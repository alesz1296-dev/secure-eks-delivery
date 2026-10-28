# Secure EKS Delivery Lab

Hands-on DevSecOps portfolio project for delivering a small containerized web application to Amazon EKS securely, detecting vulnerabilities before release, and investigating suspicious runtime behavior.

The emphasis is on learning by building: each stage is implemented, tested, documented, and then reviewed before moving on.

## Goals

- Provision a cost-aware AWS foundation with Terraform.
- Model a production-like AWS delivery foundation with VPC networking, private subnets, security groups, ECR, KMS encryption, VPC Flow Logs, remote Terraform state, and cost-control flags.
- Use GitHub OIDC with separate least-privilege roles for Terraform planning and ECR publication, without long-lived AWS credentials.
- Build a reproducible, hardened FastAPI container using a multi-stage build, locked and hash-verified dependencies, a digest-pinned base image, non-root UID/GID `10001`, dropped capabilities, and no runtime package manager.
- Apply secure Kubernetes workload defaults: non-root execution, read-only root filesystem, RuntimeDefault seccomp, disabled service-account token automount, probes, resource requests and limits, ResourceQuota, LimitRange, and least-privilege RBAC.
- Enforce namespace isolation with Pod Security Admission, Kyverno admission policy, and Cilium NetworkPolicies.
- Build a production-shaped GitHub Actions pipeline with separate PR validation, Terraform plan, and container-delivery workflows.
- Run pre-commit and CI quality checks with Ruff, pytest, pip-audit, Terraform validation, TFLint, Checkov, Gitleaks, and Actionlint.
- Build `linux/amd64` images, scan them with Trivy, retain SARIF evidence, and generate CycloneDX SBOMs.
- Publish reviewed images to ECR using immutable tags, sign the immutable digest with keyless Cosign, and attest the SBOM.
- Document scanner triage, SBOM provenance discrepancies, accepted lab risk, and remediation workflows.
- Install Falco with Helm on Kind, generate controlled runtime events, and investigate the resulting alerts.
- Validate local GitOps delivery with Argo CD, Prometheus/Grafana observability, and Argo Rollouts before an eventual EKS deployment.

## Architecture

![Secure EKS Delivery Lab architecture](docs/images/architecture.png)

```text
Developer change
       |
       v
GitHub Actions: quality -> build -> Trivy/SBOM -> ECR digest -> Cosign
       |
       v
Amazon ECR: versioned, immutable application image
       |
       v
Kind now; Amazon EKS: application workloads on EC2 managed nodes
       |
       +--> Falco: runtime detection and alert investigation

Argo CD reconciles the `test` branch to Kind; a future promotion path will target
staging and production. Prometheus/Grafana provide metrics evidence, and Argo
Rollouts supplies the canary/rollback controller for the next exercise.
```

## Security scope

The project demonstrates layered controls across source, infrastructure, artifacts,
Kubernetes, and runtime:

| Area | Tools or controls | Purpose |
| --- | --- | --- |
| Source and workflow hygiene | Gitleaks, Actionlint, pre-commit | Detect secrets and invalid or unsafe workflow changes before merge. |
| Application quality | Ruff, pytest, pip-audit, locked dependencies | Check code quality, behavior, and Python dependency risk. |
| Infrastructure as code | Terraform validation, TFLint, Checkov | Validate Terraform and identify insecure AWS configuration. |
| Container security | Hardened multi-stage Dockerfile, Trivy | Reduce runtime attack surface and identify known image vulnerabilities. |
| Artifact provenance | CycloneDX SBOM, immutable ECR tags, image digests, keyless Cosign | Record, sign, and attest what was built before deploying the exact artifact. |
| Cloud identity | GitHub OIDC, scoped IAM roles, protected environments | Avoid long-lived AWS keys and separate plan from image-publication permissions. |
| Kubernetes governance | RBAC, Pod Security Admission, Kyverno, ResourceQuota, LimitRange, seccomp, NetworkPolicies | Limit workload permissions, resources, privileges, and network reachability. |
| GitOps and observability | Argo CD, Argo Rollouts, Prometheus, Grafana | Reconcile declared state, observe service health, and prepare progressive delivery analysis. |
| Runtime detection | Falco on Kind | Detect suspicious process and shell activity in running containers. |

Trivy and Falco serve different purposes: Trivy finds known vulnerabilities before
deployment; Falco detects suspicious behavior while containers are running.

