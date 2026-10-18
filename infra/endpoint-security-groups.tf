resource "aws_vpc_security_group_ingress_rule" "nodes_to_vpc_endpoints" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = var.protocol
  from_port   = var.vpc_endpoint_from_port
  to_port     = var.vpc_endpoint_to_port

  description = "Allow worker nodes to access AWS interface endpoints"
}

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${local.name_prefix}-endpoints-"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-endpoint-sg"
    Role = "vpc-endpoints"
  })

  description = "Security group for private AWS interface endpoints"

}