locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  vpc_name     = "${local.name_prefix}-vpc"
  cluster_name = "${local.name_prefix}-eks"

  common_tags = merge(
    var.extra_tags,
    {
      Project         = var.project_name
      Environment     = var.environment
      ManagedBy       = "Terraform"
      CleanupDeadline = var.cleanup_deadline
    }
  )

  eks_private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  private_subnet_cidrs = [
    for index, az in var.availability_zones :
    cidrsubnet(var.vpc_cidr, 8, index)
  ]

  private_subnet_names = {
    for index, az in var.availability_zones :
    az => "${local.name_prefix}-${az}-private"
  }
}