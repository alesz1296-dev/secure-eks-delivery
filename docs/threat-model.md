# Threat Model

## Scope

This is a learning-lab threat model for the project application, CI pipeline, registry, and EKS workload. It is not a production risk assessment.

## Assets to protect

- AWS account access and IAM roles
- GitHub repository and CI workflow integrity
- Container image provenance and image digest
- EKS control plane and worker nodes
- Application availability and operational evidence
- Any future secrets or configuration values

## Threats and planned controls

| Threat | Planned control | Evidence |
| --- | --- | --- |
| Stolen long-lived CI credentials | GitHub OIDC with a least-privilege IAM role | IAM trust and permission policy review |
| Over-permissive or compromised CI workflow | Minimal `GITHUB_TOKEN` permissions, SHA-pinned actions, protected environments, and no deployment secrets for untrusted PRs | Workflow review and blocked unsafe test |
| Exposed credential in source | Gitleaks gate and credential rotation procedure | Failing scan and remediation record |
| Unsafe Terraform change | Checkov gate plus reviewed Terraform plan | Failing check and reviewed plan artifact |
| Vulnerable dependency or OS package | Trivy security gate; dependency/base-image remediation | Before/after scan reports |
| Mutable or substituted image | ECR plus deployment by immutable digest | CI log and deployed manifest |
| Container runs as root | Non-root Docker user and Kubernetes `runAsNonRoot` | Dockerfile and pod security context |
| Privileged or overly capable pod | Pod Security Admission, Kyverno policy, dropped capabilities, and no privilege escalation | Rejected workload evidence |
| Unauthorized pod-to-pod traffic | Kubernetes NetworkPolicies | Denied connectivity test |
| Resource exhaustion | Kubernetes resource requests and limits | Deployment manifest and `kubectl` output |
| Suspicious shell/process/file activity | Falco on EC2-backed nodes | Controlled alert and investigation notes |
| Exposed application endpoint | Start with port-forward; defer ingress | Deployment configuration and access test |
| Uncontrolled cloud spend | Terraform feature flags, budget alerts, teardown checklist | Cost-control document and cleanup evidence |

## Explicit non-goals for the first iteration

- Public application exposure through ingress/load balancers
- Production data
- Automated incident response actions
- Multi-region availability
- Secret-management integration beyond avoiding secret commits

## Review triggers

Review this threat model when adding ingress, persistent storage, external databases, secrets, CI deployment permissions, Helm, or Argo CD.
