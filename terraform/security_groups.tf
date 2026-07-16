# ===================================================
# ALB 보안 그룹
# 외부에서 HTTP/HTTPS 트래픽 허용
# ===================================================

resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-sg-"
  description = "Security group for ALB allowing HTTP/HTTPS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }

  depends_on = [aws_vpc.main]
}

# Ingress: HTTP 트래픽 (80)
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "Allow HTTP"
  }
}

# Ingress: HTTPS 트래픽 (443)
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from anywhere"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "Allow HTTPS"
  }
}

# Egress: 모든 트래픽 허용 (기본)
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "Allow All Outbound"
  }
}

# ===================================================
# Web EC2 보안 그룹
# ALB로부터의 HTTP/HTTPS 트래픽만 허용
# ===================================================

resource "aws_security_group" "web_ec2" {
  name_prefix = "${local.name_prefix}-web-ec2-sg-"
  description = "Security group for Web EC2 allowing traffic from ALB only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-web-ec2-sg"
  }

  depends_on = [aws_vpc.main]
}

# Ingress: ALB로부터 HTTP (80)
resource "aws_vpc_security_group_ingress_rule" "web_ec2_http_from_alb" {
  security_group_id            = aws_security_group.web_ec2.id
  description                  = "Allow HTTP from ALB"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name = "Allow HTTP from ALB"
  }
}

# Ingress: ALB로부터 HTTPS (443)
resource "aws_vpc_security_group_ingress_rule" "web_ec2_https_from_alb" {
  security_group_id            = aws_security_group.web_ec2.id
  description                  = "Allow HTTPS from ALB"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name = "Allow HTTPS from ALB"
  }
}

# Egress: 모든 트래픽 허용 (아웃바운드)
resource "aws_vpc_security_group_egress_rule" "web_ec2_all" {
  security_group_id = aws_security_group.web_ec2.id
  description       = "Allow all outbound traffic"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "Allow All Outbound"
  }
}

# ===================================================
# Bastion Host 보안 그룹
# 개발자의 특정 IP에서만 SSH 접속 허용
# ===================================================

resource "aws_security_group" "bastion" {
  name_prefix = "${local.name_prefix}-bastion-sg-"
  description = "Security group for Bastion Host allowing SSH from specific IP only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-bastion-sg"
  }

  depends_on = [aws_vpc.main]
}

# Ingress: SSH (22) - 개발자 IP만
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "Allow SSH from developer IP"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip

  tags = {
    Name = "Allow SSH from My IP"
  }
}

# Egress: 모든 트래픽 허용 (아웃바운드)
resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  description       = "Allow all outbound traffic"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "Allow All Outbound"
  }
}

# ===================================================
# DB 보안 그룹
# Web EC2 보안 그룹으로부터만 DB 접속 허용
# ===================================================

resource "aws_security_group" "db" {
  name_prefix = "${local.name_prefix}-db-sg-"
  description = "Security group for DB allowing access from Web EC2 only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-db-sg"
  }

  depends_on = [aws_vpc.main]
}

# Ingress: MySQL/MariaDB (3306) - Web EC2로부터
resource "aws_vpc_security_group_ingress_rule" "db_mysql" {
  security_group_id            = aws_security_group.db.id
  description                  = "Allow MySQL from Web EC2"
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web_ec2.id

  tags = {
    Name = "Allow MySQL from Web EC2"
  }
}

# Ingress: PostgreSQL (5432) - Web EC2로부터 (선택)
resource "aws_vpc_security_group_ingress_rule" "db_postgresql" {
  security_group_id            = aws_security_group.db.id
  description                  = "Allow PostgreSQL from Web EC2"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web_ec2.id

  tags = {
    Name = "Allow PostgreSQL from Web EC2"
  }
}

# Egress: 모든 트래픽 허용 (아웃바운드)
resource "aws_vpc_security_group_egress_rule" "db_all" {
  security_group_id = aws_security_group.db.id
  description       = "Allow all outbound traffic"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "Allow All Outbound"
  }
}
