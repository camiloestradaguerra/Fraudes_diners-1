# ============================================================
# PASO 0: Configuration - Estado del ECR
# ============================================================
# Verificar AUTOMÁTICAMENTE si existe imagen en ECR
# Decisión: ¿Necesitamos ejecutar CodeBuild?
# ============================================================

# Verificar si imagen existe en ECR
resource "null_resource" "check_ecr_image" {
  provisioner "local-exec" {
    command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"aws ecr describe-images --repository-name '${var.docker_image_name}' --region ${var.aws_region} --query 'imageDetails[?contains(imageTags, `latest`)] | length(@)' --output text > image_check.txt 2>&1 || echo '0' | Out-File -FilePath image_check.txt -Encoding utf8\""
    on_failure = continue
  }
}

locals {
  # ============================================================
  # Verificación automática (sin variables manuales)
  # ============================================================
  
  # Leer resultado de verificación de imagen
  image_count_raw = try(file("${path.module}/image_check.txt"), "0")
  image_count     = tonumber(trimspace(local.image_count_raw))
  
  # ¿Existe imagen con tag 'latest' en ECR?
  ecr_image_exists = local.image_count > 0

  # ============================================================
  # Decisiones automáticas
  # ============================================================
  
  # Si NO existe imagen, ejecutar CodeBuild para crearla y pushearla
  should_run_codebuild = !local.ecr_image_exists
}

# ============================================================
# Output: Estado actual
# ============================================================

output "deployment_status" {
  description = "Estado actual del deployment"
  value = {
    ecr_image_exists     = local.ecr_image_exists
    should_run_codebuild = local.should_run_codebuild
  }
}
