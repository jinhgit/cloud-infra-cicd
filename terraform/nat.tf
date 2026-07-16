# ===================================================
# Elastic IP 할당 (NAT Gateway용, AZ별 1개)
# PRD: AZ당 NAT 1 + EIP 1 (총 2) — HA / 동일 AZ 라우팅
# ===================================================

resource "aws_eip" "nat" {
  count  = local.az_count
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip-natgw-${local.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ===================================================
# NAT Gateway (각 AZ Public 서브넷에 배치)
# Private Web 서브넷 아웃바운드 인터넷 연결
# ===================================================

resource "aws_nat_gateway" "main" {
  count         = local.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.name_prefix}-natgw-${local.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main, aws_subnet.public]
}
