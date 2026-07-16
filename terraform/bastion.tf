# ===================================================
# Bastion Host (Stage 2)
# Public 서브넷 + 기존 bastion SG (my_ip → SSH 22)
# SSM Session Manager 지원 (키 없이도 접속 가능)
# enable_bastion = true 일 때만 생성 (비용 통제)
# ===================================================

data "aws_ami" "bastion" {
  count       = local.bastion_enabled ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ----- IAM: SSM Session Manager -----

data "aws_iam_policy_document" "bastion_assume" {
  count = local.bastion_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  count              = local.bastion_enabled ? 1 : 0
  name               = "${local.name_prefix}-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume[0].json

  tags = {
    Name = "${local.name_prefix}-bastion-role"
  }
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count      = local.bastion_enabled ? 1 : 0
  role       = aws_iam_role.bastion[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  count = local.bastion_enabled ? 1 : 0
  name  = "${local.name_prefix}-bastion-profile"
  role  = aws_iam_role.bastion[0].name

  tags = {
    Name = "${local.name_prefix}-bastion-profile"
  }
}

# ----- EC2 Bastion -----

resource "aws_instance" "bastion" {
  count = local.bastion_enabled ? 1 : 0

  ami                         = data.aws_ami.bastion[0].id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion[0].name
  associate_public_ip_address = true

  # 리전에 이미 있는 Key Pair 이름 (SSH 사용 시). 비우면 SSM 전용.
  key_name = var.bastion_key_name != "" ? var.bastion_key_name : null

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.bastion_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    dnf -y update || true
    hostnamectl set-hostname ${local.name_prefix}-bastion
    # SSM Agent 는 AL2023 기본 포함. 네트워크(NAT 불필요·Public) 후 자동 등록.
  EOF

  tags = {
    Name = "${local.name_prefix}-bastion"
    Role = "bastion"
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_iam_role_policy_attachment.bastion_ssm,
  ]

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# 향후 Private Web EC2 점프용 (EKS 노드 SG 와는 별개 — Stage 2 레거시/점프 경로)
resource "aws_vpc_security_group_ingress_rule" "web_ssh_from_bastion" {
  count = local.bastion_enabled ? 1 : 0

  security_group_id            = aws_security_group.web_ec2.id
  description                  = "Allow SSH from Bastion"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id

  tags = {
    Name = "SSH from Bastion"
  }
}
