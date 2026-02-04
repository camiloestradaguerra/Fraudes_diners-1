# ============================================================
# PASO 2: Outputs - IAM Roles
# ============================================================

output "codebuild_role_arn" {
  description = "ARN del rol de CodeBuild"
  value       = try(aws_iam_role.codebuild_role[0].arn, null)
}

output "codebuild_role_name" {
  description = "Nombre del rol de CodeBuild"
  value       = try(aws_iam_role.codebuild_role[0].name, null)
}
