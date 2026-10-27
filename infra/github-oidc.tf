data "tls_certificate" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count           = var.enable_github_oidc ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions[0].certificates[0].sha1_fingerprint]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-oidc"
    Role = "github-actions-identity"
  })
}

data "aws_iam_policy_document" "github_plan_trust" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions[0].arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_oidc_subject]
    }
  }
}

resource "aws_iam_role" "github_terraform_plan" {
  count              = var.enable_github_oidc ? 1 : 0
  name               = "${local.name_prefix}-github-plan"
  assume_role_policy = data.aws_iam_policy_document.github_plan_trust[0].json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-plan"
    Role = "github-actions-terraform-plan"
  })
}

data "aws_iam_policy_document" "github_terraform_plan_backend" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::secure-eks-delivery-tfstate-535079145207"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["infra/terraform.tfstate"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::secure-eks-delivery-tfstate-535079145207/infra/terraform.tfstate"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::secure-eks-delivery-tfstate-535079145207/infra/terraform.tfstate.tflock"]
  }
}

resource "aws_iam_role_policy" "github_terraform_plan_backend" {
  count  = var.enable_github_oidc ? 1 : 0
  name   = "${local.name_prefix}-github-plan-backend"
  role   = aws_iam_role.github_terraform_plan[0].id
  policy = data.aws_iam_policy_document.github_terraform_plan_backend[0].json
}

resource "aws_iam_role_policy_attachment" "github_terraform_plan_read_only" {
  count      = var.enable_github_oidc ? 1 : 0
  role       = aws_iam_role.github_terraform_plan[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# This role is deliberately separate from the Terraform plan role. It can
# publish image layers and manifests only to this repository; it cannot plan or
# apply infrastructure, administer EKS, or modify IAM.
data "aws_iam_policy_document" "github_container_delivery_trust" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions[0].arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_container_delivery_oidc_subject]
    }
  }
}

resource "aws_iam_role" "github_container_delivery" {
  count              = var.enable_github_oidc ? 1 : 0
  name               = "${local.name_prefix}-github-container-delivery"
  assume_role_policy = data.aws_iam_policy_document.github_container_delivery_trust[0].json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-container-delivery"
    Role = "github-actions-ecr-publisher"
  })
}

data "aws_iam_policy_document" "github_container_delivery_ecr" {
  count = var.enable_github_oidc ? 1 : 0

  # AWS does not support resource-level permissions for this token request.
  statement {
    sid       = "GetECRAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushOnlyToProjectRepository"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [aws_ecr_repository.fastapi.arn]
  }
}

resource "aws_iam_role_policy" "github_container_delivery_ecr" {
  count  = var.enable_github_oidc ? 1 : 0
  name   = "${local.name_prefix}-github-container-delivery-ecr"
  role   = aws_iam_role.github_container_delivery[0].id
  policy = data.aws_iam_policy_document.github_container_delivery_ecr[0].json
}
