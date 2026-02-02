# CloudFormation Deployment Guide

## 📋 Descripción

Esta plantilla CloudFormation despliega la aplicación FastAPI de detección de fraudes en AWS usando:

- **ECS Fargate**: Compute sin servidor
- **Application Load Balancer (ALB)**: Distribución de carga
- **Auto Scaling**: Escalado automático basado en CPU y memoria
- **CloudWatch Logs**: Logging centralizado
- **VPC**: Red privada con subnets públicas

## 🚀 Requisitos Previos

### 1. Cuenta AWS
- Acceso a AWS Console
- Permisos para crear recursos (VPC, ECS, ALB, IAM, etc.)
- AWS CLI configurado

### 2. ECR Repository
Crear un repositorio ECR para las imágenes Docker:

```bash
aws ecr create-repository \
  --repository-name fraudes-diners \
  --region us-east-1
```

### 3. Docker Image
Build y push de la imagen Docker:

```bash
# Build
docker build -t fraudes-diners:latest .

# Tag para ECR
docker tag fraudes-diners:latest \
  123456789.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest

# Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# Push
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest
```

## 📝 Configuración de Parámetros

Editar `parameters-dev.json` con tus valores:

```json
{
  "ParameterKey": "DockerImage",
  "ParameterValue": "YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/fraudes-diners:latest"
},
{
  "ParameterKey": "EnvironmentName",
  "ParameterValue": "development"  // o "staging", "production"
},
{
  "ParameterKey": "DesiredCount",
  "ParameterValue": "2"  // número de tareas ECS
}
```

## 🔧 Deployment

### Opción 1: Usando el script de bash

```bash
# Hacer el script ejecutable
chmod +x deploy.sh

# Ejecutar deployment
./deploy.sh fraudes-diners-stack development us-east-1

# O con valores por defecto
./deploy.sh
```

### Opción 2: Usando AWS CLI directamente

#### Crear stack
```bash
aws cloudformation create-stack \
  --stack-name fraudes-diners-stack \
  --template-body file://fraud-detection-api-template.yaml \
  --parameters file://parameters-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

#### Actualizar stack
```bash
aws cloudformation update-stack \
  --stack-name fraudes-diners-stack \
  --template-body file://fraud-detection-api-template.yaml \
  --parameters file://parameters-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

#### Esperar a que se complete
```bash
aws cloudformation wait stack-create-complete \
  --stack-name fraudes-diners-stack \
  --region us-east-1
```

### Opción 3: Usando AWS Console

1. Ir a CloudFormation en AWS Console
2. Click en "Create Stack"
3. Elegir "Upload a template file"
4. Seleccionar `fraud-detection-api-template.yaml`
5. Llenar los parámetros
6. Review y crear

## 📊 Obtener Información del Stack

### Outputs
```bash
aws cloudformation describe-stacks \
  --stack-name fraudes-diners-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs' \
  --output table
```

### Recursos creados
```bash
aws cloudformation list-stack-resources \
  --stack-name fraudes-diners-stack \
  --region us-east-1
```

### URL de la API
```bash
aws cloudformation describe-stacks \
  --stack-name fraudes-diners-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \
  --output text
```

## 🧪 Testing

Una vez el stack esté desplegado:

```bash
# Obtener URL
API_URL=$(aws cloudformation describe-stacks \
  --stack-name fraudes-diners-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \
  --output text)

# Health check
curl -X GET $API_URL/health

# Swagger UI
curl -X GET $API_URL/docs

# Test de predicción
curl -X POST $API_URL/fraud/predict \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX123456",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
  }'
```

## 🔍 Monitoreo

### CloudWatch Logs
```bash
LOG_GROUP=$(aws cloudformation describe-stacks \
  --stack-name fraudes-diners-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`LogGroupName`].OutputValue' \
  --output text)

aws logs tail $LOG_GROUP --follow
```

### Métricas de ECS
```bash
# Ver tareas corriendo
aws ecs list-tasks \
  --cluster fraudes-diners-cluster-development \
  --region us-east-1

# Detalles de una tarea
aws ecs describe-tasks \
  --cluster fraudes-diners-cluster-development \
  --tasks <task-arn> \
  --region us-east-1
```

## 🧹 Limpieza

### Eliminar el stack
```bash
aws cloudformation delete-stack \
  --stack-name fraudes-diners-stack \
  --region us-east-1

# Esperar a que se elimine
aws cloudformation wait stack-delete-complete \
  --stack-name fraudes-diners-stack \
  --region us-east-1
```

## 🛡️ Seguridad

### Recomendaciones
1. **CORS**: Cambiar `allow_origins=["*"]` a dominios específicos
2. **HTTPS**: Añadir certificado ACM al ALB
3. **WAF**: Implementar AWS WAF en el ALB
4. **Autenticación**: Añadir JWT o API Keys
5. **Secrets Manager**: Usar para credenciales
6. **VPC Endpoints**: Para acceso a S3 y otros servicios

### Añadir HTTPS (ACM Certificate)
```bash
# En el template, añadir listener HTTPS
LoadBalancerListenerHTTPS:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    LoadBalancerArn: !Ref LoadBalancer
    Protocol: HTTPS
    Port: 443
    Certificates:
      - CertificateArn: arn:aws:acm:region:account:certificate/xxxxx
    DefaultActions:
      - Type: forward
        TargetGroupArn: !Ref TargetGroup
```

## 📈 Auto Scaling

La plantilla configura auto scaling basado en:
- **CPU**: Target del 70%
- **Memoria**: Target del 80%
- **Min Tasks**: 2
- **Max Tasks**: 10

Para ajustar:
```yaml
AutoScalingTarget:
  MaxCapacity: 20  # Aumentar
  MinCapacity: 1   # Disminuir
```

## 💰 Estimación de Costos

### Recursos principales:
- **ECS Fargate**: ~$0.04644 por vCPU-hora, ~$0.01024 por GB-hora
- **ALB**: ~$0.0225 por hora + $0.006 por LCU
- **NAT Gateway**: ~$32 por mes + $0.045 por GB
- **CloudWatch Logs**: $0.50 per GB ingested

**Estimación mensual (2 tasks, dev)**: ~$50-100

## 📞 Soporte

Para problemas:
1. Revisar logs de CloudWatch
2. Verificar eventos de CloudFormation
3. Comprobar estado de tareas en ECS
4. Revisar seguridad groups y VPC config

## 🔗 Recursos Útiles

- [CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)
- [ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/)
- [CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
