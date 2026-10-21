# Checkov Terraform Baseline

## Scan evidence

Checkov was run manually against the `infra/` Terraform configuration before
CI integration.

```text
Tool:           Checkov 3.3.30
Framework:      terraform
Files scanned:  14
Passed checks:  89
Failed checks:  5 (initial baseline)
Skipped checks: 0
```

## Findings and disposition

| Check | Resource | Result | Disposition |
| --- | --- | --- | --- |
| `CKV_AWS_341` | `aws_launch_template.eks_nodes` | IMDS response hop limit is `2` | Review and reduce to `1` unless EKS bootstrap testing proves that a higher value is required. |
| `CKV_AWS_136` | `aws_ecr_repository.fastapi` | ECR uses `AES256` rather than customer-managed KMS encryption | Decide whether the lab requires a customer-managed KMS key; record the cost and operational trade-off. |
| `CKV_AWS_25` | `aws_vpc_security_group_ingress_rule.cluster_to_nodes` | Reported possible public RDP exposure | Triage as a likely false positive: the rule references the EKS cluster security group and does not use `0.0.0.0/0`. Suppress only with this justification after review. |
| `CKV2_AWS_11` | `aws_vpc.main` | VPC Flow Logs are not configured | Decide whether flow logging is required for the lab baseline and document the destination and retention if enabled. |
| `CKV2_AWS_12` | `aws_vpc.main` | Default VPC security group is not explicitly restricted | Add an explicit default-security-group rule set that removes unintended ingress and egress. |

### Follow-up KMS-policy scan

After adding customer-managed KMS encryption for ECR, Checkov reported three
additional policy checks against `data.aws_iam_policy_document.ecr_kms`:

| Check | Policy element | Disposition |
| --- | --- | --- |
| `CKV_AWS_109` | Account-root administrator statement with `kms:*` | Review as an intentional key-administration path; do not remove without defining a replacement recovery administrator. |
| `CKV_AWS_111` | KMS write-capable actions in the key policy | Review the administrator and ECR-use statements separately; retain only the cryptographic actions required by ECR. |
| `CKV_AWS_356` | `resources = ["*"]` in the key policy | Documented policy-model exception: KMS key policies commonly use `*` because the policy is attached directly to the key. |

These findings do not indicate that the KMS key is publicly accessible. The
policy principals remain the owning account root and the ECR service. The
standard root administrator statement is retained for key recovery and
administration. Any Checkov suppression must be narrowly scoped and include
the policy rationale.

The subsequent scan also continued to report `CKV_AWS_25` for the
`cluster_to_nodes` rule. This remains a likely false positive because the rule
uses `referenced_security_group_id` for the EKS cluster security group rather
than a public CIDR. The port variables must still be reviewed before adding a
formal suppression.

The 89 passing checks cover, among other areas, IAM policy restrictions, IMDSv2,
encrypted node storage, private subnet behavior, ECR scan-on-push, immutable
ECR tags, security-group descriptions, and hard-coded credential checks.

## Current status

This is a manual baseline, not yet a CI gate. Findings remain open for
remediation or documented exception. The Checkov task should not be marked
complete until the scan is reproducible in GitHub Actions and its report is
retained as a workflow artifact.
