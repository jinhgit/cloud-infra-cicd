# ===================================================
# AWS 기본 설정 변수
# ===================================================

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "유효한 AWS 리전 형식이어야 합니다 (예: ap-northeast-2)."
  }
}

# ===================================================
# 프로젝트 메타데이터 변수
# ===================================================

variable "environment" {
  description = "배포 환경 (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment는 'dev', 'staging', 'prod' 중 하나여야 합니다."
  }
}

variable "project_name" {
  description = "프로젝트명 (리소스 이름 접두사로 사용)"
  type        = string
  default     = "cloud-infra"

  validation {
    condition     = length(var.project_name) <= 15
    error_message = "project_name은 15자 이하여야 합니다."
  }
}

# ===================================================
# VPC 및 네트워크 변수
# ===================================================

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "유효한 CIDR 형식이어야 합니다."
  }
}

# ===================================================
# 서브넷 CIDR 변수 (가용영역별)
# ===================================================

variable "public_subnet_cidrs" {
  description = "Public 서브넷 CIDR 블록 (AZ-A, AZ-C)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "정확히 2개의 Public 서브넷 CIDR을 지정해야 합니다."
  }
}

variable "private_web_subnet_cidrs" {
  description = "Private Web 서브넷 CIDR 블록 (AZ-A, AZ-C)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_web_subnet_cidrs) == 2
    error_message = "정확히 2개의 Private Web 서브넷 CIDR을 지정해야 합니다."
  }
}

variable "private_db_subnet_cidrs" {
  description = "Private DB 서브넷 CIDR 블록 (AZ-A, AZ-C)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]

  validation {
    condition     = length(var.private_db_subnet_cidrs) == 2
    error_message = "정확히 2개의 Private DB 서브넷 CIDR을 지정해야 합니다."
  }
}

# ===================================================
# 보안 설정 변수
# ===================================================

variable "my_ip" {
  description = "Bastion Host SSH 접속을 허용할 개발자 공인 IP (예: 203.0.113.42/32)"
  type        = string

  validation {
    condition     = can(cidrhost(var.my_ip, 0))
    error_message = "유효한 IP CIDR 형식이어야 합니다 (예: 203.0.113.42/32)."
  }
}

# ===================================================
# 태그 변수
# ===================================================

variable "tags" {
  description = "모든 리소스에 적용할 추가 태그"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "CloudInfra"
  }
}
