resource "aws_vpc_endpoint" "s3" {
  count = var.enable_private_endpoints ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = local.s3_gateway_service
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-s3-endpoint"
    Role = "s3-gateway-endpoint"
  })
}


resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_private_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = local.ecr_api_service
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecr-api-endpoint"
    Role = "ecr-interface-endpoint"
  })
}


resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_private_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = local.ecr_dkr_service
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecr-dkr-endpoint"
    Role = "ecr-interface-endpoint"
  })
}

resource "aws_vpc_endpoint" "sts" {
  count = var.enable_private_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = local.sts_service
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sts-endpoint"
    Role = "sts-interface-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2" {
  count = var.enable_private_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = local.ec2_service
  vpc_endpoint_type   = "Interface"
  subnet_ids          = values(aws_subnet.private)[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-endpoint"
    Role = "ec2-interface-endpoint"
  })
}
