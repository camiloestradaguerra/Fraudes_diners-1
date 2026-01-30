# MANUAL DEPLOYMENT GUIDE
# Despliegue paso a paso sin GitHub Actions

Este archivo explica cómo desplegar manualmente a AWS sin CI/CD.

## 📋 Tabla de Contenidos

1. [Requisitos](#requisitos)
2. [Paso 1: Preparar Imagen Docker](#paso-1-preparar-imagen-docker)
3. [Paso 2: Crear Infraestructura con Terraform](#paso-2-crear-infraestructura-con-terraform)
4. [Paso 3: Verificar Deployment](#paso-3-verificar-deployment)
5. [Paso 4: Troubleshooting](#paso-4-troubleshooting)
6. [Paso 5: Cleanup (Destruir recursos)](#paso-5-cleanup-destruir-recursos)

---

## 📦 Requisitos

```bash
# 1. Verificar AWS CLI
aws --version
# Debe mostrar: aws-cli/2.x.x

# 2. Verificar AWS Configuration
aws sts get-caller-identity
# Debe mostrar tu Account ID, User ARN, etc.

# 3. Verificar Docker
docker --version

# 4. Verificar Terraform
terraform --version
# Debe ser >= 1.0

# 5. Verificar Git
git --version
```

Si alguno falta:
```bash
# Ejecuta (macOS):
brew install aws-cli docker terraform

# Ejecuta (Windows - PowerShell como Admin):
choco install awscli docker-desktop terraform
```

---

## Paso 1: Preparar Imagen Docker

### 1.1: Build local (test)

```bash
# Desde raíz del proyecto
docker build -t fraud-api:local .

# Test
docker run -p 8000:8000 fraud-api:local

# En otra terminal:
curl http://localhost:8000/health

# Presiona Ctrl+C para detener
```

### 1.2: Push a Amazon ECR

```bash
# A. Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
echo "Account: $AWS_ACCOUNT_ID"

# B. Build tag correcto
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/fraud-api:latest .

# C. Login a ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# D. Push a ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/fraud-api:latest

# Espera 2-3 minutos mientras Trivy (security scan) corre
```

✅ **Resultado:** Tu imagen está en ECR, lista para que ECS la descargue

---

## Paso 2: Crear Infraestructura con Terraform

### 2.1: Inicializar Terraform

```bash
cd terraform

# Descargar providers y módulos
terraform init

# Resultado: Carpeta .terraform/ creada
```

### 2.2: Revisar qué va a crear (plan)

```bash
# Ver qué va a cambiar (SIN crear nada aún)
terraform plan

# Salida:
# Plan: 45 to add, 0 to change, 0 to destroy
#
# Revisa líneas importantes:
# - aws_ecr_repository.fraud_api (ECR)
# - aws_ecs_cluster.main (ECS Cluster)
# - aws_ecs_service.app (ECS Service)
# - aws_lb.main (Load Balancer)
# - aws_apigatewayv2_api.fraud_api (API Gateway)
```

### 2.3: Aplicar configuración (CREATE)

```bash
# Crear toda la infraestructura (~5-10 minutos)
terraform apply

# Te pide confirmación:
# Do you want to perform these actions?
# Escribe: yes
# Presiona Enter

# Espera mientras Terraform crea:
# - VPC y subnets
# - Security groups
# - Load Balancer
# - ECS Cluster
# - API Gateway
# - etc.

# Resultado: Outputs con URLs
```

### 2.4: Ver outputs importantes

```bash
# Las URLs que necesitas:
terraform output

# O específico:
terraform output -raw api_gateway_endpoint
# Resultado: https://xxx.execute-api.us-east-1.amazonaws.com/prod

terraform output -raw ecr_repository_url
# Resultado: 123456789.dkr.ecr.us-east-1.amazonaws.com/fraud-api
```

---

## Paso 3: Verificar Deployment

### 3.1: Esperar a que ECS esté listo

```bash
# Ver estado del servicio
aws ecs describe-services \
  --cluster fraud-api-cluster \
  --services fraud-api-service \
  --region us-east-1 \
  --query 'services[0].{
    Status: status,
    DesiredCount: desiredCount,
    RunningCount: runningCount,
    Deployments: deployments[0].{Status: status, TaskCount: taskCount}
  }' \
  --output table

# Espera hasta que:
# - Status = ACTIVE
# - RunningCount = DesiredCount (normalmente 2)
# - Deployment Status = PRIMARY
```

### 3.2: Ver logs

```bash
# CloudWatch logs en tiempo real
aws logs tail /ecs/fraud-api --follow

# O en AWS Console:
# CloudWatch → Log Groups → /ecs/fraud-api
```

### 3.3: Test la API

```bash
# Obtener URL
API_URL=$(terraform output -raw api_gateway_endpoint)
echo "Testeando en: $API_URL"

# Test health
curl -X GET "$API_URL/health"
# Resultado: {"status":"ok"}

# Test fraud prediction
curl -X POST "$API_URL/fraud/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX123",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
  }'

# Resultado esperado:
# {
#   "schema_version": "1.0",
#   "request_id": "REQ-ABC12",
#   "ml_score_0_999": 150.5,
#   "model_meta": {...},
#   "latency_ms": 10.5
# }
```

### 3.4: Ver métricas

```bash
# CPU y memoria promedio
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=fraud-api-service \
                Name=ClusterName,Value=fraud-api-cluster \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum \
  --region us-east-1
```

---

## Paso 4: Troubleshooting

### Problema: "Containers exit immediately"

```bash
# Ver logs
aws logs tail /ecs/fraud-api --follow

# Problema común: 
# "No module named 'torch'"
# Causa: requirements.txt no instalado

# Solución:
# 1. Revisa Dockerfile (RUN pip install -r...)
# 2. Rebuild: docker build -t ... .
# 3. Re-push: docker push ...
# 4. Reinicia ECS service:
aws ecs update-service \
  --cluster fraud-api-cluster \
  --service fraud-api-service \
  --force-new-deployment \
  --region us-east-1

# Espera 2-3 minutos a que rescale
```

### Problema: "API Gateway returns 502 Bad Gateway"

```bash
# Causa: Load Balancer no tiene targets sanos

# Ver target health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw alb_arn | sed 's/loadbalancer/targetgroup/') \
  --region us-east-1

# Si Status = "unhealthy":
# 1. Revisa logs del ECS:
aws logs tail /ecs/fraud-api --follow

# 2. Verifica health check:
curl http://<load-balancer-dns>:8000/health

# 3. Aumenta timeout en Terraform:
# (en terraform/main.tf: health_check { timeout = 5 })
```

### Problema: "Timeout al llamar API"

```bash
# Causa: Modelo Torch tarda mucho al cargar

# Solución 1: Aumentar timeout en ALB
# (Terraform main.tf, health_check timeout)

# Solución 2: Pre-cargar modelo
# (Código: usa @router.on_event("startup"))

# Solución 3: Aumentar memoria ECS
# (terraform.tfvars: ecs_task_memory = 4096)
# Luego: terraform apply
```

### Problema: "ECR Image Push falla: permission denied"

```bash
# Causa: Permisos IAM insuficientes

# Verifica usuario tiene:
# - ecr:GetAuthorizationToken
# - ecr:BatchCheckLayerAvailability
# - ecr:GetDownloadUrlForLayer
# - ecr:PutImage
# - ecr:InitiateLayerUpload
# - ecr:UploadLayerPart
# - ecr:CompleteLayerUpload

# Agrega policy a tu usuario IAM en AWS Console
```

---

## Paso 5: Cleanup (Destruir recursos)

⚠️ **IMPORTANTE:** Esto eliminará TODO. Asegúrate de tener backups.

```bash
# OPCIÓN 1: Destruir solo recurso específico

# Destruir ECS service (pero mantener ALB)
aws ecs update-service \
  --cluster fraud-api-cluster \
  --service fraud-api-service \
  --desired-count 0 \
  --region us-east-1

# Destruir con Terraform
cd terraform

# Revisar qué va a destruir
terraform plan -destroy

# Destruir DEFINITIVAMENTE
terraform destroy

# Confirma escribiendo: yes
```

```bash
# OPCIÓN 2: Mantener infraestructura pero solo parar contenedores

# Reduce a 0:
aws ecs update-service \
  --cluster fraud-api-cluster \
  --service fraud-api-service \
  --desired-count 0 \
  --region us-east-1

# Más tarde, re-iniciar:
aws ecs update-service \
  --cluster fraud-api-cluster \
  --service fraud-api-service \
  --desired-count 2 \
  --region us-east-1
```

---

## ⏱️ Tiempo Estimado

| Fase | Tiempo |
|------|--------|
| **Docker build** | 3-5 min |
| **ECR push** | 2-3 min (+ Trivy scan) |
| **Terraform init** | 1 min |
| **Terraform plan** | 1 min |
| **Terraform apply** | 5-10 min |
| **ECS cluster ready** | 2-3 min |
| **TOTAL** | **15-25 minutos** |

---

## 📞 Comandos Útiles

```bash
# Ejecutar en bash/zsh/PowerShell

# Ver estado ECS
aws ecs describe-services --cluster fraud-api-cluster --services fraud-api-service

# Escalar (aumentar contenedores)
aws ecs update-service --cluster fraud-api-cluster --service fraud-api-service --desired-count 5

# Reducir
aws ecs update-service --cluster fraud-api-cluster --service fraud-api-service --desired-count 1

# Forza reinicio de tasks
aws ecs update-service --cluster fraud-api-cluster --service fraud-api-service --force-new-deployment

# Ver logs (últimas 100 líneas)
aws logs tail /ecs/fraud-api --max-items 100

# Ver eventos (errores, cambios)
aws logs filter-log-events --log-group-name /ecs/fraud-api --filter-pattern 'ERROR'

# Obtener IP del Load Balancer
aws elbv2 describe-load-balancers --names fraud-api-alb --query 'LoadBalancers[0].DNSName' --output text

# Test directo al LB (sin API Gateway)
curl http://<dns-name>/health
```

---

## 🎯 Siguiente

1. ✅ Deployaste manualmente
2. ⏭️ Ahora configura GitHub Actions para CI/CD automático
3. ⏭️ Configura dominio y SSL certificate
4. ⏭️ Configura monitoreo y alertas
