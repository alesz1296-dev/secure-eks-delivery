# Project Task Backlog

Use this checklist to track hands-on work. Mark an item complete only after it is implemented, verified, and its evidence is saved where relevant.

The ordered security program is documented in [DevSecOps Security Roadmap](devsecops-roadmap.md).

## Docker hardening — revisit before the first ECR push

- [x] Replace the single-stage Dockerfile with separate `builder` and `runtime` stages.
- [x] Build the application and dependencies into `/opt/venv` in the builder stage.
- [x] Copy only the virtual environment into the runtime image; do not retain build tooling or source-build artifacts.
- [x] Keep the runtime image installation order explicit: install locked dependencies in the builder, then copy the application source into the runtime image.
- [x] Keep the runtime process as non-root UID/GID `10001`.
- [x] Create the runtime user without a writable home directory unless the application specifically needs one.
- [x] Verify the runtime application directory is not writable by the application user.
- [x] Confirm the container starts and serves `/health/live` on port `8080`.
- [x] Expand `.dockerignore` to exclude `.env`, `.aws/`, `kubeconfig`, `*.pem`, `*.key`, `.terraform/`, Terraform state, and local-only evidence assets.
- [x] Pin builder `pip`/`setuptools` versions and use the reproducible dependency lock with exact transitive versions and hashes.
- [x] Pin the Python base image by digest after establishing the Trivy scan workflow.
- [x] Build the image locally and record its image digest.
- [x] Scan the image with Trivy and record the baseline findings.
- [x] Fix at least one deliberately selected, fixable dependency or base-image vulnerability and compare scan reports.

## Container verification evidence

- [x] Save the successful local build command and output.
- [x] Save the output proving the running container user is not root.
- [x] Save the liveness endpoint response.
- [x] Save the initial Trivy report and the remediated report.

## Validated infrastructure and local baseline

- [x] Define and validate the Terraform VPC, private subnets, route tables, tags, and outputs.
- [x] Define and validate ECR, IAM roles, security groups, VPC endpoints, EKS control-plane, managed node group, and launch-template resources.
- [x] Keep EKS creation and other cost-incurring resources disabled until the local path is proven.
- [x] Create the local kind cluster and validate Cilium networking.
- [x] Deploy the FastAPI workload, ServiceAccount, ClusterIP Service, probes, and Kustomize base.

## Supply-chain reproducibility

- [x] Replace the mutable Python base-image tag with a human-readable version tag pinned by digest.
- [x] Build the image for the intended runtime architecture (`linux/amd64` for the initial EKS node group) and record the selected base-image digest.
- [x] Scan the candidate base image with Trivy before accepting or updating its digest.
- [ ] Define an intentional base-image update cadence and retain scan evidence for each update.
- [x] Generate and commit a transitive Python dependency lock file with hashes.
- [x] Configure the Docker build to install runtime dependencies using `pip --require-hashes` from the committed lock file.
- [x] Ensure the image build does not resolve unpinned dependencies at build time.
- [ ] Automate lock-file refreshes through a reviewed dependency-update workflow and rescan the rebuilt image.

## Security delivery and runtime detection

## Open vulnerability risks

- [x] Temporarily accept the remaining 44 Debian 13.7 findings for local-only baseline validation, with expiry at the first ECR/EKS deployment gate. Retain severity, reachability, and `will_not_fix` evidence for the later production decision.
- [ ] Investigate the four grouped Python findings reported only through third-party SBOM metadata (`msgpack 1.1.2`, `setuptools 70.3.0`, and `urllib3 2.7.0`). They are not present in the final runtime filesystem; preserve the Trivy report and verify the SBOM provenance before changing application dependencies.
- [x] Record the selected pinned Trixie digest and the before/after scan comparison in `docs/vulnerability-baseline.md`.

- [ ] Define and document the Trivy gate: fail on fixable HIGH and CRITICAL findings.
- [ ] Retain Trivy reports as GitHub Actions artifacts.
- [x] Configure deployment to use the scanned ECR image digest and verify the running workload.
- [x] Install Falco using Helm after the workload is stable.
- [x] Run and document a controlled Falco interactive-shell detection exercise.
- [ ] Evaluate Falco Talon for narrowly scoped automated responses after detection-only testing is complete.
- [ ] Integrate Falco alerts with Falcosidekick and AWS SNS using workload identity rather than static AWS credentials.
- [ ] Evaluate email notification through SES via a controlled Lambda or SMTP integration; do not send directly from application containers.
- [ ] Record the investigation and mitigation for each Falco exercise.

## Identity and pipeline security

