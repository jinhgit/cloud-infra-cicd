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
    },
    var.tags
  )

  # PRD: ap-northeast-2a, ap-northeast-2c 고정 (고가용성 학습용)
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
  az_count           = length(local.availability_zones)

  # EKS
  eks_cluster_name = "${local.name_prefix}-eks"
  eks_enabled      = var.enable_eks

  # AWS LB Controller가 서브넷을 찾을 때 사용하는 태그 키
  eks_cluster_tag_key = "kubernetes.io/cluster/${local.eks_cluster_name}"
}
