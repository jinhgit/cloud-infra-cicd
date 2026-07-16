# ===================================================
# Amazon EKS 클러스터 + 관리형 노드 그룹
# PRD §14 권장 A — enable_eks = true 일 때만 생성
# 비용: 컨트롤 플레인 + 노드 EC2 — 사용 후 destroy 필수
# ===================================================

locals {
  eks_public_access_cidrs = length(var.eks_public_access_cidrs) > 0 ? var.eks_public_access_cidrs : [var.my_ip]
}

resource "aws_eks_cluster" "main" {
  count    = local.eks_enabled ? 1 : 0
  name     = local.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = var.eks_cluster_version

  vpc_config {
    # 컨트롤 플레인 ENI: Private Web + Public (다중 AZ)
    subnet_ids              = concat(aws_subnet.private_web[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = var.eks_endpoint_public_access
    public_access_cidrs     = var.eks_endpoint_public_access ? local.eks_public_access_cidrs : null
  }

  enabled_cluster_log_types = ["api", "audit"]

  tags = {
    Name = local.eks_cluster_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
    aws_nat_gateway.main,
  ]
}

resource "aws_eks_node_group" "main" {
  count           = local.eks_enabled ? 1 : 0
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${local.name_prefix}-ng"
  node_role_arn   = aws_iam_role.eks_node[0].arn
  subnet_ids      = aws_subnet.private_web[*].id
  instance_types  = [var.eks_node_instance_type]
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.eks_node_desired_size
    max_size     = var.eks_node_max_size
    min_size     = var.eks_node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "workload"
  }

  tags = {
    Name = "${local.name_prefix}-ng"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_readonly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
