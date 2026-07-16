# ===================================================
# EKS IAM (클러스터 / 노드 / IRSA for AWS LB Controller)
# enable_eks = true 일 때만 생성
# ===================================================

data "aws_iam_policy_document" "eks_cluster_assume" {
  count = local.eks_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  count              = local.eks_enabled ? 1 : 0
  name               = "${local.name_prefix}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume[0].json

  tags = {
    Name = "${local.name_prefix}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = local.eks_enabled ? 1 : 0
  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  count      = local.eks_enabled ? 1 : 0
  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ----- Node role -----

data "aws_iam_policy_document" "eks_node_assume" {
  count = local.eks_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node" {
  count              = local.eks_enabled ? 1 : 0
  name               = "${local.name_prefix}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume[0].json

  tags = {
    Name = "${local.name_prefix}-eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  count      = local.eks_enabled ? 1 : 0
  role       = aws_iam_role.eks_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  count      = local.eks_enabled ? 1 : 0
  role       = aws_iam_role.eks_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  count      = local.eks_enabled ? 1 : 0
  role       = aws_iam_role.eks_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ----- OIDC (IRSA) -----

data "tls_certificate" "eks" {
  count = local.eks_enabled ? 1 : 0
  url   = aws_eks_cluster.main[0].identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = local.eks_enabled ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main[0].identity[0].oidc[0].issuer

  tags = {
    Name = "${local.name_prefix}-eks-oidc"
  }
}

# ----- AWS Load Balancer Controller IRSA -----

data "aws_iam_policy_document" "aws_lb_controller_assume" {
  count = local.eks_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aws_lb_controller" {
  count              = local.eks_enabled ? 1 : 0
  name               = "${local.name_prefix}-aws-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_lb_controller_assume[0].json

  tags = {
    Name = "${local.name_prefix}-aws-lb-controller"
  }
}

resource "aws_iam_policy" "aws_lb_controller" {
  count       = local.eks_enabled ? 1 : 0
  name        = "${local.name_prefix}-AWSLoadBalancerControllerIAMPolicy"
  description = "AWS Load Balancer Controller IAM policy (portfolio minimal-expanded set)"
  policy      = file("${path.module}/policies/aws-load-balancer-controller-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_lb_controller" {
  count      = local.eks_enabled ? 1 : 0
  role       = aws_iam_role.aws_lb_controller[0].name
  policy_arn = aws_iam_policy.aws_lb_controller[0].arn
}
