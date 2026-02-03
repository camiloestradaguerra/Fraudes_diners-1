variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "fraudes"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "prod"
}

variable "docker_image_name" {
  description = "Nombre de la imagen Docker"
  type        = string
  default     = "fraud-detection-api"
}

variable "docker_image_tag" {
  description = "Tag de la imagen Docker"
  type        = string
  default     = "latest"
}

variable "docker_build_context" {
  description = "Path al contexto de Docker build"
  type        = string
  default     = ".."
}

variable "github_repository_url" {
  description = "URL del repositorio GitHub"
  type        = string
  default     = "https://github.com/camiloestradaguerra/Fraudes_diners-1"
}

variable "github_branch" {
  description = "Rama del repositorio GitHub a usar"
  type        = string
  default     = "sagemaker_exp"
}

variable "github_oauth_token" {
  description = "Token de OAuth de GitHub para acceso al repositorio"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_codebuild" {
  description = "Habilitar CodeBuild en lugar de local-exec"
  type        = bool
  default     = true
}

variable "docker_local_build" {
  description = "Construir Docker localmente (false cuando se usa CodeBuild)"
  type        = bool
  default     = false
}

variable "enable_docker_push" {
  description = "Hacer push de la imagen Docker a ECR"
  type        = bool
  default     = false
}

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "ECR scan on push"
  type        = bool
  default     = true
}

variable "sagemaker_instance_type" {
  description = "SageMaker endpoint instance type"
  type        = string
  default     = "ml.m5.large"
}

variable "sagemaker_initial_instance_count" {
  description = "Número inicial de instancias"
  type        = number
  default     = 1
}

variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default = {
    Terraform   = "true"
    CostCenter  = "MLOps"
  }
}

variable "codebuild_compute_type" {
  description = "Tipo de instancia para CodeBuild"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "endpoint_name_suffix" {
  description = "Sufijo para el nombre del endpoint SageMaker (ej: Diners)"
  type        = string
  default     = "Diners"
}

variable "api_gateway_name_suffix" {
  description = "Sufijo para el nombre de API Gateway"
  type        = string
  default     = "API"
}