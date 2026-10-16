# Architecture

## Status

This is the target architecture. Components are marked as planned until they are deployed and verified.

## Purpose

Deliver a small containerized FastAPI workload to Amazon EKS with infrastructure-as-code, supply-chain security, vulnerability remediation, runtime detection, and GitOps.

## Target flow

The editable diagram source is [`architecture.mmd`](architecture.mmd). The rendered PNG is useful for the portfolio overview; this Mermaid source is the version to update when the Terraform architecture changes.

```text
Developer
  -> GitHub repository
  -> GitHub Actions: test, build, Trivy scan, security gate
  -> Amazon ECR: immutable image digest
  -> Amazon EKS: FastAPI workload on EC2 managed nodes
  -> Falco: runtime event detection and investigation

Terraform provisions AWS infrastructure.
Helm packages the application and installs Falco later.
Argo CD reconciles declared GitOps state to EKS later.

## EKS API access transition

The initial AWS baseline uses private endpoint access plus a public EKS API endpoint restricted to the administrator's IP. This keeps the cluster reachable while the project is bootstrapped. Public access is temporary and must never be configured as `0.0.0.0/0`.

The target design adds an SSM-managed administration host and private Systems Manager connectivity. After that path is verified, the EKS public endpoint will be disabled.
```

## Planned AWS components

| Component                | Purpose                                             | Status  |
| ------------------------ | --------------------------------------------------- | ------- |
| VPC and private subnets  | Network boundary for cluster resources              | Planned |
| Amazon ECR               | Private image registry                              | Planned |
| IAM and GitHub OIDC role | Short-lived CI authentication to AWS                | Planned |
| Amazon EKS               | Managed Kubernetes control plane                    | Planned |
| EC2 managed node group   | Runs the application and Falco with host visibility | Planned |
| CloudWatch Logs          | Controlled, time-limited operational logs           | Planned |

## Trust boundaries

1. **GitHub to AWS:** GitHub Actions must use OIDC and a narrowly scoped IAM role. Long-lived AWS access keys are not permitted.
2. **Registry to cluster:** only images from the project ECR repository, identified by digest, may be deployed.
3. **Cluster workload:** the application runs as a non-root user with resource limits and Kubernetes security settings.
4. **Runtime observation:** Falco observes runtime events on EC2-backed nodes; its findings are investigated as security signals, not automatically treated as proof of compromise.

## Deployment maturity

| Stage                 | Deployment mechanism                  |
| --------------------- | ------------------------------------- |
| Initial workload      | `kubectl` with reviewed raw manifests |
| Repeatable packaging  | Helm                                  |
| GitOps reconciliation | Argo CD                               |

Ingress, public exposure, and HTTPS are intentionally deferred. Initial application access uses `kubectl port-forward`.

## Security-control lifecycle

Trivy is the pre-deployment security gate: an image is built, scanned, and approved before its immutable ECR digest is deployed. Falco is the post-deployment runtime control: it observes the running workload and supplies investigation evidence. See [Security controls: Trivy and Falco](security-controls.md) for the required policy, exercises, and evidence.
