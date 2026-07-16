# ===================================================
# Public 서브넷 (ALB, Bastion, NAT)
# EKS: kubernetes.io/role/elb 태그로 외부 ALB 배치
# ===================================================

resource "aws_subnet" "public" {
  count                   = local.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name                     = "${local.name_prefix}-public-subnet-${local.availability_zones[count.index]}"
      Type                     = "Public"
      "kubernetes.io/role/elb" = "1"
    },
    # 클러스터 이름 태그는 enable_eks 여부와 관계없이 예약 이름으로 부여 (Controller 탐색용)
    {
      (local.eks_cluster_tag_key) = "shared"
    }
  )
}

# ===================================================
# Private Web 서브넷 (EKS 워커 노드 / 웹)
# ===================================================

resource "aws_subnet" "private_web" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_web_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(
    {
      Name                              = "${local.name_prefix}-private-web-subnet-${local.availability_zones[count.index]}"
      Type                              = "Private-Web"
      "kubernetes.io/role/internal-elb" = "1"
    },
    {
      (local.eks_cluster_tag_key) = "shared"
    }
  )
}

# ===================================================
# Private DB 서브넷 (RDS 배치 공간)
# ===================================================

resource "aws_subnet" "private_db" {
  count             = local.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-db-subnet-${local.availability_zones[count.index]}"
    Type = "Private-DB"
  }
}
