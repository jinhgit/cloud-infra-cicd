# ===================================================
# Amazon ECR (FE / BE 이미지) — 유료 동의 + 플래그 필요
# ===================================================

resource "aws_ecr_repository" "fe" {
  count                = local.ecr_enabled ? 1 : 0
  name                 = "${local.name_prefix}-fe"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.name_prefix}-fe"
    App  = "frontend"
  }
}

resource "aws_ecr_repository" "be" {
  count                = local.ecr_enabled ? 1 : 0
  name                 = "${local.name_prefix}-be"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.name_prefix}-be"
    App  = "backend"
  }
}

resource "aws_ecr_lifecycle_policy" "fe" {
  count      = local.ecr_enabled ? 1 : 0
  repository = aws_ecr_repository.fe[0].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "be" {
  count      = local.ecr_enabled ? 1 : 0
  repository = aws_ecr_repository.be[0].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
