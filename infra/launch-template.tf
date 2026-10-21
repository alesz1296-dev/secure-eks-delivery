resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${local.name_prefix}-eks-nodes-"

  vpc_security_group_ids = [
    aws_security_group.eks_nodes.id
  ]

  metadata_options {
    http_tokens                 = "required" # forces IMDSv2
    http_put_response_hop_limit = 1 # limits the number of network hops for IMDS requests to 1, which is a security best practice.
  }

  block_device_mappings { # Explicitly enforce encrypted, disposable GP3 root storage for worker nodes.
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.eks_node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.cluster_name}-nodes"
      Role = "eks-worker-nodes"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(local.common_tags, {
      Name = "${local.cluster_name}-nodes-volume"
      Role = "eks-worker-node-storage"
    })
  }
}