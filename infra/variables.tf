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
  default     = "development"
}

#networking variables
variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
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

#Cost Services Switches

variable "enable_eks" {
  description = "Enable or disable the creation of the EKS cluster."
  type        = bool
  default     = false
}

variable "enable_eks_node_groups" {
  description = "Enable or disable the creation of EKS node groups."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable or disable the creation of NAT Gateways."
  type        = bool
  default     = false
}

variable "enable_ingress" {
  description = "Enable or disable the creation of Ingress resources."
  type        = bool
  default     = false
}

variable "enable_private_endpoints" {
  description = "Enable or disable the creation of private endpoints for AWS services."
  type        = bool
  default     = false
}

#resource cleanup deadline
variable "cleanup_deadline" {
  description = "The deadline for resource cleanup, in ISO 8601 format."
  type        = string

  validation {
    condition     = can(formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", var.cleanup_deadline))
    error_message = "cleanup_deadline must be a valid ISO 8601 UTC timestamp."
  }
}

