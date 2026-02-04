# ============================================================
# PASO 3: Outputs - CodeBuild
# ============================================================

output "codebuild_project_name" {
  description = "Nombre del proyecto CodeBuild"
  value       = try(aws_codebuild_project.docker_build[0].name, null)
}

output "codebuild_project_arn" {
  description = "ARN del proyecto CodeBuild"
  value       = try(aws_codebuild_project.docker_build[0].arn, null)
}

output "codebuild_log_group" {
  description = "Nombre del CloudWatch Log Group para CodeBuild"
  value       = try(aws_cloudwatch_log_group.codebuild[0].name, null)
}
