resource "aws_ecr_repository" "fastapi" {
  name                 = "${local.name_prefix}-fastapi"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = data.aws_kms_alias.ecr.target_key_arn
  }

  # Removed AES256 encryption because moving to KMS encryption. If you want to use AES256, uncomment the following lines and comment out the KMS encryption block above.
  #   encryption_configuration {
  #    encryption_type = "AES256"
  #  }


  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-fastapi-ecr"
    Role = "container-registry"
  })
}



resource "aws_ecr_lifecycle_policy" "fastapi" {
  repository = aws_ecr_repository.fastapi.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after seven days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep the latest ten tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["git-", "build-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