- [ ] Create a GitHub OIDC provider and a repository- and environment-scoped deployment role.
- [ ] Do not use long-lived AWS access keys in GitHub Actions.
- [ ] Set minimum `GITHUB_TOKEN` permissions per workflow and job.
- [ ] Pin third-party GitHub Actions to full commit SHAs.
- [ ] Keep untrusted pull-request code away from deployment credentials and privileged runners.
- [ ] Add Gitleaks secret detection and Checkov Terraform scanning.
- [x] Run a manual Checkov Terraform baseline and record the 89 passing checks and open findings in `docs/checkov-baseline.md`.
- [ ] Add CodeQL or Semgrep source-code scanning after the base pipeline is stable.
- [ ] Configure protected deployment environments and record the approval path.

## Kubernetes workload security

- [x] Add `runAsNonRoot`, dropped Linux capabilities, `allowPrivilegeEscalation: false`, and a read-only root filesystem where compatible.
- [x] Define and enforce a Pod Security Admission baseline or restricted policy.
- [x] Add NetworkPolicies and demonstrate that unauthorized pod-to-pod traffic is denied.
- [x] Keep the application ServiceAccount token disabled because the workload has no Kubernetes API requirement.
- [ ] Add an SBOM and retain it with the image build evidence.
- [ ] Review application authorization and test that unauthorized actions are denied.
- [ ] Evaluate CloudTrail and GuardDuty for a controlled cloud-security exercise.
- [ ] Record dependency provenance from source lockfile to image digest.
- [ ] Evaluate artifact signing and verification as an optional supply-chain enhancement.

## Local Kubernetes hardening follow-up

- [x] Add and apply a namespace `ResourceQuota` for aggregate CPU, memory, and Pod limits; keep PVC quotas deferred because the workload is stateless.
- [x] Add and apply a namespace `LimitRange` that supplies safe default resource requests and limits for future workloads.
- [x] Keep the local kind node image and Cilium chart version pinned and document their upgrade procedure.
- [ ] Create a Kubernetes overlay for EKS that replaces the local image and `imagePullPolicy: Never` with an ECR image digest.

## RBAC and label-governance exercise

- [x] Prove that the application ServiceAccount cannot list Pods, read Secrets, create workloads, or access cluster-scoped resources.
- [x] Record `kubectl auth can-i` evidence for the application ServiceAccount.
- [ ] Define a least-privilege Role and RoleBinding only if the application gains a genuine Kubernetes API requirement.
- [ ] Ensure GitHub Actions, Argo CD, and human operators use distinct identities and minimal namespace-scoped permissions.
- [ ] Do not grant `cluster-admin` to application, CI, or GitOps identities.
- [ ] Add a Kyverno policy or Kubernetes ValidatingAdmissionPolicy restricting use of `access=api-client` to approved ServiceAccounts or workloads.
- [ ] Demonstrate that an unauthorized workload carrying `access=api-client` is rejected by the admission policy.

## Network security hardening

- [ ] Resolve or formally suppress the Checkov findings for the default security group, VPC Flow Logs, and the cluster-to-node rule after reviewing the effective ports and security-group references.
- [ ] Decide whether customer-managed KMS encryption is justified for ECR; if retained, review the KMS key policy and document narrowly scoped Checkov exceptions.
- [ ] Review the temporary unrestricted outbound rules on the EKS cluster and worker-node security groups.
- [ ] Choose the final egress design: NAT Gateway, VPC endpoints, or a documented combination.
- [ ] Add only the required NAT routes or endpoint security-group rules.
- [ ] Restrict worker-node and control-plane egress and verify ECR pulls, S3 access, STS, logging, and node updates.
- [ ] Capture a Terraform plan and connectivity evidence proving the restricted design works.
- [ ] Replace implicit endpoint-security-group egress with explicit, least-privilege rules and verify ECR, STS, and EC2 endpoint connectivity.

## Private EKS administration path

- [ ] Provision an SSM-managed administration host in a private subnet.
- [ ] Choose and implement SSM connectivity through NAT or Systems Manager interface endpoints.
- [ ] Verify Session Manager access without SSH or inbound security-group rules.
- [ ] Verify `kubectl` access to the private EKS endpoint from the administration host.
- [ ] Disable EKS public endpoint access after private administration is proven.
- [ ] Remove the temporary public endpoint CIDR configuration from the baseline.

## Later platform tasks

- [ ] Add resource requests and limits.
- [ ] Package the workload as a Helm chart.
- [ ] Introduce Argo CD only after the Helm deployment path is understood and verified.
