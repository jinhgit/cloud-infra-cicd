# ===================================================
# Public 라우팅 테이블 (1개)
# Internet Gateway를 통한 인터넷 접속 허용
# ===================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rt-public"
    Type = "Public"
  }

  depends_on = [aws_vpc.main]
}

# Public 라우트: 0.0.0.0/0 → IGW
resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id

  depends_on = [aws_route_table.public, aws_internet_gateway.main]
}

# Public 서브넷 → Public RT 연결
resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id

  depends_on = [aws_route_table.public, aws_subnet.public]
}

# ===================================================
# Private Web 라우팅 테이블 (AZ별 분리)
# 0.0.0.0/0 → 동일 AZ NAT Gateway
# ===================================================

resource "aws_route_table" "private_web" {
  count  = local.az_count
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rt-private-web-${local.availability_zones[count.index]}"
    Type = "Private-Web"
  }

  depends_on = [aws_vpc.main]
}

# Private Web 라우트: 0.0.0.0/0 → 동일 AZ NAT
resource "aws_route" "private_web_nat" {
  count                  = local.az_count
  route_table_id         = aws_route_table.private_web[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id

  depends_on = [
    aws_route_table.private_web,
    aws_nat_gateway.main,
  ]
}

# Private Web 서브넷 → 동일 AZ RT 연결
resource "aws_route_table_association" "private_web" {
  count          = local.az_count
  subnet_id      = aws_subnet.private_web[count.index].id
  route_table_id = aws_route_table.private_web[count.index].id

  depends_on = [aws_route_table.private_web, aws_subnet.private_web]
}

# ===================================================
# Private DB 라우팅 테이블 (AZ별 분리)
# 인터넷 기본 경로 없음 (VPC 내부 통신만)
# ===================================================

resource "aws_route_table" "private_db" {
  count  = local.az_count
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rt-private-db-${local.availability_zones[count.index]}"
    Type = "Private-DB"
  }

  depends_on = [aws_vpc.main]
}

# Private DB 서브넷 → 동일 AZ RT 연결
resource "aws_route_table_association" "private_db" {
  count          = local.az_count
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db[count.index].id

  depends_on = [aws_route_table.private_db, aws_subnet.private_db]
}
