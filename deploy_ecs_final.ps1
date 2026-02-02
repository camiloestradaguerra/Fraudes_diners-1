#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

$AWS_ACCOUNT_ID = "822626720556"
$AWS_REGION = "us-east-1"
$ECS_CLUSTER = "fraudes-diners-cluster"
$ECS_SERVICE = "fraudes-diners-service"
$ECS_TASK_FAMILY = "fraudes-diners-task"
$ECR_REPO = "fraudes-diners"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Desplegando a ECS/Fargate" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Asumir rol
Write-Host "1️⃣  Asumiendo rol IAM..." -ForegroundColor Yellow
$assume = aws sts assume-role --role-arn "arn:aws:iam::$AWS_ACCOUNT_ID:role/ElasticBeanstalkRole" --role-session-name "ecs-deploy-$(Get-Random)" --external-id "fraudes-diners-eb" --region $AWS_REGION 2>&1 | ConvertFrom-Json
$env:AWS_ACCESS_KEY_ID = $assume.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $assume.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $assume.Credentials.SessionToken
$env:AWS_DEFAULT_REGION = $AWS_REGION
Write-Host "✅ Credenciales configuradas`n" -ForegroundColor Green

# Crear cluster
Write-Host "2️⃣  Creando cluster ECS..." -ForegroundColor Yellow
aws ecs create-cluster --cluster-name $ECS_CLUSTER --region $AWS_REGION 2>&1 | Out-Null
Write-Host "✅ Cluster listo`n" -ForegroundColor Green

# Obtener VPC y subnets
Write-Host "3️⃣  Obteniendo VPC y subnets..." -ForegroundColor Yellow
$vpcs = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region $AWS_REGION | ConvertFrom-Json
$vpc_id = $vpcs.Vpcs[0].VpcId
Write-Host "VPC: $vpc_id" -ForegroundColor Cyan

$subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --region $AWS_REGION | ConvertFrom-Json
$subnet_ids = @($subnets.Subnets[0].SubnetId, $subnets.Subnets[1].SubnetId)
Write-Host "Subnets: $($subnet_ids -join ', ')" -ForegroundColor Cyan

# Crear security group
Write-Host "`n4️⃣  Creando security group..." -ForegroundColor Yellow
$sg_name = "fraudes-diners-sg"
$sgs = aws ec2 describe-security-groups --filters "Name=group-name,Values=$sg_name" "Name=vpc-id,Values=$vpc_id" --region $AWS_REGION 2>&1 | ConvertFrom-Json
if ($sgs.SecurityGroups.Count -eq 0) {
    $sg = aws ec2 create-security-group --group-name $sg_name --description "Security group for Fraudes Diners API" --vpc-id $vpc_id --region $AWS_REGION | ConvertFrom-Json
    $sg_id = $sg.GroupId
    Write-Host "Creado: $sg_id" -ForegroundColor Cyan
    
    # Permitir puerto 8000
    aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 8000 --cidr 0.0.0.0/0 --region $AWS_REGION 2>&1 | Out-Null
} else {
    $sg_id = $sgs.SecurityGroups[0].GroupId
    Write-Host "Existente: $sg_id" -ForegroundColor Cyan
}
Write-Host "✅ Security group listo`n" -ForegroundColor Green

# Imagen ECR
$IMAGE_URI = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO`:latest"
Write-Host "5️⃣  Registrando task definition..." -ForegroundColor Yellow
Write-Host "Image: $IMAGE_URI`n" -ForegroundColor Cyan

