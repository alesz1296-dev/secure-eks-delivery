resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = local.vpc_name
    }
  )
}

resource "aws_subnet" "private" {
  for_each = {
    for index, az in var.availability_zones :
    az => index
  }

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)

  tags = merge(
    local.common_tags,
    local.eks_private_subnet_tags,
    {
      Name = "${local.name_prefix}-subnet-private-${each.key}"
      Tier = "private"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rtb-private"
    Tier = "private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${local.cluster_name}/flow-logs"
  retention_in_days = 365
  kms_key_id        = data.aws_kms_alias.logs.target_key_arn

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-vpc-flow-logs"
    Role = "network-observability"
  })
}
