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

  # 무료 모드에서 유료 플래그 실수 방지 (plan/apply 모두 실패)
  lifecycle {
    precondition {
      condition = (
        var.acknowledge_paid_aws
        || (
          !var.enable_eks
          && !var.enable_bastion
          && !var.enable_ecr
          && var.nat_gateway_count == 0
        )
      )
      error_message = "무료 모드(acknowledge_paid_aws=false): enable_eks/bastion/ecr 와 NAT 를 켤 수 없습니다. docs/FREE_MODE.md 참고. 로컬은 ./scripts/dev-free.sh 만 사용하세요."
    }
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
}
