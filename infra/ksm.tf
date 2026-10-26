
data "aws_kms_alias" "ecr" {
  name = "alias/aws/ecr"
}

data "aws_kms_alias" "logs" {
  name = "alias/aws/logs"
}
