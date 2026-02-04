# ============================================================
# PASO 1: Outputs - ECR Repository
# ============================================================

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.fraud_detection.repository_url
}

output "ecr_repository_arn" {
  description = "ECR Repository ARN"
  value       = aws_ecr_repository.fraud_detection.arn
}
