# ===================================================
# VPC 및 네트워크 출력값
# ===================================================

output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "Public 서브넷 ID 목록"
  value       = aws_subnet.public[*].id
}

output "private_web_subnet_ids" {
  description = "Private Web 서브넷 ID 목록 (EKS 노드)"
  value       = aws_subnet.private_web[*].id
}

output "private_db_subnet_ids" {
  description = "Private DB 서브넷 ID 목록"
  value       = aws_subnet.private_db[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway ID 목록"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_ips" {
  description = "NAT Gateway 공인 IP 목록"
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "Public 라우팅 테이블 ID"
  value       = aws_route_table.public.id
}

output "private_web_route_table_ids" {
  description = "Private Web RT ID 목록 (AZ별)"
  value       = aws_route_table.private_web[*].id
}

output "private_db_route_table_ids" {
  description = "Private DB RT ID 목록 (AZ별)"
  value       = aws_route_table.private_db[*].id
}

output "security_group_ids" {
  description = "보안 그룹 ID 맵"
  value = {
    alb     = aws_security_group.alb.id
    web_ec2 = aws_security_group.web_ec2.id
    bastion = aws_security_group.bastion.id
    rds     = aws_security_group.db.id
  }
}

# ===================================================
# EKS / ECR 출력 (비활성 시 null)
# ===================================================

output "eks_cluster_name" {
  description = "EKS 클러스터 이름 (enable_eks=false 이면 null)"
  value       = try(aws_eks_cluster.main[0].name, null)
}

output "eks_cluster_endpoint" {
  description = "EKS API 엔드포인트"
  value       = try(aws_eks_cluster.main[0].endpoint, null)
}

output "eks_cluster_version" {
  description = "EKS Kubernetes 버전"
  value       = try(aws_eks_cluster.main[0].version, null)
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN (IRSA)"
  value       = try(aws_iam_openid_connect_provider.eks[0].arn, null)
}

output "aws_lb_controller_role_arn" {
  description = "AWS Load Balancer Controller IRSA Role ARN"
  value       = try(aws_iam_role.aws_lb_controller[0].arn, null)
}

output "ecr_repository_urls" {
  description = "ECR 리포지토리 URL"
  value = local.ecr_enabled ? {
    fe = aws_ecr_repository.fe[0].repository_url
    be = aws_ecr_repository.be[0].repository_url
  } : null
}

output "kubeconfig_command" {
  description = "kubeconfig 갱신 명령"
  value = local.eks_enabled ? (
    "aws eks update-kubeconfig --region ${var.aws_region} --name ${local.eks_cluster_name}"
  ) : null
}

# ===================================================
# Bastion
# ===================================================

output "bastion_instance_id" {
  description = "Bastion 인스턴스 ID (enable_bastion=false 이면 null)"
  value       = try(aws_instance.bastion[0].id, null)
}

output "bastion_public_ip" {
  description = "Bastion 공인 IP (SSH 접속용)"
  value       = try(aws_instance.bastion[0].public_ip, null)
}

output "bastion_private_ip" {
  description = "Bastion 사설 IP"
  value       = try(aws_instance.bastion[0].private_ip, null)
}

output "bastion_ssh_command" {
  description = "SSH 예시 (key pair 사용 시). 키 경로·사용자 확인 필요 (AL2023: ec2-user)"
  value = local.bastion_enabled && var.bastion_key_name != "" ? (
    "ssh -i /path/to/${var.bastion_key_name}.pem ec2-user@${try(aws_instance.bastion[0].public_ip, "PENDING")}"
  ) : null
}

output "bastion_ssm_command" {
  description = "SSM Session Manager 접속 명령"
  value = local.bastion_enabled ? (
    "aws ssm start-session --target ${try(aws_instance.bastion[0].id, "PENDING")} --region ${var.aws_region}"
  ) : null
}

# ===================================================
# 배포 요약
# ===================================================

output "deployment_summary" {
  description = "배포 요약 (비용 모드 포함)"
  value = {
    project              = var.project_name
    environment          = var.environment
    region               = var.aws_region
    vpc_cidr             = var.vpc_cidr
    availability_zones   = local.availability_zones
    public_subnets       = length(aws_subnet.public)
    private_web_subnets  = length(aws_subnet.private_web)
    private_db_subnets   = length(aws_subnet.private_db)
    acknowledge_paid_aws = var.acknowledge_paid_aws
    nat_gateways         = local.nat_count
    private_web_rts      = length(aws_route_table.private_web)
    private_db_rts       = length(aws_route_table.private_db)
    enable_bastion       = local.bastion_enabled
    enable_eks           = local.eks_enabled
    enable_ecr           = local.ecr_enabled
    eks_cluster_name     = local.eks_enabled ? local.eks_cluster_name : null
    bastion_public_ip    = try(aws_instance.bastion[0].public_ip, null)
    status = (
      !var.acknowledge_paid_aws ? "free-mode" :
      local.eks_enabled ? "paid-eks" :
      local.bastion_enabled ? "paid-bastion" :
      local.nat_count > 0 ? "paid-network" :
      "free-vpc-skeleton"
    )
  }
}
