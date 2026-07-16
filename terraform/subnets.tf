# ===================================================
# Public 서브넷 생성 (ALB, Bastion 호스트용)
# ===================================================

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet-${local.availability_zones[count.index]}"
    Type = "Public"
  }

  depends_on = [aws_vpc.main]
}

# ===================================================
# Private Web 서브넷 생성 (웹 서버/EC2용)
# ===================================================

resource "aws_subnet" "private_web" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_web_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-web-subnet-${local.availability_zones[count.index]}"
    Type = "Private-Web"
  }

  depends_on = [aws_vpc.main]
}

# ===================================================
# Private DB 서브넷 생성 (데이터베이스용)
# ===================================================

resource "aws_subnet" "private_db" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-db-subnet-${local.availability_zones[count.index]}"
    Type = "Private-DB"
  }

  depends_on = [aws_vpc.main]
}
