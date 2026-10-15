# Project Task Backlog

Use this checklist to track hands-on work. Mark an item complete only after it is implemented, verified, and its evidence is saved where relevant.

## Docker hardening — revisit before the first ECR push

- [ ] Replace the single-stage Dockerfile with separate `builder` and `runtime` stages.
- [ ] Build the application and dependencies into `/opt/venv` in the builder stage.
- [ ] Copy only the virtual environment into the runtime image; do not retain build tooling or source-build artifacts.
- [ ] Correct the package build/install order: copy the application package before building/installing it.
- [ ] Keep the runtime process as non-root UID/GID `10001`.
- [ ] Create the runtime user without a writable home directory unless the application specifically needs one.
- [ ] Verify the runtime application directory is not writable by the application user.
- [ ] Confirm the container starts and serves `/health/live` on port `8080`.
- [ ] Expand `.dockerignore` to exclude `.env`, `.aws/`, `kubeconfig`, `*.pem`, `*.key`, `.terraform/`, Terraform state, and local-only evidence assets.
- [ ] Pin build tools and introduce a reproducible dependency-lock strategy with exact transitive versions and hashes.
- [ ] Pin the Python base image by digest after establishing the Trivy scan workflow.
- [ ] Build the image locally and record its image digest.
- [ ] Scan the image with Trivy and record the baseline findings.
- [ ] Fix at least one deliberately selected, fixable dependency or base-image vulnerability and compare scan reports.

## Container verification evidence

- [ ] Save the successful local build command and output.
- [ ] Save the output proving the running container user is not root.
- [ ] Save the liveness endpoint response.
- [ ] Save the initial Trivy report and the remediated report.

## Security delivery and runtime detection

- [ ] Define and document the Trivy gate: fail on fixable HIGH and CRITICAL findings.
- [ ] Retain Trivy reports as GitHub Actions artifacts.
- [ ] Configure deployment to use the scanned ECR image digest.
- [ ] Install Falco using Helm after the workload is stable.
- [ ] Run and document controlled Falco shell and sensitive-file-write detection exercises.
- [ ] Record the investigation and mitigation for each Falco exercise.

## Later platform tasks

- [ ] Define Kubernetes `securityContext` settings, including `runAsNonRoot` and `readOnlyRootFilesystem`.
- [ ] Add Kubernetes liveness and readiness probes using the existing health endpoints.
- [ ] Add resource requests and limits.
- [ ] Package the workload as a Helm chart.
- [ ] Deploy Falco through Helm and document a controlled detection exercise.
- [ ] Introduce Argo CD only after the Helm deployment path is understood and verified.
