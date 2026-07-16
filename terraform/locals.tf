# ===================================================
# 로컬 변수 (계산된 값 및 공통 설정)
# ===================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      CreatedBy   = "Terraform"
      ManagedBy   = "Terraform"
      CostMode    = var.acknowledge_paid_aws ? "paid-demo" : "free"
    },
    var.tags
  )

  # PRD: ap-northeast-2a, ap-northeast-2c 고정
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
  az_count           = length(local.availability_zones)

  # ----- 비용 안전 모드 -----
  # acknowledge_paid_aws=false 이면 유료 리소스 count 전부 0
  paid_ok = var.acknowledge_paid_aws

  # NAT: 유료 동의 + 개수 > 0 일 때만
  nat_count = local.paid_ok ? var.nat_gateway_count : 0

  # Bastion / EKS / ECR
  bastion_enabled = local.paid_ok && var.enable_bastion
  eks_enabled     = local.paid_ok && var.enable_eks
  ecr_enabled     = local.paid_ok && (var.enable_ecr || var.enable_eks)

  # EKS
  eks_cluster_name    = "${local.name_prefix}-eks"
  eks_cluster_tag_key = "kubernetes.io/cluster/${local.eks_cluster_name}"
}
