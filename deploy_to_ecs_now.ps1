#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

$AWS_ACCOUNT_ID = "822626720556"
$AWS_REGION = "us-east-1"
$VPC_ID = "vpc-087f280a479ba58ad"
$SUBNET_1 = "subnet-0df66d1dd8322bc58"
$SUBNET_2 = "subnet-03369fa560374023f"
$ECS_CLUSTER = "fraudes-diners-cluster"
$ECS_SERVICE = "fraudes-diners-service"
$ECS_TASK_FAMILY = "fraudes-diners-task"
$ECR_REPO = "fraudes-diners"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   Desplegando a ECS/Fargate" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. Crear cluster
Write-Host "1️⃣  Creando cluster ECS..." -ForegroundColor Yellow
aws ecs create-cluster --cluster-name $ECS_CLUSTER --region $AWS_REGION 2>&1 | Out-Null
Write-Host "✅ Cluster '$ECS_CLUSTER' listo`n" -ForegroundColor Green

# 2. Crear security group
Write-Host "2️⃣  Creando security group..." -ForegroundColor Yellow
$sg_name = "fraudes-diners-sg"
$sgs_check = aws ec2 describe-security-groups --filters "Name=group-name,Values=$sg_name" --region $AWS_REGION 2>&1
if ($sgs_check -match "AuthFailure") {
    Write-Host "Creando nuevo SG..." -ForegroundColor Cyan
    $sg = aws ec2 create-security-group --group-name $sg_name --description "Security group for Fraudes Diners API" --vpc-id $VPC_ID --region $AWS_REGION | ConvertFrom-Json
    $sg_id = $sg.GroupId
    aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 8000 --cidr 0.0.0.0/0 --region $AWS_REGION 2>&1 | Out-Null
} else {
    $sgs = $sgs_check | ConvertFrom-Json
    $sg_id = $sgs.SecurityGroups[0].GroupId
}
Write-Host "✅ Security Group: $sg_id`n" -ForegroundColor Green

# 3. Crear Log Group
Write-Host "3️⃣  Creando CloudWatch log group..." -ForegroundColor Yellow
aws logs create-log-group --log-group-name "/ecs/fraudes-diners" --region $AWS_REGION 2>&1 | Out-Null
Write-Host "✅ Log group listo`n" -ForegroundColor Green

# 4. Task definition
Write-Host "4️⃣  Registrando task definition..." -ForegroundColor Yellow
$IMAGE_URI = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO`:latest"
Write-Host "   Image: $IMAGE_URI" -ForegroundColor Cyan

$task_json = @"
{
  "family": "$ECS_TASK_FAMILY",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "fraudes-diners-container",
      "image": "$IMAGE_URI",
      "portMappings": [
        {
          "containerPort": 8000,
          "hostPort": 8000,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/fraudes-diners",
          "awslogs-region": "$AWS_REGION",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "environment": [
        {
          "name": "PYTHONUNBUFFERED",
          "value": "1"
        }
      ]
    }
  ]
}
"@

$task_json | Out-File -FilePath "task_def.json" -Encoding UTF8
$task_response = aws ecs register-task-definition --cli-input-json file://task_def.json --region $AWS_REGION | ConvertFrom-Json
Write-Host "✅ Task Definition registrada`n" -ForegroundColor Green

# 5. Crear servicio
Write-Host "5️⃣  Creando ECS service..." -ForegroundColor Yellow
$service_check = aws ecs list-services --cluster $ECS_CLUSTER --region $AWS_REGION 2>&1 | ConvertFrom-Json
$service_exists = $service_check.serviceArns | Where-Object { $_ -like "*$ECS_SERVICE*" } | Measure-Object | Select-Object -ExpandProperty Count

if ($service_exists -eq 0) {
    Write-Host "   Creando nuevo servicio..." -ForegroundColor Cyan
    aws ecs create-service `
        --cluster $ECS_CLUSTER `
        --service-name $ECS_SERVICE `
        --task-definition $ECS_TASK_FAMILY `
        --desired-count 1 `
        --launch-type FARGATE `
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$sg_id],assignPublicIp=ENABLED}" `
        --region $AWS_REGION 2>&1 | Out-Null
} else {
    Write-Host "   Actualizando servicio existente..." -ForegroundColor Cyan
    aws ecs update-service `
        --cluster $ECS_CLUSTER `
        --service $ECS_SERVICE `
        --task-definition $ECS_TASK_FAMILY `
        --region $AWS_REGION 2>&1 | Out-Null
}
Write-Host "✅ ECS Service listo`n" -ForegroundColor Green

# 6. Esperar y obtener IP
Write-Host "6️⃣  Esperando a que las tareas se estabilicen..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

$tasks = aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $ECS_SERVICE --region $AWS_REGION | ConvertFrom-Json
if ($tasks.taskArns.Count -gt 0) {
    $task_details = aws ecs describe-tasks --cluster $ECS_CLUSTER --tasks $tasks.taskArns[0] --region $AWS_REGION | ConvertFrom-Json
    
    if ($task_details.tasks[0].attachments.Count -gt 0) {
        $eni = $task_details.tasks[0].attachments[0].details | Where-Object { $_.name -eq "networkInterfaceId" }
        $eni_id = $eni.value
        
        Write-Host "   Buscando IP pública..." -ForegroundColor Cyan
        $eni_info = aws ec2 describe-network-interfaces --network-interface-ids $eni_id --region $AWS_REGION | ConvertFrom-Json
        $public_ip = $eni_info.NetworkInterfaces[0].Association.PublicIp
        
        if ($null -eq $public_ip) {
            Write-Host "   Esperando asignación de IP..." -ForegroundColor Yellow
            Start-Sleep -Seconds 15
            $eni_info = aws ec2 describe-network-interfaces --network-interface-ids $eni_id --region $AWS_REGION | ConvertFrom-Json
            $public_ip = $eni_info.NetworkInterfaces[0].Association.PublicIp
        }
        
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "   ✅ DESPLIEGUE EXITOSO" -ForegroundColor Green
        Write-Host "========================================`n" -ForegroundColor Green
        Write-Host "🎉 Tu API FastAPI está disponible en:`n" -ForegroundColor Cyan
        Write-Host "📡 URL Principal:`n" -ForegroundColor Yellow
        Write-Host "   http://$public_ip`:8000`n" -ForegroundColor White
        Write-Host "📚 Documentación Swagger:`n" -ForegroundColor Yellow
        Write-Host "   http://$public_ip`:8000/docs`n" -ForegroundColor White
        Write-Host "========================================`n" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  No se encontraron tareas en ejecución" -ForegroundColor Yellow
}
