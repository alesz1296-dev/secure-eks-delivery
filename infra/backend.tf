terraform {
  backend "s3" {
    bucket       = "secure-eks-delivery-tfstate-535079145207"
    key          = "infra/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}