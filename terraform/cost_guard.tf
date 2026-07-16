# ===================================================
# 비용 가드 — 기본 무료 모드
# acknowledge_paid_aws = false 이면 유료 리소스 생성 차단
# ===================================================

check "free_mode_blocks_paid_flags" {
  assert {
    condition = (
      var.acknowledge_paid_aws
      || (
        !var.enable_eks
        && !var.enable_bastion
        && !var.enable_ecr
        && var.nat_gateway_count == 0
      )
    )
    error_message = <<-EOT
      [비용 가드] 무료 모드입니다. 유료 AWS 리소스 생성이 차단되었습니다.

      허용된 작업 (과금 없음):
        - 로컬: docker compose up --build
        - 로컬: cd BE && npm test
        - CI: terraform fmt / validate / plan (시크릿 있어도 apply 안 함)
        - terraform plan (유료 플래그 끈 상태)

      AWS 데모(NAT/EKS/Bastion)가 꼭 필요할 때만:
        1) terraform.tfvars 에
             acknowledge_paid_aws = true
             nat_gateway_count    = 2   # 또는 1
             enable_eks / enable_bastion 필요한 것만 true
        2) apply 후 즉시 destroy
        3) 문서: docs/FREE_MODE.md

      현재: acknowledge_paid_aws=false 인데 enable_* 또는 nat_gateway_count>0 이 켜져 있습니다.
    EOT
  }
}

check "eks_implies_nat" {
  assert {
    condition     = !var.enable_eks || (var.acknowledge_paid_aws && var.nat_gateway_count > 0)
    error_message = "EKS 를 쓰려면 acknowledge_paid_aws=true 이고 nat_gateway_count 가 1 또는 2 여야 합니다 (Private 노드 아웃바운드)."
  }
}
