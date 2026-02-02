# CloudFormation Templates para Fraud Detection API

Esta carpeta contiene los templates de CloudFormation y scripts para desplegar la aplicación de detección de fraudes en AWS.

## 📁 Contenido

- **fraud-detection-api-template.yaml** - Template principal de CloudFormation
- **parameters-dev.json** - Parámetros para ambiente de desarrollo
- **deploy.sh** - Script automático de deployment
- **DEPLOYMENT_GUIDE.md** - Guía detallada paso a paso

## 🚀 Quick Start

### 1. Preparar imagen Docker
```bash
docker build -t fraudes-diners:latest ..
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
docker tag fraudes-diners:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest
```

### 2. Actualizar parámetros
Editar `parameters-dev.json` con tu AWS Account ID y región.

### 3. Desplegar
```bash
chmod +x deploy.sh
./deploy.sh fraudes-diners-stack development us-east-1
```

## 📊 Arquitectura

```
┌─────────────────────────────────────────────────┐
│               AWS VPC (10.0.0.0/16)             │
├─────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────┐  │
│  │   Internet Gateway                        │  │
│  └──────────────────────────────────────────┘  │
│                     ↓                           │
│  ┌──────────────────────────────────────────┐  │
│  │  Application Load Balancer               │  │
│  │  - Port 80 (HTTP)                        │  │
│  └──────────────────────────────────────────┘  │
│                     ↓                           │
│  ┌────────────────┬─────────────────────────┐  │
│  │ Public Subnet 1│ Public Subnet 2         │  │
│  │ (10.0.1.0/24) │ (10.0.2.0/24)           │  │
│  ├────────────────┼─────────────────────────┤  │
│  │ ┌────────────┐ │ ┌────────────┐          │  │
│  │ │ ECS Task 1 │ │ │ ECS Task 2 │          │  │
│  │ │ Port 8000  │ │ │ Port 8000  │          │  │
│  │ └────────────┘ │ └────────────┘          │  │
│  │                │                         │  │
│  └────────────────┴─────────────────────────┘  │
└─────────────────────────────────────────────────┘
         ↓
  CloudWatch Logs
  Auto Scaling
```

## 🔧 Parámetros Configurables

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| EnvironmentName | development | dev/staging/production |
| ProjectName | fraudes-diners | Nombre del proyecto |
| DockerImage | - | URI de imagen ECR |
| DesiredCount | 2 | Número de tareas ECS |
| ContainerPort | 8000 | Puerto del contenedor |
| VpcCIDR | 10.0.0.0/16 | CIDR del VPC |
| PublicSubnet1CIDR | 10.0.1.0/24 | CIDR Subnet 1 |
| PublicSubnet2CIDR | 10.0.2.0/24 | CIDR Subnet 2 |

## 📈 Recursos Creados

### Networking
- 1 VPC
- 2 Public Subnets (Multi-AZ)
- 1 Internet Gateway
- 1 Route Table

### Load Balancing
- 1 Application Load Balancer
- 1 Target Group
- 1 Listener HTTP (puerto 80)

### Computing
- 1 ECS Cluster
- 1 Task Definition
- 1 ECS Service (con ALB integration)

### Auto Scaling
- 1 Scalable Target
- 2 Scaling Policies (CPU + Memory)

### Security
- 1 Security Group ALB
- 1 Security Group ECS
- 2 IAM Roles (Execution + Task)

### Monitoring
- 1 CloudWatch Log Group (7 días retención)

## ✨ Features

✅ Multi-AZ deployment  
✅ Load balancing automático  
✅ Auto scaling basado en métricas  
✅ Health checks integrados  
✅ CloudWatch Logs centralizado  
✅ IAM roles con least privilege  
✅ VPC aislada  
✅ Parametrizado para múltiples ambientes  

## 🧪 Testing

Una vez desplegado:

```bash
# Obtener URL del ALB
API_URL=$(aws cloudformation describe-stacks \
  --stack-name fraudes-diners-stack \
  --query 'Stacks[0].Outputs[0].OutputValue' \
  --output text)

# Health check
curl $API_URL/health

# Swagger UI
open $API_URL/docs

# Test de predicción
curl -X POST $API_URL/fraud/predict \
  -H "Content-Type: application/json" \
  -d '{"transaction_id":"TRX123","monto":100,"edad":30,"ciudad":"Quito","establecimiento":"Test","especialidad":"GENERAL"}'
```

## 🚨 Troubleshooting

### El stack no se crea
```bash
# Ver eventos del stack
aws cloudformation describe-stack-events \
  --stack-name fraudes-diners-stack \
  --query 'StackEvents[?ResourceStatus!=`CREATE_SUCCESSFUL`]'
```

### Las tareas no arrancan
```bash
# Ver logs de las tareas
aws logs tail /ecs/fraudes-diners-development --follow
```

### El ALB no responde
```bash
# Ver target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

## 🧹 Eliminar Stack

```bash
aws cloudformation delete-stack --stack-name fraudes-diners-stack
```

## 📚 Recursos

- [CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)
- [ECS on Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_AWSFAQ.html)
- [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)

## 💬 Notas

- El template usa Fargate para no requerir EC2 instances
- Los logs se retienen 7 días (modificable)
- El auto scaling es gradual para evitar cambios abruptos
- Las subnets son públicas por simplicidad (considerar privadas en prod)

---

**Última actualización**: Enero 30, 2026
