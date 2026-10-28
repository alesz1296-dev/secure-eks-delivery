# Secure EKS Delivery Lab — Update #3: From a Secure Cluster to a Delivery Platform

Since Update #2, the lab has grown from a hardened local Kubernetes workload
into a working delivery and platform-security baseline.

## Traceable CI delivery

GitHub Actions is now split into pull-request validation, Terraform planning,
and container delivery. The pipeline runs Gitleaks, Checkov, TFLint,
Actionlint, Ruff, pytest, and `pip-audit`.

AWS access uses GitHub OIDC rather than stored access keys. The Terraform plan
workflow has its own scoped role, while a separate role can publish only to the
project ECR repository. The container workflow builds `linux/amd64`, retains
Trivy SARIF evidence, generates a CycloneDX SBOM, and publishes immutable ECR
tags and digests. Keyless Cosign signing and SBOM attestation are now included;
the next provenance milestone is verifying them from a protected `main` run and
enforcing trusted signatures with Kyverno.

## Prevention, GitOps, and runtime signals

The Kind workload remains non-root, read-only, capability-free, and protected
by `RuntimeDefault` seccomp, resource limits, and a ServiceAccount without an
API token. Pod Security Admission enforces the Kubernetes Restricted profile,
while Kyverno adds project-specific rules for the read-only filesystem and
explicit CPU and memory resources. An unsafe test Pod first produced a
PolicyReport in audit mode, then was rejected once the policy moved to deny
mode.

Argo CD now reconciles the `test` branch to Kind with a `Synced` and `Healthy`
application state. Prometheus scrapes the FastAPI `/metrics` endpoint through a
ServiceMonitor, Grafana provides visualisation, and Argo Rollouts supplies a
staged canary strategy. Falco completes the runtime layer: a controlled shell
event in the non-root application container produced the expected alert.

## What comes next

The next exercise is operational: use Prometheus analysis during a controlled
bad canary release and capture the automatic abort or rollback. Then the lab
will complete signature verification, branch promotion from test to staging to
production, and a cost-reviewed EKS deployment using this proven pattern.

![Production EKS security-group target](images/security-groups-production-target.png)

The main result is a chain of evidence rather than a single security tool:
checked source, scoped identity, immutable artifacts, admission controls,
GitOps reconciliation, and runtime signals.
