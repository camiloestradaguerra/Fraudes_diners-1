# PASO 6: API Gateway Outputs

output "api_gateway_name" {
  description = "API Gateway name"
  value       = try(aws_api_gateway_rest_api.fraudes[0].name, "")
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = try(aws_api_gateway_rest_api.fraudes[0].id, "")
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = try("https://${aws_api_gateway_rest_api.fraudes[0].id}.execute-api.${var.aws_region}.amazonaws.com/${var.api_gateway_stage}/predict", "")
}

output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL for /predict endpoint"
  value       = try("${aws_api_gateway_stage.fraudes[0].invoke_url}/predict", "")
}

output "api_gateway_stage_name" {
  description = "API Gateway stage name"
  value       = var.api_gateway_stage
}

output "api_gateway_log_group" {
  description = "CloudWatch log group for API Gateway"
  value       = try(aws_cloudwatch_log_group.apigateway[0].name, "")
}

output "apigateway_role_arn" {
  description = "API Gateway IAM role ARN"
  value       = try(aws_iam_role.apigateway_role[0].arn, "")
}

output "apigateway_role_name" {
  description = "API Gateway IAM role name"
  value       = try(aws_iam_role.apigateway_role[0].name, "")
}
