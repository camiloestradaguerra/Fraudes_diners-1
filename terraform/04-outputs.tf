# PASO 4: SageMaker Outputs

output "sagemaker_role_arn" {
  description = "SageMaker execution role ARN"
  value       = try(aws_iam_role.sagemaker_role[0].arn, "")
}

output "sagemaker_role_name" {
  description = "SageMaker execution role name"
  value       = try(aws_iam_role.sagemaker_role[0].name, "")
}

output "sagemaker_model_arn" {
  description = "SageMaker model ARN"
  value       = try(aws_sagemaker_model.fraudes[0].arn, "")
}

output "sagemaker_model_name" {
  description = "SageMaker model name"
  value       = try(aws_sagemaker_model.fraudes[0].name, "")
}

output "sagemaker_artifacts_bucket" {
  description = "S3 bucket for SageMaker artifacts"
  value       = try(aws_s3_bucket.sagemaker_artifacts[0].id, "")
}

output "sagemaker_log_group" {
  description = "CloudWatch log group for SageMaker"
  value       = try(aws_cloudwatch_log_group.sagemaker[0].name, "")
}
