# Project Task Backlog

Use this checklist to track hands-on work. Mark an item complete only after it is implemented, verified, and its evidence is saved where relevant.

The ordered security program is documented in [DevSecOps Security Roadmap](devsecops-roadmap.md).

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

## Identity and pipeline security

- [ ] Create a GitHub OIDC provider and a repository- and environment-scoped deployment role.
- [ ] Do not use long-lived AWS access keys in GitHub Actions.
- [ ] Set minimum `GITHUB_TOKEN` permissions per workflow and job.
- [ ] Pin third-party GitHub Actions to full commit SHAs.
- [ ] Keep untrusted pull-request code away from deployment credentials and privileged runners.
- [ ] Add Gitleaks secret detection and Checkov Terraform scanning.
- [ ] Add CodeQL or Semgrep source-code scanning after the base pipeline is stable.
- [ ] Configure protected deployment environments and record the approval path.

## Kubernetes workload security

- [ ] Add `runAsNonRoot`, dropped Linux capabilities, `allowPrivilegeEscalation: false`, and a read-only root filesystem where compatible.
- [ ] Define and enforce a Pod Security Admission baseline or restricted policy.
- [ ] Add NetworkPolicies and demonstrate that unauthorized pod-to-pod traffic is denied.
- [ ] Define Kubernetes RBAC roles using least privilege.
- [ ] Add an SBOM and retain it with the image build evidence.
- [ ] Review application authorization and test that unauthorized actions are denied.
- [ ] Evaluate CloudTrail and GuardDuty for a controlled cloud-security exercise.
- [ ] Record dependency provenance from source lockfile to image digest.
- [ ] Evaluate artifact signing and verification as an optional supply-chain enhancement.

## Network security hardening

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
