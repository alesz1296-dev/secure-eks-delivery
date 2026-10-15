# Design Decisions

This document records meaningful choices and their rationale. Update an entry when the decision changes.

## D-001: Use Terraform for AWS infrastructure

**Decision:** Terraform provisions AWS resources such as VPC, ECR, IAM, EKS, managed node groups, and supporting observability resources.

**Rationale:** Infrastructure is reviewable, repeatable, and removable. Terraform variables also provide explicit cost-control switches.

## D-002: Use EC2 managed nodes instead of Fargate

**Decision:** Run the lab workload on a small EC2-backed EKS managed node group.

**Rationale:** Falco runtime detection benefits from host visibility. This choice also provides practical experience patching and rolling node AMIs.

## D-003: Start without ingress, NAT Gateway, or public application exposure

**Decision:** Access the application through `kubectl port-forward` in the first deployment stage.

**Rationale:** This reduces attack surface and avoids early recurring costs from NAT Gateways and load balancers. Ingress and HTTPS are deliberate later exercises.

## D-004: Deploy immutable image digests

**Decision:** Deployment configuration references ECR image digests rather than mutable tags such as `latest`.

**Rationale:** A digest identifies exactly what was scanned, approved, and deployed.

## D-005: Use GitHub OIDC instead of stored AWS keys

**Decision:** GitHub Actions assumes a narrowly scoped AWS IAM role through OIDC.

**Rationale:** This avoids long-lived credentials in GitHub secrets and makes the trust relationship explicit.

## D-006: Introduce Helm before Argo CD

**Decision:** Package and understand the application with Helm before adding Argo CD.

**Rationale:** GitOps should automate an understood deployment model, not conceal it. Argo CD is deferred until Helm deployment and rollback behavior are verified.

## D-007: Separate vulnerability scanning from runtime detection

**Decision:** Use Trivy for image/dependency CVEs and Falco for runtime behavior.

**Rationale:** They address different stages of risk. A clean Trivy result does not prove runtime safety, and a Falco alert does not replace vulnerability management.

