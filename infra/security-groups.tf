resource "aws_security_group" "eks_cluster" {
  name_prefix = "${local.cluster_name}-cluster-"
  description = "Security group for the EKS control plane"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-cluster-sg"
    Role = "eks-control-plane"
  })
}

resource "aws_security_group" "eks_nodes" {
  name_prefix = "${local.cluster_name}-nodes-"
  description = "Security group for the EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-nodes-sg"
    Role = "eks-worker-nodes"
  })
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No inbound traffic by default.
  ingress = []

  # No outbound traffic by default.
  egress = []

  tags = merge(local.common_tags, {
    Name = "${local.vpc_name}-default-deny"
  })
}

resource "aws_vpc_security_group_ingress_rule" "nodes_to_cluster_api" {
  security_group_id            = aws_security_group.eks_cluster.id
  referenced_security_group_id = aws_security_group.eks_nodes.id #direct reference to SG, not CIDRs

  ip_protocol = var.protocol
  from_port   = var.kubernetes_api_port
  to_port     = var.kubernetes_api_port

  description = "Allow worker nodes to reach the Kubernetes API"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_to_nodes_kubelet" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_cluster.id #direct reference to SG, not CIDRs

  ip_protocol = "tcp"
  from_port   = 10250
  to_port     = 10250

  description = "Allow EKS control plane to reach kubelet on worker nodes"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_to_nodes_webhook" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_cluster.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Allow EKS control plane to reach node webhooks"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_to_nodes" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"

  description = "Allow worker nodes to communicate with one another"
}
