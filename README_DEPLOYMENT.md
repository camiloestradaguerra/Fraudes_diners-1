# 🚀 Fraud Detection API - MLOps Platform

API de detección de fraudes en tiempo real para transacciones Diners usando **AWS SageMaker** + **CloudFormation**.

## ⚡ Quick Start

### 1. Construir imagen Docker
```bash
docker build -t fraud-detection-api:latest .
```

### 2. Pushear a ECR
```bash
aws ecr create-repository --repository-name fraud-detection-api --region us-east-1
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 761951921633.dkr.ecr.us-east-1.amazonaws.com
docker tag fraud-detection-api:latest 761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest
docker push 761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest
```

### 3. Desplegar con CloudFormation
```bash
aws cloudformation create-stack \
  --stack-name fraudes-prod-final \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters ParameterKey=ImageUri,ParameterValue=761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 4. Obtener URL del API
```bash
aws cloudformation describe-stacks \
  --stack-name fraudes-prod-final \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiInvokeUrl`].OutputValue' \
  --output text
```

### 5. Hacer predicción
```bash
curl -X POST <API_URL> \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX-001",
    "monto": 1000.0,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "Store",
    "especialidad": "RETAIL"
  }'
```

## 📋 Documentación

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guía completa de despliegue
- **[Dockerfile](Dockerfile)** - Configuración de imagen Docker
- **[infra-sagemaker-complete.yaml](infra-sagemaker-complete.yaml)** - Template CloudFormation

## 🏗️ Arquitectura

```
Docker Image → ECR → SageMaker Model → SageMaker Endpoint → API Gateway → Cliente
                                                    ↑
                                          (CloudFormation crea TODO)
```

## 🔧 Tech Stack

- **Container:** Docker
- **Registry:** AWS ECR
- **Inference:** AWS SageMaker
- **API:** AWS API Gateway
- **IaC:** AWS CloudFormation
- **Security:** AWS IAM

## 📊 Specs

- **Instance Type:** ml.m5.large
- **Latency:** ~40ms
- **Model Version:** 2024.11
- **Python:** 3.11

## 💰 Estimado de Costos

- SageMaker Endpoint: ~$0.115/hora
- ECR Storage: ~$0.10/GB/mes
- API Gateway: ~$0.001/llamada

## ✅ Features

✓ Infrastructure as Code  
✓ Auto-scaling ready  
✓ Full IAM integration  
✓ Real-time predictions  
✓ Monitoring & logging  

## 🚀 Producción

Stack está listo para producción. Ver [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) para monitoreo y troubleshooting.

---

**Status:** ✅ Operacional  
**Última actualización:** Feb 2, 2026
