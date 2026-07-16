# ===================================================
# Terraform 설정 및 Provider
# Stage 1: 네트워크 / Stage 4: EKS (var.enable_eks)
# ===================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # 향후 S3 + DynamoDB Remote State
  # backend "s3" {
  #   bucket         = "terraform-state-bucket"
  #   key            = "dev/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
