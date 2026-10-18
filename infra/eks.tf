resource "aws_eks_cluster" "main" {
  count = var.enable_eks ? 1 : 0

  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = values(aws_subnet.private)[*].id
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true #SSM, Private CI/CD, Site-to-Site VPN, and/or Direct Connect are required for private access to the EKS API server. If you need public access, set this to true and configure the public_access_cidrs variable to limit access to trusted IPs.
    public_access_cidrs     = var.eks_public_access_cidrs
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true #add explicit EKS access entries, verify them, and then remove the bootstrap permission in a controlled change
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator" #,
    #"scheduler",
    #"controllerManager"
  ]

  kubernetes_network_config {
    service_ipv4_cidr = var.eks_service_ipv4_cidr
  }


  tags = merge(local.common_tags, {
    Name = local.cluster_name
    Role = "eks-control-plane"
  })
}

resource "aws_eks_node_group" "main" {
  count = var.enable_eks_node_group && var.enable_eks ? 1 : 0

  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${local.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = values(aws_subnet.private)[*].id

  instance_types = var.eks_node_instance_types
  capacity_type  = var.eks_node_capacity_type
  ami_type       = var.eks_node_ami_type

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = var.eks_node_desired_size
    min_size     = var.eks_node_min_size
    max_size     = var.eks_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "worker"
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-nodes"
    Role = "eks-worker-nodes"
  })
}


