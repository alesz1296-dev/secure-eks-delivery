#EKS Cluster IAM Role
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${local.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-cluster-role"
    Role = "eks-control-plane"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

#EKS Node Group IAM Role
data "aws_iam_policy_document" "eks_nodes_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_nodes" {
  name               = "${local.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_nodes_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-node-role"
    Role = "eks-worker-node"
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_nodes_ecr" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "eks_nodes_cni" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
# EC2 Instance Profile for EKS Nodes
# An instance profile is the EC2-compatible wrapper around an IAM role.
# EC2 instances cannot directly attach an IAM role. They attach an instance profile, and that profile contains the role.
resource "aws_iam_instance_profile" "eks_nodes" {
  name = "${local.cluster_name}-node-profile"
  role = aws_iam_role.eks_nodes.name

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-node-profile"
    Role = "eks-worker-node"
  })
}