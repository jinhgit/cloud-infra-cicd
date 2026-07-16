# ===================================================
# 로컬 변수 (계산된 값 및 공통 설정)
# ===================================================

locals {
  # 리소스 이름 규칙: {project_name}-{resource_type}-{environment}
  name_prefix = "${var.project_name}-${var.environment}"

  # 공통 태그 정의
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      CreatedBy   = "Terraform"
    },
    var.tags
  )

  # 가용영역 목록
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]

  # 서브넷 매핑 (인덱스와 AZ 연결)
  az_count = length(local.availability_zones)
}
