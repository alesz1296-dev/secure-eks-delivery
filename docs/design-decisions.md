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

## D-008: Temporarily allow unrestricted security-group egress

**Decision:** The initial EKS cluster and worker-node security groups allow outbound traffic while the lab networking foundation is validated.

**Rationale:** This avoids blocking the first EKS deployment on an incomplete NAT or VPC-endpoint design. It is a temporary exception, not a production recommendation. Later hardening must restrict egress through NAT Gateway routes or VPC endpoints and verify that ECR, S3, STS, logging, and node-update workflows still function.

## D-009: Use a restricted public EKS endpoint during bootstrap

**Decision:** The initial AWS baseline enables both private and public API endpoint access. Public access must be restricted to the administrator's current public IP using `public_access_cidrs`.

**Rationale:** A private-only endpoint requires an administration path before `kubectl` can reach the cluster. The project will later provision an SSM-managed administration host and private Systems Manager connectivity. Once that path is implemented and verified, public endpoint access will be disabled.

**Target state:** `Laptop -> SSM Session Manager -> private administration host -> private EKS API`

## D-010: Demonstrate a complete DevSecOps security lifecycle

**Decision:** The project will include prevention, pre-deployment detection, runtime detection, incident investigation, remediation, and retained evidence rather than only provisioning infrastructure.

**Rationale:** The portfolio should demonstrate why each control exists and how a finding is handled. The implementation sequence and evidence expectations are maintained in the [DevSecOps Security Roadmap](devsecops-roadmap.md).

## D-011: Use VPC endpoints for private node egress

**Decision:** Use VPC endpoints as the egress design for private EKS nodes. The project will not use a hybrid NAT Gateway plus endpoint design.

The first endpoint set will cover:

- S3 Gateway Endpoint
- ECR API Interface Endpoint
- ECR DKR Interface Endpoint
- STS Interface Endpoint

CloudWatch Logs and Systems Manager endpoints will be added when those capabilities are enabled.

**Rationale:** VPC endpoints keep AWS service traffic on the AWS network, make the permitted service boundary explicit, and support the project's security-learning goals. They also avoid introducing NAT Gateway hourly and data-processing charges during the first private-node milestone.

**Trade-off:** Interface endpoints add resources, endpoint security groups, private DNS requirements, and their own hourly/data-processing costs. Workloads requiring general internet access, external package repositories, or external APIs are outside this private-egress baseline and would require a separately reviewed architecture decision.

The endpoint security group currently relies on implicit default outbound behavior during the lab phase. This is a temporary exception to be replaced with explicit, least-privilege egress rules after endpoint connectivity is verified.

## D-012: Separate Terraform planning from ECR publication identity

**Decision:** Use distinct GitHub OIDC roles and protected environments for Terraform planning and container publication.

**Rationale:** A plan-only identity needs remote-state access and read-only AWS discovery. An image publisher instead needs permission to obtain an ECR authorization token and upload layers/manifests to one repository. Combining them would increase the impact of a compromised workflow or mistaken configuration. Terraform apply remains disabled and will require a third, separately reviewed role and approval path.

## D-013: Disable the Terraform backend during pull-request validation

**Decision:** Run `terraform init -backend=false` in the pull-request validation job. Enable the S3 backend only in the trusted OIDC-authenticated Terraform plan workflow.

**Rationale:** Pull-request code is untrusted and should not receive credentials or access to remote state and state locks. Static validation does not require the backend. The deployment-plan workflow has a separate identity and is the correct place to read remote state.

## D-014: Layer PSA with a project-specific Kyverno policy

**Decision:** Enforce the Kubernetes Restricted Pod Security Admission profile and add a namespaced Kyverno policy that requires read-only root filesystems, dropped capabilities, disabled privilege escalation, and explicit CPU/memory resources.

**Rationale:** PSA provides a standardized baseline, but it does not express every workload rule needed by this project. Kyverno makes those additional requirements auditable and enforceable at admission time. The policy was proven first in audit mode and then switched to deny mode using a controlled negative Pod.

## D-015: Use keyless Cosign signing for published ECR digests

**Decision:** Have the protected container-delivery workflow sign immutable ECR digests and attest their CycloneDX SBOMs using keyless Cosign and the GitHub Actions OIDC identity.

**Rationale:** Keyless signing avoids storing a private signing key in the repository or CI secrets while still binding an artifact to an issuer, workflow identity, and source branch. Signature verification will be enforced by Kyverno only after the first successful `main` workflow run is independently captured as evidence.
