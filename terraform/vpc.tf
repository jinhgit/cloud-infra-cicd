# ===================================================
# VPC 생성
# ===================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ===================================================
# Internet Gateway 생성
# ===================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }

  depends_on = [aws_vpc.main]
}

# ===================================================
# 가용영역 데이터 소스
# ===================================================

data "aws_availability_zones" "available" {
  state = "available"
}
