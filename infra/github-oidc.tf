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
      values   = ["repo:alesz1296-dev@257826828/secure-eks-delivery@1419922858:environment:terraform-plan"]
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
