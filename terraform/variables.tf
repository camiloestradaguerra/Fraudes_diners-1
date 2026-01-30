# Variables para Terraform
# 
# Estos valores se pueden sobrescribir en terraform.tfvars
# o pasando: terraform apply -var="variable_name=value"

variable "aws_region" {
  description = "Región AWS donde desplegar"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region debe ser válida, ej: us-east-1, us-west-2"
  }
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment debe ser: dev, staging o prod"
  }
}

variable "ecs_task_cpu" {
  description = "CPU para cada tarea ECS (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 1024

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.ecs_task_cpu)
    error_message = "CPU debe ser: 256, 512, 1024, 2048 o 4096"
  }
}

variable "ecs_task_memory" {
  description = "Memoria (MB) para cada tarea ECS"
  type        = number
  default     = 2048

  validation {
    condition     = var.ecs_task_memory >= 512 && var.ecs_task_memory <= 30720
    error_message = "Memoria debe estar entre 512 y 30720 MB"
  }
}

variable "ecs_desired_count" {
  description = "Número de contenedores a ejecutar inicialmente"
  type        = number
  default     = 2

  validation {
    condition     = var.ecs_desired_count >= 1 && var.ecs_desired_count <= 10
    error_message = "Desired count debe estar entre 1 y 10"
  }
}

variable "ecs_min_capacity" {
  description = "Mínimo número de contenedores (auto-scaling)"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Máximo número de contenedores (auto-scaling)"
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "Días para retener logs en CloudWatch"
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Retention days debe ser: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827 o 3653"
  }
}

variable "cors_allowed_origins" {
  description = "Orígenes permitidos para CORS (array de strings)"
  type        = list(string)
  default     = ["*"]
}

variable "docker_image_tag" {
  description = "Tag de la imagen Docker a usar"
  type        = string
  default     = "latest"
}

variable "enable_monitoring" {
  description = "Activar CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "api_throttling_rate_limit" {
  description = "Rate limit para API Gateway (requests por segundo)"
  type        = number
  default     = 1000
}

variable "api_throttling_burst_limit" {
  description = "Burst limit para API Gateway"
  type        = number
  default     = 2000
}
