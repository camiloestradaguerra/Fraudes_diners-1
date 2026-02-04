# PASO 5: SageMaker Endpoint Outputs

output "sagemaker_endpoint_name" {
  description = "SageMaker endpoint name"
  value       = try(aws_sagemaker_endpoint.fraudes[0].name, "")
}

output "sagemaker_endpoint_arn" {
  description = "SageMaker endpoint ARN"
  value       = try(aws_sagemaker_endpoint.fraudes[0].arn, "")
}

output "sagemaker_endpoint_config_name" {
  description = "SageMaker endpoint configuration name"
  value       = try(aws_sagemaker_endpoint_configuration.fraudes[0].name, "")
}

output "sagemaker_endpoint_log_group" {
  description = "CloudWatch log group for SageMaker endpoint"
  value       = try(aws_cloudwatch_log_group.sagemaker_endpoint[0].name, "")
}