Portfolio-lab scan policy: retain Trivy evidence in CI and document material findings. This project intentionally does **not** block delivery on HIGH or CRITICAL findings because its focus is demonstrating the wider delivery, identity, Kubernetes, and runtime-detection lifecycle. A real production service should add a risk-approved vulnerability gate with ownership, remediation deadlines, and exceptions.

## Development roadmap

### Stage 1 — Infrastructure and application baseline

- [x] Provision and validate the AWS foundation: VPC, private subnets, security groups, ECR, IAM, VPC Flow Logs, remote state, and a GitHub OIDC plan role.
- [x] Keep EKS, managed nodes, NAT, endpoints, and ingress behind explicit cost-control flags.
- [x] Design EC2-backed EKS managed nodes to support host-visible Falco runtime detection.
- [x] Build and harden the FastAPI container.
- [x] Deploy and verify it locally on Kind with a Deployment, Service, health probes, ResourceQuota, LimitRange, least-privilege RBAC, Pod Security Admission, and Cilium NetworkPolicies.
- [x] Verify the workload through `kubectl port-forward` before adding ingress or HTTPS.
- [x] Run the workload as UID/GID `10001`, with a read-only root filesystem, dropped capabilities, RuntimeDefault seccomp, and disabled service-account token automount.

### Stage 2 — Secure CI delivery and artifact provenance

- [x] Run infrastructure and secret/IaC checks in GitHub Actions: Terraform validation, TFLint, Checkov, Gitleaks, and Actionlint.
- [x] Run application quality checks: Ruff, pytest, pip-audit, and dependency-lock verification.
- [x] Build and scan a `linux/amd64` image with Trivy and retain SARIF evidence as a workflow artifact.
- [x] Generate and retain a CycloneDX SBOM for the image.
- [x] Authenticate the Terraform plan workflow to AWS through GitHub OIDC; no long-lived AWS key is stored in GitHub.
- [x] Publish a scanned candidate image to ECR and deploy it locally by immutable digest.
- [x] Create a separate, least-privilege OIDC role and protected `container-delivery` environment for ECR publication.
- [x] Complete and verify the end-to-end ECR publication run from GitHub Actions; `build-6` and the commit tag resolve to the recorded ECR digest.
- [x] Implement keyless Cosign signing and CycloneDX SBOM attestation after ECR publication, with identity-based verification and retained evidence configured in CI.
- [ ] Merge the signing implementation to `main` and retain the first successful signing and attestation verification artifact.
- [ ] Keep Terraform apply disabled until a separate production role and approval environment are configured.

### Stage 3 — Security validation and vulnerability remediation

- [ ] Introduce or select an older image with a fixable vulnerability.
- [ ] Capture the failing Trivy report.
- [ ] Update the vulnerable application dependency or base image.
- [ ] Rebuild, rescan, and compare the reports.
- [ ] Record the successful rollout of the patched image.
- [x] Document the portfolio policy that Trivy findings remain visible as SARIF evidence but do not block this lab's delivery gate.
- [x] Record SBOM-only package discrepancies as provenance investigations rather than confirmed runtime vulnerabilities.

### Stage 4 — Runtime detection and response

- [x] Install Falco using its Helm chart on Kind and generate a controlled shell event.
- [x] Inspect the resulting alert: rule, process, container, pod, and response.
- [ ] Document mitigation and cleanup, including a Falco Talon response path for future notification or containment integration.

### Stage 5 — GitOps with Argo CD

- [x] Install Argo CD on Kind and reconcile the `test` branch through an Argo CD Application.
- [x] Install Prometheus/Grafana and verify the application `ServiceMonitor` reports `up = 1`.
- [x] Install Argo Rollouts and define a staged canary strategy.
- [ ] Add Prometheus-backed analysis to the rollout and force a failed release to demonstrate automatic abort/rollback.
- [ ] Have CI promote a signed immutable digest by updating the intended environment branch.
- [ ] Package the application configuration with Helm if it improves the tested manifest workflow.
- [ ] Promote the proven GitOps path to staging and production, then reconcile it to EKS.

## Cost controls

This is an intentional, short-lived lab. Resources must not be left running between learning sessions.

- [ ] Set an AWS Budget and billing alerts before creating paid resources.
- [ ] Use explicit Terraform feature flags for billable components, such as EKS, managed node groups, NAT gateways, ingress/load balancers, and runtime tooling.
- [ ] Keep the default lab configuration minimal.
- [ ] Document whether each resource is charged while it exists or only while it is used.
- [ ] Use a teardown checklist after every lab session and verify the AWS console is clear of remaining billable resources.

