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
  description = "Private Web 서브넷 CIDR (EKS 노드 / 웹)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_web_subnet_cidrs) == 2
    error_message = "정확히 2개의 Private Web 서브넷 CIDR을 지정해야 합니다."
  }
}

variable "private_db_subnet_cidrs" {
  description = "Private DB 서브넷 CIDR"
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
  description = "Bastion/EKS API 공개 접근 허용 개발자 공인 IP (예: 203.0.113.42/32)"
  type        = string

  validation {
    condition     = can(cidrhost(var.my_ip, 0))
    error_message = "유효한 IP CIDR 형식이어야 합니다 (예: 203.0.113.42/32)."
  }
}

variable "tags" {
  description = "모든 리소스에 적용할 추가 태그"
  type        = map(string)
  default = {
    Application = "CloudInfra"
  }
}

# ===================================================
# EKS / ECR (Stage 4) — 기본 비활성 (비용 통제)
# ===================================================

variable "enable_eks" {
  description = "true 시 EKS 클러스터·노드·OIDC·LB Controller IRSA 생성 (과금 주의)"
  type        = bool
  default     = false
}

variable "enable_ecr" {
  description = "true 시 FE/BE ECR 리포지토리 생성 (enable_eks와 독립 가능)"
  type        = bool
  default     = false
}

variable "eks_cluster_version" {
  description = "EKS Kubernetes 버전"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_type" {
  description = "관리형 노드 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_desired_size" {
  description = "노드 desired capacity"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "노드 min capacity"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "노드 max capacity"
  type        = number
  default     = 4
}

variable "eks_endpoint_public_access" {
  description = "EKS API 퍼블릭 엔드포인트 사용 여부"
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "EKS API 퍼블릭 접근 CIDR (비우면 my_ip 사용)"
  type        = list(string)
  default     = []
}

# ===================================================
# Bastion Host (Stage 2)
# ===================================================

variable "enable_bastion" {
  description = "true 시 Public 서브넷에 Bastion EC2 생성 (과금 주의 — 미사용 시 false/destroy)"
  type        = bool
  default     = false
}

variable "bastion_instance_type" {
  description = "Bastion 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "bastion_key_name" {
  description = "EC2 Key Pair 이름 (리전에 사전 생성). 빈 문자열이면 SSM Session Manager 만 사용"
  type        = string
  default     = ""
}

variable "bastion_volume_size" {
  description = "Bastion 루트 볼륨 GiB (AL2023 AMI 스냅샷 최소 약 30GiB)"
  type        = number
  default     = 30
}