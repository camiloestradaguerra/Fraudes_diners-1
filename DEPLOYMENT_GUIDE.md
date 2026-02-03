# 🚀 MLOps Platform - Fraud Detection API

## Documentación Oficial - Etapa CloudFormation

**Versión:** 1.0  
**Fecha:** Febrero 2, 2026  
**Estado:** ✅ Producción Ready

---

## 📋 Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Arquitectura](#arquitectura)
3. [Requisitos](#requisitos)
4. [Flujo de Despliegue](#flujo-de-despliegue)
5. [Uso End-to-End](#uso-end-to-end)
6. [Infraestructura Creada](#infraestructura-creada)
7. [Testing](#testing)
8. [Monitoreo](#monitoreo)

---

## Descripción General

**Fraud Detection API** es una plataforma MLOps completa que:

- 🐳 Ejecuta modelos de detección de fraudes en **Docker**
- 📦 Almacena imágenes en **AWS ECR**
- 🤖 Sirve predicciones con **SageMaker**
- 🌐 Expone API REST mediante **API Gateway**
- 🔐 Gestiona permisos con **IAM**

**Tecnología:** AWS CloudFormation (IaC completo)

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                        API Client                               │
│                         (Usuario)                               │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                    POST /fraude (JSON)
                               │
                               ▼
                    ┌──────────────────────┐
                    │   API Gateway        │
                    │  (REST Endpoint)     │
                    └──────────┬───────────┘
                               │
                    Integration: SageMaker
                               │
                               ▼
                    ┌──────────────────────┐
                    │  SageMaker Runtime   │
                    │    (Inference)       │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │   SageMaker Endpoint │
                    │   (ml.m5.large)      │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │   Docker Container   │
                    │  (Fraud Model v2024) │
                    │     (ECR Image)      │
                    └──────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  All Infrastructure Created by CloudFormation (Single Command)   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Requisitos

### Local
- ✅ Docker Desktop (corriendo)
- ✅ AWS CLI v2
- ✅ Credenciales AWS configuradas
- ✅ Python 3.11+ (opcional, para troubleshooting)

### AWS
- ✅ Cuenta AWS con permisos de administrador
- ✅ Region: `us-east-1` (configurable)

---

## Flujo de Despliegue

### Paso 1: Construir Imagen Docker

```bash
cd c:\Users\CAMILO\Documents\Diners\Proyecto Fraudes\Fraudes_diners

docker build -t fraud-detection-api:latest .
```

**Qué hace:**
- Copia código Python en imagen
- Instala dependencias (scikit-learn, pandas, etc.)
- Configura SageMaker como entrypoint

**Output esperado:**
```
[...] Building...
=> exporting layers                                           0.1s
=> naming to docker.io/library/fraud-detection-api:latest    0.0s
```

### Paso 2: Pushear a ECR

```bash
# Variables
$account = "761951921633"
$region = "us-east-1"
$repo = "fraud-detection-api"

# Crear repositorio ECR
aws ecr create-repository --repository-name $repo --region $region

# Autenticar Docker
aws ecr get-login-password --region $region | `
  docker login --username AWS --password-stdin "$account.dkr.ecr.$region.amazonaws.com"

# Tag
docker tag fraud-detection-api:latest `
  "$account.dkr.ecr.$region.amazonaws.com/$repo:latest"

# Push
docker push "$account.dkr.ecr.$region.amazonaws.com/$repo:latest"
```

**Output esperado:**
```
latest: digest: sha256:d59a03039a2a4b4a63670b35bd76e19e82ecf72e759bdc761ac0c8ce8af11c69
```

### Paso 3: Desplegar CloudFormation

```bash
# Deploy stack (crea TODA la infraestructura)
aws cloudformation create-stack `
  --stack-name fraudes-prod-final `
  --template-body file://infra-sagemaker-complete.yaml `
  --parameters `
    ParameterKey=ImageUri,ParameterValue=761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest `
  --capabilities CAPABILITY_NAMED_IAM `
  --region us-east-1
```

**CloudFormation crea automáticamente:**
- IAM Role (SageMaker Execution)
- IAM Role (API Gateway)
- IAM Policies
- SageMaker Model
- SageMaker Endpoint Config
- SageMaker Endpoint (ml.m5.large)
- API Gateway REST API
- API Gateway Resource (/fraude)
- API Gateway Method (POST)
- API Gateway Deployment

**Tiempo:** ~4-5 minutos

### Paso 4: Obtener Outputs

```bash
# Ver stack outputs
aws cloudformation describe-stacks `
  --stack-name fraudes-prod-final `
  --region us-east-1 `
  --query 'Stacks[0].Outputs' `
  --output table
```

**Outputs principales:**
```
ModelName:        fraudes-model-fraudes-prod-final
EndpointName:     endpoint-fraudes-fraudes-prod-final
ApiInvokeUrl:     https://0vjdv8nplh.execute-api.us-east-1.amazonaws.com/prod/fraude
```

---

## Uso End-to-End

### Llamar API (PowerShell)

```powershell
$apiUrl = "https://0vjdv8nplh.execute-api.us-east-1.amazonaws.com/prod/fraude"

$body = @{
    transaction_id = "TRX-001"
    monto = 1500.00
    edad = 35
    ciudad = "Quito"
    establecimiento = "Shopping-Center"
    especialidad = "RETAIL"
} | ConvertTo-Json

$response = Invoke-WebRequest `
    -Uri $apiUrl `
    -Method POST `
    -ContentType "application/json" `
    -Body $body `
    -UseBasicParsing

$response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

### Llamar API (cURL)

```bash
curl -X POST https://0vjdv8nplh.execute-api.us-east-1.amazonaws.com/prod/fraude \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX-001",
    "monto": 1500.0,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "Shopping-Center",
    "especialidad": "RETAIL"
  }'
```

### Response

```json
{
  "schema_version": "1.0",
  "request_id": "REQ-48928",
  "ml_score_0_999": 999.0,
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": 0.0426
}
```

---

## Infraestructura Creada

### 1. IAM Roles

| Recurso | Propósito | Políticas |
|---------|-----------|-----------|
| `sagemaker-execution-{stack}` | SageMaker execution | AmazonSageMakerFullAccess + ECR Access |
| `apigateway-sagemaker-{stack}` | API Gateway integration | InvokeEndpoint on endpoint/* |

### 2. SageMaker

| Recurso | Valor |
|---------|-------|
| Model Name | `fraudes-model-{stack-name}` |
| Endpoint Config | `fraudes-config-{stack-name}` |
| Endpoint Name | `endpoint-fraudes-{stack-name}` |
| Instance Type | `ml.m5.large` |
| Status | `InService` |

### 3. API Gateway

| Recurso | Configuración |
|---------|---------------|
| REST API | `fraudes-api-{stack-name}` |
| Resource | `/fraude` |
| Method | `POST` |
| Integration | AWS SageMaker Runtime |
| Deployment | `prod` stage |

---

## Testing

### 1. Verificar Status del Endpoint

```bash
aws sagemaker describe-endpoint \
  --endpoint-name endpoint-fraudes-fraudes-prod-final \
  --region us-east-1 \
  --query 'EndpointStatus'
```

**Output esperado:** `InService`

### 2. Listar Recursos CloudFormation

```bash
aws cloudformation describe-stack-resources \
  --stack-name fraudes-prod-final \
  --region us-east-1 \
  --query 'StackResources[*].[LogicalResourceId, ResourceStatus]' \
  --output table
```

### 3. Test de API con latencia

```powershell
for ($i=0; $i -lt 5; $i++) {
    $start = Get-Date
    $response = Invoke-WebRequest `
        -Uri "https://0vjdv8nplh.execute-api.us-east-1.amazonaws.com/prod/fraude" `
        -Method POST `
        -ContentType "application/json" `
        -Body '{"transaction_id":"TRX-'$i'","monto":500,"edad":30,"ciudad":"Quito","establecimiento":"Store","especialidad":"RETAIL"}' `
        -UseBasicParsing
    $elapsed = (Get-Date) - $start
    Write-Host "Request $i - Time: $($elapsed.TotalMilliseconds)ms - Status: $($response.StatusCode)"
}
```

---

## Monitoreo

### 1. Ver Logs de CloudFormation

```bash
aws cloudformation describe-stack-events \
  --stack-name fraudes-prod-final \
  --region us-east-1 \
  --query 'StackEvents[0:10]' \
  --output table
```

### 2. Métricas de SageMaker

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/SageMaker \
  --metric-name ModelLatency \
  --dimensions Name=EndpointName,Value=endpoint-fraudes-fraudes-prod-final \
  --start-time 2026-02-02T00:00:00Z \
  --end-time 2026-02-03T00:00:00Z \
  --period 3600 \
  --statistics Average \
  --region us-east-1
```

### 3. Eliminar Stack (si necesario)

```bash
aws cloudformation delete-stack \
  --stack-name fraudes-prod-final \
  --region us-east-1
```

---

## 📁 Estructura de Archivos

```
Fraudes_diners/
├── Dockerfile                      # Imagen Docker con modelo
├── infra-sagemaker-complete.yaml   # Template CloudFormation (IaC)
├── endpoint_prototipo/             # Código de la API (FastAPI)
│   ├── main.py
│   ├── routers/
│   │   ├── fraud_prediction.py
│   │   └── health.py
│   └── requirements.txt
├── api-invoke-url.txt              # URL del API (generado)
├── endpoint-name.txt               # Nombre del endpoint (generado)
├── deployment-config.json          # Config del deployment (generado)
└── README.md                       # Este archivo
```

---

## Troubleshooting

### Problema: "Image not found in ECR"
**Solución:** Verificar que el push completó exitosamente:
```bash
aws ecr describe-images \
  --repository-name fraud-detection-api \
  --region us-east-1
```

### Problema: "Stack CREATE_FAILED"
**Solución:** Ver eventos:
```bash
aws cloudformation describe-stack-events \
  --stack-name fraudes-prod-final \
  --region us-east-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

### Problema: "Endpoint InService pero API retorna 500"
**Solución:** Verificar que el modelo responde:
```bash
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name endpoint-fraudes-fraudes-prod-final \
  --body '{"transaction_id":"TEST","monto":100}' \
  --content-type application/json \
  response.json

Get-Content response.json
```

---

## Ventajas de esta Arquitectura

✅ **Infrastructure as Code:** Todo en CloudFormation  
✅ **Reproducible:** Un comando, siempre el mismo resultado  
✅ **Escalable:** Cambiar `ml.m5.large` a `ml.m5.xlarge` en template  
✅ **Seguro:** Roles y políticas IAM específicas  
✅ **Observable:** CloudFormation Drift Detection  
✅ **Costo:** Pay-per-use SageMaker + API Gateway  

---

## Notas Importantes

- **Costo:** SageMaker endpoint cuesta ~$0.115/hora (ml.m5.large)
- **Imagen Docker:** 2.9 GB en ECR (comprimida)
- **Latencia:** ~40ms end-to-end (API Gateway + SageMaker)
- **Concurrencia:** Endpoint soporta auto-scaling

---

## Contacto & Soporte

Para reportar problemas o sugerencias, crear un issue en el repositorio.

**Última actualización:** 2026-02-02
