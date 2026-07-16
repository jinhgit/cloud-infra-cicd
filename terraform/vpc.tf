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

  # 1) 무료 모드에서 유료 플래그 차단
  # 2) 유료 모드라도 confirm 문구 없으면 차단 (사용자 명시 승인 필수)
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
      error_message = "무료 모드(acknowledge_paid_aws=false): enable_eks/bastion/ecr 와 NAT 를 켤 수 없습니다. docs/FREE_MODE.md · ./scripts/dev-free.sh"
    }

    precondition {
      condition = (
        !var.acknowledge_paid_aws
        || var.confirm_paid_apply == "YES_I_ACCEPT_AWS_CHARGES"
      )
      error_message = <<-EOT
        유료 AWS apply 가 차단되었습니다.
        acknowledge_paid_aws=true 이면 반드시 confirm_paid_apply = "YES_I_ACCEPT_AWS_CHARGES"
        를 설정하세요. 이 값은 사용자(본인)가 과금에 동의한 뒤에만 넣습니다.
        권장: ./scripts/terraform-apply-paid.sh (대화형 확인)
        문서: docs/FREE_MODE.md
      EOT
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
