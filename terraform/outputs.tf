output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.fraud_detection.repository_url
}

output "ecr_repository_arn" {
  description = "ECR Repository ARN"
  value       = aws_ecr_repository.fraud_detection.arn
}

output "docker_image_uri" {
  description = "Imagen Docker completa en ECR"
  value       = local.docker_image_uri
}

output "sagemaker_model_name" {
  description = "Nombre del modelo SageMaker"
  value       = aws_sagemaker_model.fraud_detection.name
}

output "sagemaker_endpoint_name" {
  description = "Nombre del endpoint SageMaker"
  value       = aws_sagemaker_endpoint.fraud_detection.name
}

output "sagemaker_endpoint_arn" {
  description = "ARN del endpoint SageMaker"
  value       = aws_sagemaker_endpoint.fraud_detection.arn
}

output "api_gateway_rest_api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.fraud_detection.id
}

output "api_gateway_rest_api_name" {
  description = "API Gateway REST API Name"
  value       = aws_api_gateway_rest_api.fraud_detection.name
}

output "api_invoke_url" {
  # Eliminamos la barra manual porque invoke_url ya la trae
  value = "${aws_api_gateway_stage.prod.invoke_url}/${aws_api_gateway_resource.fraude.path_part}"
}

output "iam_role_sagemaker_arn" {
  description = "ARN del rol SageMaker"
  value       = aws_iam_role.sagemaker_execution.arn
}

output "codebuild_project_name" {
  description = "Nombre del proyecto CodeBuild"
  value       = try(aws_codebuild_project.docker_build[0].name, "CodeBuild no habilitado")
}

output "codebuild_project_arn" {
  description = "ARN del proyecto CodeBuild"
  value       = try(aws_codebuild_project.docker_build[0].arn, "CodeBuild no habilitado")
}

output "codebuild_log_group" {
  description = "CloudWatch Log Group para CodeBuild"
  value       = try(aws_cloudwatch_log_group.codebuild[0].name, "CodeBuild no habilitado")
}

output "iam_role_apigateway_arn" {
  description = "ARN del rol API Gateway"
  value       = aws_iam_role.apigateway_sagemaker.arn
}

output "deployment_info" {
  description = "Información de deployment completo"
  value = {
    environment                = var.environment
    region                     = var.aws_region
    account_id                 = var.aws_account_id
    project_name               = var.project_name
    docker_image_uri           = local.docker_image_uri
    sagemaker_endpoint_name    = aws_sagemaker_endpoint.fraud_detection.name
    api_invoke_url             = "${aws_api_gateway_deployment.fraud_detection.invoke_url}${aws_api_gateway_resource.fraude.path_part}"
    instance_type              = var.sagemaker_instance_type
    instance_count             = var.sagemaker_initial_instance_count
  }
  sensitive = false
}
