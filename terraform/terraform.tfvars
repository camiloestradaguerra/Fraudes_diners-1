# terraform.tfvars - Valores específicos para tu environment
#
# Este archivo contiene valores que quieres usar para Terraform
# IMPORTANTE: No comitees este archivo si contiene secretos
#             Mejor usa: git update-index --skip-worktree terraform.tfvars
#
# Uso: terraform apply (usa automáticamente este archivo)

aws_region  = "us-east-1"
environment = "prod"

# ============================================================================
# Configuración de ECS
# ============================================================================

# CPU: 256, 512, 1024, 2048, 4096 (en unidades Fargate)
ecs_task_cpu = 1024

# Memoria en MB
ecs_task_memory = 2048

# Cuántas instancias ejecutar inicialmente (importante: costo)
ecs_desired_count = 2

# Auto-scaling: mínimo y máximo
ecs_min_capacity = 1
ecs_max_capacity = 5

# ============================================================================
# Logging
# ============================================================================

# Retención de logs en CloudWatch (días)
# Valores válidos: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
log_retention_days = 30

# ============================================================================
# CORS (Cross-Origin Resource Sharing)
# ============================================================================

# Orígenes permitidos para llamadas desde navegador
# "*" = permite todos (desarrollo)
# Específico = solo de ciertos dominios (producción más segura)
cors_allowed_origins = ["*"]

# Para producción más segura:
# cors_allowed_origins = [
#   "https://app.diners.com",
#   "https://admin.diners.com",
#   "https://dashboard.diners.com"
# ]

# ============================================================================
# API Gateway Throttling
# ============================================================================

# Rate limiting: máximo requests por segundo
api_throttling_rate_limit = 1000

# Burst limit: picos temporales permitidos
api_throttling_burst_limit = 2000

# ============================================================================
# Docker
# ============================================================================

# Tag de la imagen a usar (normalmente "latest")
docker_image_tag = "latest"

# ============================================================================
# Monitoreo
# ============================================================================

enable_monitoring = true

# ============================================================================
# NOTAS IMPORTANTES:
# ============================================================================
#
# 1. COSTOS:
#    - Fargate: ~$0.04/vCPU-hour + $0.004/GB-hour
#    - 2 tareas x 1vCPU x 2GB = ~$60/mes
#    - Aumenta ecs_max_capacity aumenta costo
#
# 2. IMAGEN DOCKER:
#    - Primero debes pushear la imagen a ECR:
#      docker push <ecr-url>/fraud-api:latest
#    - Terraform luego la descargará de ECR
#
# 3. AUTO-SCALING:
#    - Escalará automáticamente cuando CPU > 70%
#    - Reducirá cuando CPU < 70% por 5 minutos
#
# 4. LOGS:
#    - Ver en AWS Console: CloudWatch → Log Groups → /ecs/fraud-api
#    - O por CLI: aws logs tail /ecs/fraud-api --follow
#
# 5. IP PÚBLICA:
#    - ECS tasks tienen IP pública asignada
#    - Accesible desde internet a través de API Gateway/ALB
#    - NO expongas puerto 8000 directamente
#
