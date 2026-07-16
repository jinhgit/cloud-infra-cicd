# ===================================================
# Terraform 설정 및 Provider
# ===================================================

terraform {
  # Terraform 버전 요구사항
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 향후 S3 + DynamoDB Remote State 설정
  # backend "s3" {
  #   bucket         = "terraform-state-bucket"
  #   key            = "prod/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock"
  # }
}

# ===================================================
# AWS Provider 설정
# ===================================================

provider "aws" {
  region = var.aws_region
}

# ===================================================
# 주요 출력값 (콘솔 출력 확인용)
# ===================================================

output "deployment_info" {
  description = "배포 정보 요약"
  value = {
    vpc_id       = aws_vpc.main.id
    region       = var.aws_region
    environment  = var.environment
    project_name = var.project_name
  }
}
