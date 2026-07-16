# ===================================================
# NAT Gateway + EIP
# 기본: nat_count=0 (무료). 유료 데모 시에만 1~2개
# ===================================================

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip-natgw-${local.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.name_prefix}-natgw-${local.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main, aws_subnet.public]
}
