# Infrastructure Design

## Status and scope

This document is the implementation documentation for the Terraform portion of the Secure EKS Delivery Lab. The remote-state bootstrap and low-cost AWS foundation are applied. EKS, its node group, NAT Gateway, private interface endpoints, ingress, and public workload exposure remain disabled.

The target platform is **Amazon EKS with EC2 managed nodes**. Amazon ECS is out of scope; add it only as a separate comparison exercise.

## Design goals

- Keep the default environment low-cost and easy to destroy.
- Deploy only scanned, immutable ECR image digests to EKS.
- Use GitHub OIDC instead of long-lived AWS credentials.
- Support Falco later through EC2-backed worker nodes.
- Make every billable service deliberate, visible, tagged, and removable.

## Repository layout

```text
bootstrap/                         # Terraform state and optional cost-alert bootstrap
  versions.tf
  providers.tf
  state.tf
  variables.tf
  outputs.tf

infra/                             # Main EKS environment
  versions.tf
  providers.tf
  backend.tf                        # Backend declaration only; configuration supplied separately
  variables.tf
  locals.tf
  outputs.tf
  network.tf
  security-groups.tf
  endpoints.tf
  ecr.tf
  iam.tf
  github-oidc.tf
  eks.tf
  node-group.tf
  logging.tf
  terraform.tfvars.example
```

Do not commit `terraform.tfstate`, `terraform.tfstate.*`, real `.tfvars` files, credentials, kubeconfig files, or backend secrets.

## Phase 0: Bootstrap remote state and cost governance

Build this separately from the main EKS environment. Terraform needs the backend to exist before it can use it.

### Required resources

| Resource purpose         | Terraform resource types to investigate              | Notes                                                                                    |
| ------------------------ | ---------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Terraform state storage  | `aws_s3_bucket`                                      | Use a unique, dedicated bucket.                                                          |
| State version recovery   | `aws_s3_bucket_versioning`                           | Enables recovery from accidental state changes.                                          |
| State encryption         | `aws_s3_bucket_server_side_encryption_configuration` | Start with managed encryption unless a customer-managed KMS key is an explicit exercise. |
| Public-access protection | `aws_s3_bucket_public_access_block`                  | Block all public access.                                                                 |
| Retention/cost control   | `aws_s3_bucket_lifecycle_configuration`              | Retain state versions intentionally; do not retain forever by accident.                  |
| Cost alerting            | `aws_budgets_budget`                                 | Create before EKS. Confirm billing permissions first.                                    |

### Backend decision

Use an S3 backend for the `infra/` state. Keep backend values in a separate, non-secret backend configuration file or supply them at initialization. Do not attempt to create and consume the same state bucket in a single first Terraform run.

## Phase 1: Common Terraform foundation

Create the following before adding AWS resources:

- Required Terraform and AWS provider versions.
- AWS region variable.
- Unique project/name prefix variable.
- Environment variable, initially `lab`.
- Standard tags: `project`, `environment`, `owner`, `managed_by`, and `cleanup_deadline`.
- Feature flags listed below.
- Outputs designed for later steps: ECR URL, cluster name, cluster endpoint, region, and node-group name.

Run `terraform fmt`, `terraform validate`, and `terraform plan` at every phase. Apply only the current phase.

## Feature flags and cost model

| Variable                       | Default intent      | What it controls                      | Cost implication                                                         |
| ------------------------------ | ------------------- | ------------------------------------- | ------------------------------------------------------------------------ |
| `enable_ecr`                   | `true`              | ECR repository                        | Storage/data costs only when images exist.                               |
| `enable_github_oidc`           | `true`              | GitHub OIDC provider and CI role      | No meaningful direct idle service cost.                                  |
| `enable_eks`                   | `false` until ready | EKS cluster and core add-ons          | Control-plane charge exists while cluster exists.                        |
| `enable_node_group`            | `false` until ready | EC2 managed node group                | EC2 and EBS charges while nodes/volumes exist.                           |
| `enable_cluster_logs`          | `false` initially   | EKS control-plane logs and log group  | CloudWatch ingestion and retention cost.                                 |
| `enable_nat_gateway`           | `false`             | NAT Gateway and Elastic IP            | Hourly and data-processing charges.                                      |
| `enable_private_aws_endpoints` | `false`             | Interface endpoints such as ECR       | Hourly endpoint and data-processing charges.                             |
| `enable_ingress`               | `false`             | Later ingress/load balancer resources | Load-balancer and data charges.                                          |
| `enable_falco`                 | `false`             | Later Helm/Falco installation path    | Consumes node capacity and generates logs.                               |
| `enable_budget_alerts`         | `true`              | Budget and alert resources            | Minimal/none for the configuration itself; requires billing permissions. |
| `allow_ecr_force_delete`       | `false`             | ECR destruction behavior              | Allow only during deliberate full teardown.                              |

Changing an `enable_*` flag from `true` to `false` can remove that Terraform-managed component after `terraform apply`. It is not a substitute for a final environment teardown.

## Phase 2: Network baseline

### Required resources

| Purpose                         | Resource types to investigate                                                           |
| ------------------------------- | --------------------------------------------------------------------------------------- |
| Isolated network                | `aws_vpc`                                                                               |
| High-availability subnet layout | `aws_subnet` in two Availability Zones                                                  |
| Routing                         | `aws_route_table`, `aws_route_table_association`, and only required `aws_route` entries |
| Cluster/node controls           | `aws_security_group`, `aws_vpc_security_group_rule`                                     |
| Optional public egress          | `aws_internet_gateway`, conditional `aws_nat_gateway`, `aws_eip`                        |
| Optional private AWS access     | `aws_vpc_endpoint`, endpoint security group                                             |

