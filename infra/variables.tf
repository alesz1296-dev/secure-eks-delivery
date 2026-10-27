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

variable "enable_eks_node_group" {
  description = "Enable or disable the creation of EKS node groups."
  type        = bool
  default     = false
}

#variable "enable_nat_gateway" {
#  description = "Enable or disable the creation of NAT Gateways."
#  type        = bool
#  default     = false
#}

#variable "enable_ingress" {
#  description = "Enable or disable the creation of Ingress resources."
#  type        = bool
#  default     = false
#}

variable "enable_private_endpoints" {
  description = "Enable or disable the creation of private endpoints for AWS services."
  type        = bool
  default     = false
}

variable "enable_github_oidc" {
  description = "Create the GitHub Actions OIDC provider and plan identity role."
  type        = bool
  default     = false
}

variable "github_oidc_subject" {
  description = "Exact GitHub OIDC subject claim for the protected terraform-plan environment."
  type        = string
  default     = "repo:alesz1296-dev@257826828/secure-eks-delivery@1419922858:environment:terraform-plan"
}

variable "github_container_delivery_oidc_subject" {
  description = "Exact GitHub OIDC subject claim for the protected container-delivery environment."
  type        = string
  default     = "repo:alesz1296-dev@257826828/secure-eks-delivery@1419922858:environment:container-delivery"
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

#variable "enable_aws_load_balancer_controller" {
#  description = "Enable or disable the creation of AWS Load Balancer Controller."
#  type        = bool
#  default     = false
#}


#networking variables
variable "protocol" {
  description = "The protocol for security group rules."
  type        = string
  default     = "tcp"
}

variable "kubernetes_api_port" {
  description = "The Kubernetes API port for security group rules."
  type        = number
  default     = 443
}
#ECR variables
variable "ecr_force_delete" {
  description = "Force delete ECR resources even if images exist."
  type        = bool
  default     = false
}

#EKS variables
variable "eks_version" {
  description = "Kubernetes version for EKS."
  type        = string
  default     = "1.36" #EKS standard version as of 2026-10-16
}


variable "eks_public_access_cidrs" {
  description = "CIDR ranges allowed to access the public EKS API endpoint."
  type        = list(string)
  default     = []
}

variable "eks_service_ipv4_cidr" {
  description = "Kubernetes Service CIDR. Must not overlap the VPC or connected networks."
  type        = string
  default     = "172.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.eks_service_ipv4_cidr, 0))
    error_message = "eks_service_ipv4_cidr must be a valid IPv4 CIDR block."
  }
}

#EKS Node Group variables
variable "eks_node_instance_types" {
  type    = list(string)
  default = ["t3.small"]
}

variable "eks_node_capacity_type" {
  description = "EC2 capacity type for EKS nodes."
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_node_ami_type" {
  description = "AMI type for EKS managed nodes."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "eks_node_disk_size" {
  type    = number
  default = 20
}

variable "eks_node_desired_size" {
  type    = number
  default = 1
}

variable "eks_node_min_size" {
  type    = number
  default = 1
}

variable "eks_node_max_size" {
  type    = number
  default = 2
}

#endpoints variables

#variable "vpc_endpoint_subnet_ids" {
#  type    = list(string)
#  default = []
#}


variable "vpc_endpoint_from_port" {
  description = "The lowest port for VPC endpoint security group rules."
  type        = number
  default     = 443
}

variable "vpc_endpoint_to_port" {
  description = "The highest port for VPC endpoint security group rules."
  type        = number
  default     = 443
}
