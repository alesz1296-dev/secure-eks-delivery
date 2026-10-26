
resource "aws_kms_key" "ecr" {
  description         = "KMS key for ${local.name_prefix} ECR images"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ecr_kms.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecr-kms"
    Role = "container-registry-encryption"
  })
}

data "aws_caller_identity" "current" {}

#checkov:skip=CKV_AWS_109:KMS account administration is retained as the break-glass recovery path
#checkov:skip=CKV_AWS_111:ECR cryptographic use is constrained by kms:ViaService
#checkov:skip=CKV_AWS_356:KMS key policies require Resource * for key-local permissions
data "aws_iam_policy_document" "ecr_kms" {
  statement {
    sid    = "EnableAccountAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowECRUse"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecr.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ecr.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "vpc_flow_logs" {
  description         = "KMS key for VPC Flow Logs"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.vpc_flow_logs_kms.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-flow-logs-kms"
    Role = "network-observability"
  })
}