### Egress decision

Do not add a NAT Gateway by default. Before creating EKS nodes, choose one documented approach:

1. **NAT Gateway path:** simpler outbound connectivity but recurring NAT charges.
2. **Private-endpoint path:** use only the VPC endpoints actually required by the workload, such as ECR API/DKR and S3; interface endpoints also have recurring charges.

Compare the expected session duration and required AWS services before choosing. The project must record why the chosen option is appropriate for the lab.

## Phase 3: Image registry and CI identity

### ECR resources

- `aws_ecr_repository`
- `aws_ecr_lifecycle_policy`
- Optional `aws_ecr_repository_policy` only when a specific access requirement exists

Configure immutable tags where practical, scan-on-push as defense in depth, and a lifecycle policy that removes old lab images. Trivy remains the primary build gate.

The implemented baseline uses customer-managed KMS keys for ECR and VPC Flow Logs, with rotation enabled. Key policies retain account-root break-glass administration and constrain service use with `kms:ViaService`; CloudWatch Logs is additionally constrained by its encryption context. These direct key-policy patterns trigger Checkov's generic `CKV_AWS_109`, `CKV_AWS_111`, and `CKV_AWS_356` heuristics, so CI and pre-commit exclude only those three checks with the rationale in [the Checkov baseline](checkov-baseline.md).

### GitHub OIDC resources

- `aws_iam_openid_connect_provider` for GitHub Actions
- `aws_iam_role` for CI
- `aws_iam_role_policy` or managed-policy attachments scoped to the project ECR repository

The applied first CI role is **plan-only**. Its trust policy requires the exact GitHub Actions subject for the protected `terraform-plan` environment, and it has remote-state access plus temporary AWS read-only permissions required for Terraform refresh and planning. It cannot apply infrastructure or publish images. A separate application delivery role and protected environment are required before automated ECR publication or deployment.

## Phase 4: EKS control plane

### Required resources

| Purpose                          | Resource types to investigate                                 |
| -------------------------------- | ------------------------------------------------------------- |
| Cluster IAM identity             | `aws_iam_role`, required EKS policy attachment                |
| EKS cluster                      | `aws_eks_cluster`                                             |
| Controlled control-plane logging | `aws_cloudwatch_log_group`                                    |
| Core cluster functionality       | `aws_eks_addon` for selected add-ons                          |
| Workload identity foundation     | `aws_iam_openid_connect_provider` based on the EKS issuer URL |

Create the CloudWatch log group before the cluster so retention is controlled from the beginning. Enable only the log categories you intend to investigate.

The EKS cluster is the first substantial recurring cost. Do not apply this phase until budget alerts, feature flags, and the network egress decision are reviewed.

## Phase 5: EC2 managed node group

### Required resources

| Purpose           | Resource types to investigate                                       |
| ----------------- | ------------------------------------------------------------------- |
| Node IAM identity | `aws_iam_role` and narrowly required EKS/EC2/ECR policy attachments |
| Node hardening    | `aws_launch_template`                                               |
| Managed compute   | `aws_eks_node_group`                                                |

### Node-group design

- Start with one small on-demand node during active lab sessions.
- Set desired, minimum, and maximum node counts explicitly.
- Use a launch template to require IMDSv2 and configure encrypted root storage.
- Keep node security-group ingress minimal.
- Do not expose SSH; use an approved managed access method only if an exercise requires it.
- Review EKS-optimized AMI updates and node-roll procedures as part of the vulnerability-remediation exercise.

## Phase 6: Workload and security controls

Do not implement application Kubernetes resources in Terraform initially.

1. Deploy reviewed raw manifests using `kubectl`: namespace, Deployment, Service, resource limits, probes, and security context.
2. Pull the ECR image by immutable digest.
3. Verify access with `kubectl port-forward`.
4. Build GitHub Actions testing, image build, Trivy scanning, report retention, and ECR publication.
5. Convert the workload to a Helm chart.
6. Install Falco with Helm; run controlled detection exercises.
7. Add Argo CD only after the Helm path is understood and repeatable.

See [Security controls: Trivy and Falco](security-controls.md) for the security-gate and runtime-detection requirements.

## Validation gates

| Before proceeding | Required evidence                                                                             |
| ----------------- | --------------------------------------------------------------------------------------------- |
| Remote state      | State bucket is versioned, encrypted, non-public, and accessible only to intended identities. |
| Network           | `terraform plan` shows only intended networking and no unplanned NAT/endpoints.               |
| ECR/OIDC          | CI role trust policy is restricted to the intended GitHub repository/ref conditions.          |
| EKS               | Cluster endpoint, logging, IAM role, and selected add-ons are verified.                       |
| Node group        | Node joins successfully; IMDSv2 and encrypted root volume are verified.                       |
| Workload          | Non-root application is healthy through port-forward and runs by image digest.                |
| Security          | Trivy report is retained; Falco controlled alert is investigated and documented.              |

## Teardown procedure

Use Terraform to remove every temporary environment resource. Do not rely only on disabling application deployments.

1. Remove workload resources and later Helm/Argo CD resources if present.
2. Set `allow_ecr_force_delete = true` only if intentionally deleting the image repository and its images.
3. Run `terraform destroy` for the main `infra/` environment.
4. Verify that EKS, node groups, EC2 instances, EBS volumes, NAT Gateways, interface endpoints, load balancers, public IPv4/EIPs, and log groups are absent unless intentionally retained.
5. Retain the bootstrap state bucket only while it is needed; remove it deliberately as a separate final action.
6. Record the cleanup date and any intentional residual cost.
