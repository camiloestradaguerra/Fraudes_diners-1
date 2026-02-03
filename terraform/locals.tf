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
  
  # Endpoint name dinámico: "Fraudes-Diners-Prod-Endpoint"
  sagemaker_endpoint_name    = "${title(var.project_name)}-${var.endpoint_name_suffix}-${title(var.environment)}-Endpoint"
  
  api_gateway_name = "${var.project_name}-${var.api_gateway_name_suffix}-${var.environment}"
  
  iam_role_sagemaker_name     = "sagemaker-execution-${var.project_name}-${var.environment}"
  iam_role_apigateway_name    = "apigateway-sagemaker-${var.project_name}-${var.environment}"

  stack_name = "${var.project_name}-${var.environment}"
}