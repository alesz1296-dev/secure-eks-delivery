# trixie image
ARG PYTHON_IMAGE=python:3.12-slim-trixie@sha256:a6e34c598f2467ed0e9a8d349809fcd8b5c603269512df273a0bb1784edc11b1 


# Build stage: Install dependencies and build the application in a virtual environment.
FROM ${PYTHON_IMAGE} AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# pinned puo and setuptools versions to avoid issues with newer versions
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install \
      --no-cache-dir \
      --upgrade \
      pip==26.2.1 \
      setuptools==84.2.0

# Copy the lock file separately for Docker layer caching.
COPY requirements.lock ./

# Install only hash-verified, locked dependencies.
RUN /opt/venv/bin/pip install \
    --no-cache-dir \
    --require-hashes \
    -r requirements.lock

# Runtime stage: Use a minimal image with only the virtual environment and application code.
FROM ${PYTHON_IMAGE} AS runtime

RUN /usr/local/bin/python -m pip uninstall --yes pip

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PATH="/opt/venv/bin:${PATH}"

WORKDIR /app

RUN groupadd --gid 10001 appgroup \
    && useradd --uid 10001 --gid appgroup --no-create-home --shell /usr/sbin/nologin appuser

COPY --chown=appuser:appgroup app ./app
COPY --from=builder /opt/venv /opt/venv

# Use a non-root user to run the application for security.
USER 10001:10001

# Expose the application port and define a health check for Kubernetes readiness and liveness probes.
EXPOSE 8080

# Define a health check to ensure the application is running and responsive
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "from urllib.request import urlopen; urlopen('http://127.0.0.1:8080/health/live')"

# Start the application using Uvicorn with the specified host and port.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]

