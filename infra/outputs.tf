#networking outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "private_subnet_cidrs" {
  value = [for subnet in aws_subnet.private : subnet.cidr_block]
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

#Security groups outputs
output "eks_cluster_security_group_id" {
  value = aws_security_group.eks_cluster.id
}

output "eks_node_security_group_id" {
  value = aws_security_group.eks_nodes.id
}

#ECR outputs
output "ecr_repository_url" {
  value = aws_ecr_repository.fastapi.repository_url
}

output "ecr_repository_arn" {
  value = aws_ecr_repository.fastapi.arn
}

output "ecr_repository_name" {
  value = aws_ecr_repository.fastapi.name
}

# EKS IAM roles outputs
output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}

output "eks_node_instance_profile_name" {
  value = aws_iam_instance_profile.eks_nodes.name
}

#OIDC
output "github_terraform_plan_role_arn" {
  description = "OIDC role ARN for the protected terraform-plan environment."
  value       = var.enable_github_oidc ? aws_iam_role.github_terraform_plan[0].arn : null
}

output "github_container_delivery_role_arn" {
  description = "OIDC role ARN for the protected container-delivery environment."
  value       = var.enable_github_oidc ? aws_iam_role.github_container_delivery[0].arn : null
}
