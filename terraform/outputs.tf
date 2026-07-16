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

# ===================================================
# Public 서브넷 출력값
# ===================================================

output "public_subnet_ids" {
  description = "Public 서브넷 ID 목록"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "Public 서브넷 CIDR 목록"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_details" {
  description = "Public 서브넷 상세 정보"
  value = [
    for subnet in aws_subnet.public : {
      id                = subnet.id
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  ]
}

# ===================================================
# Private Web 서브넷 출력값
# ===================================================

output "private_web_subnet_ids" {
  description = "Private Web 서브넷 ID 목록"
  value       = aws_subnet.private_web[*].id
}

output "private_web_subnet_cidrs" {
  description = "Private Web 서브넷 CIDR 목록"
  value       = aws_subnet.private_web[*].cidr_block
}

output "private_web_subnet_details" {
  description = "Private Web 서브넷 상세 정보"
  value = [
    for subnet in aws_subnet.private_web : {
      id                = subnet.id
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  ]
}

# ===================================================
# Private DB 서브넷 출력값
# ===================================================

output "private_db_subnet_ids" {
  description = "Private DB 서브넷 ID 목록"
  value       = aws_subnet.private_db[*].id
}

output "private_db_subnet_cidrs" {
  description = "Private DB 서브넷 CIDR 목록"
  value       = aws_subnet.private_db[*].cidr_block
}

output "private_db_subnet_details" {
  description = "Private DB 서브넷 상세 정보"
  value = [
    for subnet in aws_subnet.private_db : {
      id                = subnet.id
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  ]
}

# ===================================================
# NAT Gateway 및 Elastic IP 출력값 (AZ별)
# ===================================================

output "nat_gateway_ids" {
  description = "NAT Gateway ID 목록 (AZ 인덱스 순서)"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_ips" {
  description = "NAT Gateway 공인 IP 목록 (EIP)"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_details" {
  description = "NAT Gateway 상세 정보"
  value = [
    for i, nat in aws_nat_gateway.main : {
      id                = nat.id
      public_ip         = aws_eip.nat[i].public_ip
      subnet_id         = nat.subnet_id
      availability_zone = local.availability_zones[i]
    }
  ]
}

# ===================================================
# 라우팅 테이블 출력값
# ===================================================

output "public_route_table_id" {
  description = "Public 라우팅 테이블 ID"
  value       = aws_route_table.public.id
}

output "private_web_route_table_ids" {
  description = "Private Web 라우팅 테이블 ID 목록 (AZ별)"
  value       = aws_route_table.private_web[*].id
}

output "private_db_route_table_ids" {
  description = "Private DB 라우팅 테이블 ID 목록 (AZ별)"
  value       = aws_route_table.private_db[*].id
}

# ===================================================
# 보안 그룹 출력값
# ===================================================

output "security_group_ids" {
  description = "생성된 보안 그룹 ID 맵"
  value = {
    alb     = aws_security_group.alb.id
    web_ec2 = aws_security_group.web_ec2.id
    bastion = aws_security_group.bastion.id
    rds     = aws_security_group.db.id
  }
}

output "alb_security_group_id" {
  description = "ALB 보안 그룹 ID"
  value       = aws_security_group.alb.id
}

output "web_ec2_security_group_id" {
  description = "Web EC2 보안 그룹 ID"
  value       = aws_security_group.web_ec2.id
}

output "bastion_security_group_id" {
  description = "Bastion Host 보안 그룹 ID"
  value       = aws_security_group.bastion.id
}

output "db_security_group_id" {
  description = "DB/RDS 보안 그룹 ID"
  value       = aws_security_group.db.id
}

# ===================================================
# 배포 요약 정보
# ===================================================

output "deployment_summary" {
  description = "1단계 배포 완료 요약"
  value = {
    project             = var.project_name
    environment         = var.environment
    region              = var.aws_region
    vpc_cidr            = var.vpc_cidr
    availability_zones  = local.availability_zones
    public_subnets      = length(aws_subnet.public)
    private_web_subnets = length(aws_subnet.private_web)
    private_db_subnets  = length(aws_subnet.private_db)
    nat_gateways        = length(aws_nat_gateway.main)
    private_web_rts     = length(aws_route_table.private_web)
    private_db_rts      = length(aws_route_table.private_db)
    status              = "stage1-ha-network"
  }
}
