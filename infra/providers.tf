provider "aws" {
  region              = var.aws_region
  allowed_account_ids = var.allowed_account_ids # use only approved accounts

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
