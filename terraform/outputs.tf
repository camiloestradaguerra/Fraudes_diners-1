# Outputs - valores importantes después de desplegar
# 
# Estos se imprimirán después de: terraform apply
# Accede a ellos con: terraform output <nombre>

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "api_gateway_endpoint" {
  description = "Endpoint de API Gateway (URL pública para clientes)"
  value       = aws_apigatewayv2_stage.fraud_api.invoke_url
  sensitive   = false
}

output "api_gateway_api_id" {
  description = "ID de API Gateway"
  value       = aws_apigatewayv2_api.fraud_api.id
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR (para push de images)"
  value       = aws_ecr_repository.fraud_api.repository_url
}

output "ecr_repository_arn" {
  description = "ARN del repositorio ECR"
  value       = aws_ecr_repository.fraud_api.arn
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.app.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group para ECS"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "cloudwatch_log_group_api_gateway" {
  description = "CloudWatch Log Group para API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "vpc_id" {
  description = "ID de VPC"
  value       = aws_vpc.main.id
}

output "security_group_alb_id" {
  description = "ID del security group del ALB"
  value       = aws_security_group.alb.id
}

output "security_group_ecs_id" {
  description = "ID del security group de ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

# ============================================================================
# Resumen rápido para copiar/pegar
# ============================================================================

output "deployment_summary" {
  description = "Resumen del deployment para referencia rápida"
  value = {
    api_url               = aws_apigatewayv2_stage.fraud_api.invoke_url
    load_balancer_dns     = aws_lb.main.dns_name
    ecr_push_command      = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.fraud_api.repository_url}"
    docker_push_command   = "docker push ${aws_ecr_repository.fraud_api.repository_url}:latest"
    logs_command          = "aws logs tail ${aws_cloudwatch_log_group.ecs.name} --follow"
    ecs_services_command  = "aws ecs describe-services --cluster ${aws_ecs_cluster.main.name} --services ${aws_ecs_service.app.name} --region ${var.aws_region}"
  }
}
