locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )

  ecr_repository_url = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  docker_image_uri   = "${local.ecr_repository_url}/${var.docker_image_name}:${var.docker_image_tag}"

  sagemaker_model_name       = "${var.project_name}-model-${var.environment}"
  sagemaker_endpoint_config  = "${var.project_name}-config-${var.environment}"
  
  # Nombre exacto del endpoint para evitar conflictos
  sagemaker_endpoint_name    = "endpoint-fraudes-v5"
  
  api_gateway_name = "${var.project_name}-api-${var.environment}"
  
  iam_role_sagemaker_name     = "sagemaker-execution-${var.project_name}-${var.environment}"
  iam_role_apigateway_name    = "apigateway-sagemaker-${var.project_name}-${var.environment}"

  stack_name = "${var.project_name}-${var.environment}"
}