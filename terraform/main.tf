# Terraform Configuration para Fraud Detection API en AWS
# 
# Infraestructura:
# - ECR (Elastic Container Registry) para almacenar Docker images
# - ECS Fargate para ejecutar contenedores
# - Load Balancer para distribuir tráfico
# - API Gateway para punto de entrada
# - CloudWatch para logs y monitoreo
#
# Antes de ejecutar: 
#   1. Configura variables en terraform.tfvars
#   2. Ejecuta: terraform init
#   3. Ejecuta: terraform plan
#   4. Ejecuta: terraform apply

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend: almacena estado en S3 (evita conflictos en equipo)
  # Descomenta si trabajas con otros (necesita S3 bucket)
  # backend "s3" {
  #   bucket         = "fraud-api-terraform-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Fraud Detection API"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = "2026-01-30"
    }
  }
}

# ============================================================================
# VPC (Virtual Private Cloud) - Networking
# ============================================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "fraud-api-vpc"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "fraud-api-public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "fraud-api-public-2"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "fraud-api-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "fraud-api-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# Security Groups
# ============================================================================

resource "aws_security_group" "alb" {
  name        = "fraud-api-alb-sg"
  description = "Security group para Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Permitir HTTP (será redirigido a HTTPS)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida a internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fraud-api-alb-sg"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "fraud-api-ecs-tasks-sg"
  description = "Security group para ECS tasks"
  vpc_id      = aws_vpc.main.id

  # Permitir tráfico desde ALB
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Salida a internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fraud-api-ecs-tasks-sg"
  }
}

# ============================================================================
# ECR (Elastic Container Registry) - Docker Image Storage
# ============================================================================

resource "aws_ecr_repository" "fraud_api" {
  name                 = "fraud-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Política: solo desde CI/CD pipeline
  # encryption_configuration {
  #   encryption_type = "KMS"
  # }

  tags = {
    Name = "fraud-api-ecr"
  }
}

resource "aws_ecr_lifecycle_policy" "fraud_api" {
  repository = aws_ecr_repository.fraud_api.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Mantén últimas 10 imágenes"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ============================================================================
# IAM Roles for ECS
# ============================================================================

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "fraud-api-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Permitir ECS acceder a CloudWatch Logs
resource "aws_iam_role_policy" "ecs_task_logging_policy" {
  name = "fraud-api-ecs-logging-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:${var.aws_region}:*:*"
    }]
  })
}

# ============================================================================
# CloudWatch Logs
# ============================================================================

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/fraud-api"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "fraud-api-logs"
  }
}

# ============================================================================
# Application Load Balancer
# ============================================================================

resource "aws_lb" "main" {
  name               = "fraud-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "fraud-api-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "fraud-api-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
    matcher             = "200-299"
  }

  tags = {
    Name = "fraud-api-tg"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ============================================================================
# ECS Cluster & Service
# ============================================================================

resource "aws_ecs_cluster" "main" {
  name = "fraud-api-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "fraud-api-cluster"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }

  default_capacity_provider_strategy {
    weight            = 0
    capacity_provider = "FARGATE_SPOT"
  }
}

# Task Definition (qué contenedor correr, cuánta memoria, etc.)
resource "aws_ecs_task_definition" "app" {
  family                   = "fraud-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "fraud-api"
    image     = "${aws_ecr_repository.fraud_api.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      {
        name  = "ENVIRONMENT"
        value = var.environment
      },
      {
        name  = "LOG_LEVEL"
        value = "INFO"
      }
    ]
  }])

  tags = {
    Name = "fraud-api-task"
  }
}

# ECS Service (corre N instancias del task)
resource "aws_ecs_service" "app" {
  name            = "fraud-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "fraud-api"
    container_port   = 8000
  }

  depends_on = [
    aws_lb_listener.app,
    aws_iam_role_policy.ecs_task_logging_policy
  ]

  tags = {
    Name = "fraud-api-service"
  }
}

# ============================================================================
# Auto Scaling
# ============================================================================

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.ecs_max_capacity
  min_capacity       = var.ecs_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Escala por CPU
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "fraud-api-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Escala por Memoria
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "fraud-api-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}

# ============================================================================
# API Gateway (entrada pública, punto único de acceso)
# ============================================================================

resource "aws_apigatewayv2_api" "fraud_api" {
  name          = "fraud-detection-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors_allowed_origins
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 300
  }

  tags = {
    Name = "fraud-api-apigw"
  }
}

resource "aws_apigatewayv2_stage" "fraud_api" {
  api_id      = aws_apigatewayv2_api.fraud_api.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/fraud-api"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "fraud-api-apigw-logs"
  }
}

resource "aws_apigatewayv2_integration" "fraud_api" {
  api_id           = aws_apigatewayv2_api.fraud_api.id
  integration_type = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri  = "http://${aws_lb.main.dns_name}"

  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "fraud_api" {
  api_id    = aws_apigatewayv2_api.fraud_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.fraud_api.id}"
}
