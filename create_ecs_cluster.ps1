# Script para crear ECS Cluster, Task Definition y Service
# =========================================================

$ErrorActionPreference = "Stop"

# Cargar configuración del deployment anterior
$config = Get-Content "deployment_config.json" | ConvertFrom-Json

$AWS_ACCOUNT_ID = $config.AWS_ACCOUNT_ID
$AWS_REGION = $config.AWS_REGION
$ECR_REPO = $config.ECR_REPO
$FULL_IMAGE_URI = $config.FULL_IMAGE_URI
$ECS_CLUSTER = $config.ECS_CLUSTER
$ECS_SERVICE = $config.ECS_SERVICE
$ECS_TASK_FAMILY = $config.ECS_TASK_FAMILY
$CONTAINER_PORT = $config.CONTAINER_PORT

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configurando ECS Cluster y Service" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Paso 1: Asumir rol IAM nuevamente
Write-Host "`n[1/5] Asumiendo rol IAM..." -ForegroundColor Yellow

$assume = aws sts assume-role `
    --role-arn "arn:aws:iam::$AWS_ACCOUNT_ID:role/ElasticBeanstalkRole" `
    --role-session-name "ecs-cluster-setup" `
    --external-id "fraudes-diners-eb" `
    --region $AWS_REGION | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID = $assume.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $assume.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $assume.Credentials.SessionToken
$env:AWS_DEFAULT_REGION = $AWS_REGION

Write-Host "✓ Credenciales configuradas" -ForegroundColor Green

# Paso 2: Crear cluster ECS
Write-Host "`n[2/5] Creando cluster ECS..." -ForegroundColor Yellow

$CLUSTER_EXISTS = aws ecs describe-clusters `
    --clusters $ECS_CLUSTER `
    --region $AWS_REGION `
    --output text `
    --query 'clusters[0].clusterName' 2>$null

if (-not $CLUSTER_EXISTS) {
    Write-Host "Creando nuevo cluster..." -ForegroundColor Gray
    aws ecs create-cluster --cluster-name $ECS_CLUSTER --region $AWS_REGION | Out-Null
    Write-Host "✓ Cluster creado: $ECS_CLUSTER" -ForegroundColor Green
} else {
    Write-Host "✓ Cluster existente: $ECS_CLUSTER" -ForegroundColor Green
}

# Paso 3: Crear Task Definition
Write-Host "`n[3/5] Creando Task Definition..." -ForegroundColor Yellow

$TASK_DEF = @{
    family = $ECS_TASK_FAMILY
    networkMode = "awsvpc"
    requiresCompatibilities = @("FARGATE")
    cpu = "256"
    memory = "512"
    containerDefinitions = @(
        @{
            name = "fraudes-diners-container"
            image = $FULL_IMAGE_URI
            portMappings = @(
                @{
                    containerPort = $CONTAINER_PORT
                    hostPort = $CONTAINER_PORT
                    protocol = "tcp"
                }
            )
            environment = @(
                @{
                    name = "PYTHONUNBUFFERED"
                    value = "1"
                }
            )
            logConfiguration = @{
                logDriver = "awslogs"
                options = @{
                    "awslogs-group" = "/ecs/fraudes-diners"
                    "awslogs-region" = $AWS_REGION
                    "awslogs-stream-prefix" = "ecs"
                }
            }
            healthCheck = @{
                command = @("CMD-SHELL", "curl -f http://localhost:8000/health || exit 1")
                interval = 30
                timeout = 5
                retries = 3
                startPeriod = 60
            }
        }
    )
    executionRoleArn = "arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole"
} | ConvertTo-Json -Depth 10

$TASK_DEF | Out-File -FilePath "task_definition.json" -Force -Encoding UTF8

Write-Host "Registrando Task Definition..." -ForegroundColor Gray

aws ecs register-task-definition `
    --cli-input-json file://task_definition.json `
    --region $AWS_REGION | Out-Null

Write-Host "✓ Task Definition creada: $ECS_TASK_FAMILY" -ForegroundColor Green

# Paso 4: Obtener VPC y Subnets
Write-Host "`n[4/5] Obtiendo configuración de VPC..." -ForegroundColor Yellow

# Obtener default VPC
$DEFAULT_VPC = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=true" `
    --region $AWS_REGION `
    --output text `
    --query 'Vpcs[0].VpcId'

if (-not $DEFAULT_VPC) {
    Write-Host "⚠ No se encontró VPC por defecto. Creando..." -ForegroundColor Yellow
    aws ec2 create-default-vpc --region $AWS_REGION | Out-Null
    $DEFAULT_VPC = aws ec2 describe-vpcs `
        --filters "Name=isDefault,Values=true" `
        --region $AWS_REGION `
        --output text `
        --query 'Vpcs[0].VpcId'
}

# Obtener subnets
$SUBNETS = aws ec2 describe-subnets `
    --filters "Name=vpc-id,Values=$DEFAULT_VPC" `
    --region $AWS_REGION `
    --output text `
    --query 'Subnets[*].SubnetId' | ConvertFrom-String

# Obtener security group
$SECURITY_GROUP = aws ec2 describe-security-groups `
    --filters "Name=vpc-id,Values=$DEFAULT_VPC" "Name=group-name,Values=default" `
    --region $AWS_REGION `
    --output text `
    --query 'SecurityGroups[0].GroupId'

Write-Host "✓ VPC: $DEFAULT_VPC" -ForegroundColor Green
Write-Host "✓ Subnets: $($SUBNETS -join ', ')" -ForegroundColor Green
Write-Host "✓ Security Group: $SECURITY_GROUP" -ForegroundColor Green

# Paso 5: Crear Service ECS
Write-Host "`n[5/5] Creando ECS Service..." -ForegroundColor Yellow

# Convertir subnets array a formato requerido
$SUBNET_LIST = $SUBNETS | ForEach-Object { $_ } | Select-Object -First 2

aws ecs create-service `
    --cluster $ECS_CLUSTER `
    --service-name $ECS_SERVICE `
    --task-definition $ECS_TASK_FAMILY `
    --desired-count 1 `
    --launch-type FARGATE `
    --network-configuration "awsvpcConfiguration={subnets=[$($SUBNET_LIST -join ',')],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" `
    --region $AWS_REGION | Out-Null

Write-Host "✓ Service ECS creado: $ECS_SERVICE" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✓ Configuración completada!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nProximos pasos:" -ForegroundColor Cyan
Write-Host "1. Verificar estado del service:" -ForegroundColor White
Write-Host "   aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --region $AWS_REGION" -ForegroundColor Gray
Write-Host "`n2. Ver tareas en ejecución:" -ForegroundColor White
Write-Host "   aws ecs list-tasks --cluster $ECS_CLUSTER --region $AWS_REGION" -ForegroundColor Gray
Write-Host "`n3. Ver logs:" -ForegroundColor White
Write-Host "   aws logs tail /ecs/fraudes-diners --follow --region $AWS_REGION" -ForegroundColor Gray

# Guardar información
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Información de Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cluster: $ECS_CLUSTER" -ForegroundColor White
Write-Host "Service: $ECS_SERVICE" -ForegroundColor White
Write-Host "Task Family: $ECS_TASK_FAMILY" -ForegroundColor White
Write-Host "Image: $FULL_IMAGE_URI" -ForegroundColor White
Write-Host "Region: $AWS_REGION" -ForegroundColor White
