resource "aws_kms_key" "ecr" {
  description         = "KMS key for ${local.name_prefix} ECR images"
  enable_key_rotation = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecr-kms"
    Role = "container-registry-encryption"
  })
}

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
      "kms:ReEncrypt*"
    ]

    resources = ["*"]
  }
}

