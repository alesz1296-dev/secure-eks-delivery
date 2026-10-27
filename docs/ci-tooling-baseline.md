# CI Tooling Manual Baseline

These checks were run locally before enabling the GitHub Actions workflows.

## TFLint

```text
Command: tflint --init
Result:  plugins already installed

Command: tflint --chdir=infra
Result:  no findings
```

## actionlint

```text
Version: 1.7.12
Files:   .github/workflows/pr-validation.yml
         .github/workflows/terraform-deploy.yml
         .github/workflows/container-delivery.yml
Result:  no findings
```

These results establish that the Terraform configuration passes the local
TFLint baseline and the current workflow YAML passes actionlint. They do not
yet prove that GitHub Actions can authenticate to AWS, execute a remote plan,
or perform an approved apply.

## SonarQube manual analysis

The Python/FastAPI source was analyzed using the local SonarQube instance.

```text
Quality Gate:       Passed
Bugs:               0
Vulnerabilities:    0
Security Hotspots:  0
Code Smells:        0
Reliability:        A
Security:           A
Maintainability:    A
Coverage:           0.0% (21 lines; no coverage report configured)
Duplication:        0.0%
```

SonarQube remains excluded from the active CI gate for now. The manual result
is retained as evidence and may support a future quality-gate integration.

## Application and repository checks

```text
pytest:       4 passed
Ruff:         all checks passed
pip-audit:    no known vulnerabilities found
Kubernetes:   Kustomize render and client-side dry-run succeeded
SBOM:         generated with Trivy as sbom-filesystem.json
```

## Trivy filesystem configuration findings

The filesystem scan found no new application dependency vulnerability, but it
reported configuration findings that require triage:

| Severity | Finding | Context |
| --- | --- | --- |
| HIGH | `AWS-0132` — S3 encryption should use customer-managed keys | Reported for the Terraform state bucket configuration and repeated in the generated plan snapshot. This aligns with the documented AES256 versus CMK decision. |
| MEDIUM | `AWS-0178` — VPC Flow Logs not enabled | Open infrastructure-hardening decision. |
| MEDIUM | `KSV-0125` — restrict Kubernetes images to trusted registries | Review production workload images; negative test fixtures are not deployment workloads. |
| LOW | S3 logging, Kubernetes requests/limits, UID/GID, and ECR CMK recommendations | Triage by resource and distinguish production manifests from intentional test fixtures. |

The scan also included generated Terraform plan snapshots and local evidence
files. CI scanning must exclude generated artifacts such as `*.tfplan`,
`terraformplan-snapshot/`, `trivy-*.json`, `trivy-*.log`, and `sbom-*.json` so
that source findings are not duplicated by evidence files.

## Container delivery workflow

The GitHub Actions `container-delivery.yml` workflow was manually dispatched
and completed successfully. It built the `linux/amd64` image, scanned it with
Trivy, generated a SARIF report, and uploaded the report as a workflow
artifact.

The workflow is intentionally evidence-only: Trivy findings do not fail the
job. The SARIF report includes the known Debian baseline findings and the
SBOM-only Python provenance findings. This is a deliberate portfolio-lab
choice, not an unfinished requirement. A production service should make its
blocking threshold and exception process explicit before release.

## ECR publisher pipeline design

The next container-delivery revision separates validation from AWS publication:

```text
quality checks + Gitleaks
  -> build linux/amd64 image
  -> Trivy SARIF evidence
  -> CycloneDX image SBOM
  -> protected GitHub environment approval
  -> GitHub OIDC publisher role
  -> ECR immutable tags and recorded digest
```

The `quality` job runs Ruff, pytest, and `pip-audit` against the locked runtime requirements. The `secrets` job runs Gitleaks. The publish job runs only after both complete successfully and the `container-delivery` GitHub environment is available. It uploads a Trivy SARIF report and a CycloneDX SBOM generated from the built image as the same retained evidence artifact.

The publisher role is separate from the Terraform plan role. It has only `ecr:GetAuthorizationToken` plus layer-upload and `PutImage` permissions for the one project repository. It cannot apply Terraform, change IAM, or administer EKS. AWS requires `GetAuthorizationToken` to use `Resource: "*"`; the remaining ECR actions are repository-scoped.

Before dispatching the workflow, apply the Terraform role and configure these **environment variables** in GitHub's `container-delivery` environment:

| Variable | Value source |
| --- | --- |
| `AWS_ROLE_ARN` | Terraform output `github_container_delivery_role_arn` |
| `ECR_REPOSITORY` | Terraform output `ecr_repository_name` |

The environment should restrict deployments to `main` and require approval if the repository plan supports it. Its OIDC subject must match the value supplied to `github_container_delivery_oidc_subject`; inspect an Actions token first if the repository uses customized OIDC subject claims.
