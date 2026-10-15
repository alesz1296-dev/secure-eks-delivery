variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "The availability zones to deploy resources in."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "secure-eks-delivery"
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "bootstrap"
}

variable "state_bucket_name" {
  description = "The name of the S3 bucket to store Terraform state."
  type        = string
  default     = "secure-eks-delivery-tfstate-535079145207"
}

variable "state_version_retention_days" {
  description = "The number of days to retain versions of the Terraform state in the S3 bucket."
  type        = number
  default     = 90
}

variable "extra_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "allowed_account_ids" {
  description = "List of allowed AWS account IDs for cross-account access."
  type        = list(string)
  default     = ["535079145207"]
}