# Crear JSON para task definition
$task_def = @{
    family = $ECS_TASK_FAMILY
    networkMode = "awsvpc"
    requiresCompatibilities = @("FARGATE")
    cpu = "256"
    memory = "512"
    containerDefinitions = @(
        @{
            name = "fraudes-diners-container"
            image = $IMAGE_URI
            portMappings = @(
                @{
                    containerPort = 8000
                    hostPort = 8000
                    protocol = "tcp"
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
            environment = @(
                @{
                    name = "PYTHONUNBUFFERED"
                    value = "1"
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

# Guardar a archivo
$task_def | Out-File -FilePath "task_definition.json" -Encoding UTF8
Write-Host "Task definition guardado en task_definition.json" -ForegroundColor Cyan

# Crear log group
Write-Host "`nCreando CloudWatch log group..." -ForegroundColor Cyan
aws logs create-log-group --log-group-name "/ecs/fraudes-diners" --region $AWS_REGION 2>&1 | Out-Null
Write-Host "✅ Log group listo`n" -ForegroundColor Green

# Registrar task definition
Write-Host "6️⃣  Registrando en ECS..." -ForegroundColor Yellow
$task_response = aws ecs register-task-definition --cli-input-json file://task_definition.json --region $AWS_REGION | ConvertFrom-Json
$task_arn = $task_response.taskDefinition.taskDefinitionArn
Write-Host "Task Definition: $task_arn" -ForegroundColor Green
Write-Host "✅ Task definition registrada`n" -ForegroundColor Green

# Crear servicio
Write-Host "7️⃣  Creando ECS service..." -ForegroundColor Yellow
$service_exists = aws ecs list-services --cluster $ECS_CLUSTER --region $AWS_REGION | ConvertFrom-Json
$service_found = $service_exists.serviceArns | Where-Object { $_ -like "*$ECS_SERVICE*" }

if ($null -eq $service_found) {
    Write-Host "Creando nuevo servicio..." -ForegroundColor Cyan
    aws ecs create-service `
        --cluster $ECS_CLUSTER `
        --service-name $ECS_SERVICE `
        --task-definition $ECS_TASK_FAMILY `
        --desired-count 1 `
        --launch-type FARGATE `
        --network-configuration "awsvpcConfiguration={subnets=[$($subnet_ids -join ',')],securityGroups=[$sg_id],assignPublicIp=ENABLED}" `
        --region $AWS_REGION 2>&1 | Out-Null
} else {
    Write-Host "Actualizando servicio existente..." -ForegroundColor Cyan
    aws ecs update-service `
        --cluster $ECS_CLUSTER `
        --service $ECS_SERVICE `
        --task-definition $ECS_TASK_FAMILY `
        --region $AWS_REGION 2>&1 | Out-Null
}
Write-Host "✅ Servicio ECS listo`n" -ForegroundColor Green

# Esperar a que se estabilice
Write-Host "8️⃣  Esperando a que las tareas se estabilicen..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Obtener información del servicio
$service = aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --region $AWS_REGION | ConvertFrom-Json
$task_count = $service.services[0].runningCount
Write-Host "Tareas en ejecución: $task_count" -ForegroundColor Green

# Obtener IP pública
Write-Host "`n9️⃣  Obteniendo dirección IP pública..." -ForegroundColor Yellow
$tasks = aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $ECS_SERVICE --region $AWS_REGION | ConvertFrom-Json
if ($tasks.taskArns.Count -gt 0) {
    $task_details = aws ecs describe-tasks --cluster $ECS_CLUSTER --tasks $tasks.taskArns[0] --region $AWS_REGION | ConvertFrom-Json
    $eni = $task_details.tasks[0].attachments[0].details | Where-Object { $_.name -eq "networkInterfaceId" }
    $eni_id = $eni.value
    
    $eni_info = aws ec2 describe-network-interfaces --network-interface-ids $eni_id --region $AWS_REGION | ConvertFrom-Json
    $public_ip = $eni_info.NetworkInterfaces[0].Association.PublicIp
    
    if ($null -ne $public_ip) {
        Write-Host "✅ IP Pública: $public_ip" -ForegroundColor Green
    } else {
        Write-Host "⏳ IP pública aún no asignada, esperando..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
        $eni_info = aws ec2 describe-network-interfaces --network-interface-ids $eni_id --region $AWS_REGION | ConvertFrom-Json
        $public_ip = $eni_info.NetworkInterfaces[0].Association.PublicIp
        Write-Host "✅ IP Pública: $public_ip" -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "   ✅ DESPLIEGUE COMPLETADO" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`n🎉 Tu API FastAPI está disponible en:`n" -ForegroundColor Cyan
Write-Host "http://$public_ip`:8000" -ForegroundColor Yellow
Write-Host "http://$public_ip`:8000/docs  (Swagger UI)" -ForegroundColor Yellow
Write-Host "`n" -ForegroundColor Green
