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

resource "aws_vpc_security_group_ingress_rule" "nodes_to_cluster_api" {
  security_group_id            = aws_security_group.eks_cluster.id
  referenced_security_group_id = aws_security_group.eks_nodes.id #direct reference to SG, not CIDRs

  ip_protocol = var.protocol
  from_port   = var.kubernetes_api_port
  to_port     = var.kubernetes_api_port

  description = "Allow worker nodes to reach the Kubernetes API"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_to_nodes" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_cluster.id #direct reference to SG, not CIDRs

  ip_protocol = var.protocol
  from_port   = var.cluster_to_node_from_port
  to_port     = var.cluster_to_node_to_port

  description = "Allow Kubernetes API to reach worker nodes"
}

resource "aws_vpc_security_group_ingress_rule" "nodes_to_nodes" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"

  description = "Allow worker nodes to communicate with one another"
}