> Scaling application workloads down does not make an EKS cluster free. EKS control-plane charges and resources such as NAT gateways, load balancers, public IPv4 addresses, EBS volumes, and logs may continue to incur cost while they exist.

## Remediation model

| Vulnerability location         | Expected remediation                                               |
| ------------------------------ | ------------------------------------------------------------------ |
| Application dependency         | Update the dependency and lockfile; test, rebuild, and rescan.     |
| Container OS package           | Update the base image or package installation; rebuild and rescan. |
| EKS worker-node OS             | Update the managed node group AMI and roll nodes safely.           |
| Kubernetes component or add-on | Upgrade the component and verify version compatibility.            |

Application containers are rebuilt and replaced; running pods are never manually patched.

## Evidence to collect

The finished project will demonstrate two independent security outcomes:

1. **Vulnerability remediation:** failed scan -> dependency or base-image update -> passing scan -> successful rollout.
2. **Runtime detection:** controlled suspicious activity -> Falco alert -> investigation -> mitigation.

Keep sanitized screenshots, workflow logs, scan reports, deployment evidence, Falco events, and teardown confirmation. Never commit AWS credentials, kubeconfig files, Terraform state, or sensitive account information.

## Planned repository structure

```text
.
├── app/                 # Application source and tests
├── infra/               # Terraform infrastructure
├── k8s/                 # Raw Kubernetes manifests during early stages
├── helm/                # Helm charts and values (optional later packaging)
├── gitops/              # Argo CD Applications and environment overlays
├── docs/                # Architecture, decisions, evidence, and runbooks
└── .github/workflows/   # CI workflows
```

## Current status — 2026-10-28

The project has a working local Kubernetes security baseline and a partially applied, cost-controlled AWS foundation. VPC, ECR, IAM, customer-managed KMS keys, VPC Flow Logs, remote Terraform state, and the GitHub OIDC plan identity exist. EKS, EC2 node groups, NAT Gateway, interface endpoints, ingress, and public application exposure remain disabled.

The active CI path is split deliberately:

- **Pull request validation:** formatting, Terraform validation, TFLint, Checkov (with three documented KMS-policy model exclusions), and Gitleaks.
- **Terraform deployment:** manually dispatched, OIDC-authenticated, remote-state **plan only**; apply is intentionally disabled.
- **Container delivery:** a gated workflow runs quality checks, Gitleaks, a `linux/amd64` build, Trivy SARIF evidence, a CycloneDX SBOM, protected ECR publication by immutable tags, keyless Cosign signing, and SBOM attestation. The verified `build-6` and commit tags resolve to `sha256:df00c79558a2ebf82d978415686c860c2c483258d202a3cb594479eb2965f67f`; the first signing run remains to be captured after the implementation is merged to `main`.

The local `test` branch is the current Kind GitOps target. Argo CD reports the
application as `Synced` and `Healthy`; Prometheus successfully scrapes the
application; PSA Restricted and a Kyverno runtime-hardening policy deny
non-compliant pods. Argo Rollouts is installed for the next canary and
automatic-rollback exercise.

Local pre-commit checks, the GitHub PR workflow, the OIDC Terraform plan workflow, and the container evidence workflow have all been validated. See [the task backlog](docs/tasks.md) for remaining platform work.

## Task backlog

Track implementation and evidence in the [project task backlog](docs/tasks.md).

## Design documentation

- [Architecture](docs/architecture.md)
- [Infrastructure design guide](docs/infrastructure-design.md)
- [Design decisions](docs/design-decisions.md)
- [Threat model](docs/threat-model.md)
- [Security controls: Trivy and Falco](docs/security-controls.md)
- [Cost controls and teardown](docs/cost-controls.md)

## Local application workflow

The sample FastAPI service is intentionally small: it exposes service metadata, liveness and readiness endpoints, and an in-memory task API. It is a disposable workload used to practice platform delivery and security controls, not a production application.

```bash
python -m venv .venv
# Windows PowerShell: .venv\\Scripts\\Activate.ps1
source .venv/bin/activate
pip install -e ".[dev]"
pytest
uvicorn app.main:app --host 127.0.0.1 --port 8080
```

Useful endpoints: `/`, `/health/live`, `/health/ready`, and `/docs`.

Build and run the container locally:

```bash
docker build -t secure-eks-delivery:local .
docker run --rm -p 8080:8080 secure-eks-delivery:local
```

The Dockerfile runs as UID `10001`, rather than root. Kubernetes will later reinforce this with a security context and other workload restrictions.
