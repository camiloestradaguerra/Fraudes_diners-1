# ============================================================
# PASO 1: ECR REPOSITORY - Search & Create if not exists
# ============================================================
# Este archivo verifica si existe un repositorio ECR 
# con el nombre especificado en var.docker_image_name.
# Si no existe, lo crea. Si existe, no hace nada.
# ============================================================

# ============================================================
# ECR Repository: Crear o usar existente
# ============================================================
# Cuando se ejecuta terraform apply por primera vez, intenta crear el recurso.
# Si ya existe, Terraform lo detectará en el estado y no lo recreará (idempotente).

resource "aws_ecr_repository" "fraud_detection" {
  name                 = var.docker_image_name
  image_tag_mutability = var.ecr_image_tag_mutability
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  encryption_configuration {
    encryption_type = var.ecr_encryption_type
  }

  tags = local.common_tags

  # lifecycle {
  #   prevent_destroy = true
  # }
}

# ============================================================
# Local: Referencia al repositorio
# ============================================================

locals {
  ecr_repository_arn = aws_ecr_repository.fraud_detection.arn
  ecr_repository_name = aws_ecr_repository.fraud_detection.name
}

# ============================================================
# Null Resource: Limpiar imágenes del ECR antes de destruir
# ============================================================

resource "null_resource" "ecr_cleanup" {
  triggers = {
    repository_name = aws_ecr_repository.fraud_detection.name
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "powershell.exe -Command \"aws ecr delete-repository --repository-name fraud-detection-api --force --region us-east-1 2>$null; exit 0\""
    on_failure = continue
  }

  depends_on = [aws_ecr_repository.fraud_detection]
}
