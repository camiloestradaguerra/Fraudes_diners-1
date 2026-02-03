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

variable "enable_docker_push" {
  description = "Ejecutar push a ECR automáticamente"
  type        = bool
  default     = true
}

variable "docker_local_build" {
  description = "Build Docker localmente"
  type        = bool
  default     = true
}