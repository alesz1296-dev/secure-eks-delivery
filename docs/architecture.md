# Architecture

## Status

This document distinguishes the implemented foundation from the target EKS architecture. The local Kind baseline is verified; EKS and its node group remain deliberately disabled for cost control.

## Purpose

Deliver a small containerized FastAPI workload to Amazon EKS with infrastructure-as-code, supply-chain security, vulnerability remediation, runtime detection, and GitOps.

## Target flow

The editable diagram source is [`architecture.mmd`](architecture.mmd). The rendered PNG is useful for the portfolio overview; this Mermaid source is the version to update when the Terraform architecture changes.

The private egress and endpoint security-group relationships are illustrated in [`images/private-eks-egress-diagram.png`](images/private-eks-egress-diagram.png).

```text
Developer
  -> GitHub repository
  -> GitHub Actions: quality, build, Trivy/SBOM evidence, ECR publication, Cosign
  -> Amazon ECR: immutable image digest, signature, and SBOM attestation
  -> Argo CD: reconcile intended environment state
  -> Kind today; Amazon EKS: FastAPI workload on EC2 managed nodes
  -> Falco: runtime event detection and investigation

Terraform provisions AWS infrastructure.
Argo CD currently reconciles the `test` branch to Kind.
Prometheus/Grafana observe the local workload, and Argo Rollouts provides the
canary controller for the next rollback exercise.
```

## EKS API access transition

The initial AWS baseline uses private endpoint access plus a public EKS API endpoint restricted to the administrator's IP. This keeps the cluster reachable while the project is bootstrapped. Public access is temporary and must never be configured as `0.0.0.0/0`.

The target design adds an SSM-managed administration host and private Systems Manager connectivity. After that path is verified, the EKS public endpoint will be disabled.

## Planned AWS components

| Component                | Purpose                                             | Status  |
| ------------------------ | --------------------------------------------------- | ------- |
| VPC and private subnets  | Network boundary for cluster resources              | Applied; no NAT route |
| Security groups          | Cluster and worker traffic boundaries               | Applied; egress hardening remains open |
| Amazon ECR               | Private image registry                              | Applied; scanned candidate image published |
| IAM roles                | EKS/node definitions and CI-plan permissions        | Applied; EKS/node roles unused while feature flags are off |
| GitHub OIDC plan role    | Short-lived Terraform-plan authentication to AWS    | Applied and validated in GitHub Actions |
| VPC Flow Logs            | Network observability                               | Applied with customer-managed KMS encryption and 365-day retention |
| Amazon EKS               | Managed Kubernetes control plane                    | Defined, not created (`enable_eks = false`) |
| EC2 managed node group   | Runs the application and Falco with host visibility | Defined, not created (`enable_eks_node_group = false`) |

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
| GitOps reconciliation | Argo CD on Kind (`test` branch)       |
| Progressive delivery | Argo Rollouts canary strategy on Kind |
| Metrics and dashboards | Prometheus and Grafana on Kind       |

Ingress, public application exposure, and HTTPS are intentionally deferred. Initial application access uses `kubectl port-forward`. The EKS API has temporary restricted public access for administration; this is separate from public application exposure.

## Security-control lifecycle

Trivy produces retained CI evidence and supports documented vulnerability triage. A blocking HIGH/CRITICAL gate is intentionally outside this portfolio lab's scope; it would be required and risk-owned in a production service. Falco has been validated on Kind through a controlled interactive-shell alert. See [Security controls: Trivy and Falco](security-controls.md) for the policy, exercises, and evidence.
