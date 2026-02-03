# ============================================================
# ECR Repository
# ============================================================

resource "aws_ecr_repository" "fraud_detection" {
  name                 = var.docker_image_name
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "fraud_detection" {
  repository = aws_ecr_repository.fraud_detection.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantener últimas 5 imágenes"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ============================================================
# Data Source: Get AWS Account ID
# ============================================================

data "aws_caller_identity" "current" {}

# ============================================================
# Docker Build & Push
# ============================================================

resource "null_resource" "docker_build" {
  count = var.docker_local_build ? 1 : 0

  triggers = {
    dockerfile_hash = filemd5("${var.docker_build_context}/Dockerfile")
    requirements_hash = try(
      filemd5("${var.docker_build_context}/endpoint_prototipo/requirements.txt"),
      "none"
    )
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "[BUILD] Construyendo imagen Docker: ${var.docker_image_name}:${var.docker_image_tag}"
      docker build \
        -t ${var.docker_image_name}:${var.docker_image_tag} \
        -f ${var.docker_build_context}/Dockerfile \
        ${var.docker_build_context}
      echo "[OK] Imagen construida exitosamente"
    EOT
  }
}

resource "null_resource" "docker_push" {
  count = var.enable_docker_push ? 1 : 0

  depends_on = [
    aws_ecr_repository.fraud_detection,
    null_resource.docker_build
  ]

  triggers = {
    docker_image_uri = local.docker_image_uri
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "[AUTH] Obteniendo credenciales ECR..."
      aws ecr get-login-password --region ${var.aws_region} | \
        docker login --username AWS --password-stdin ${local.ecr_repository_url}
      
      echo "[TAG] Tagging imagen Docker..."
      docker tag ${var.docker_image_name}:${var.docker_image_tag} ${local.docker_image_uri}
      
      echo "[PUSH] Pusheando a ECR..."
      docker push ${local.docker_image_uri}
      
      echo "[OK] Imagen en ECR: ${local.docker_image_uri}"
    EOT
  }
}

# ============================================================
# Verify ECR Image
# ============================================================

data "aws_ecr_image" "fraud_detection" {
  depends_on = [null_resource.docker_push]

  repository_name = aws_ecr_repository.fraud_detection.name
  image_tag       = var.docker_image_tag
}
