# 📚 DOCUMENTACIÓN TÉCNICA CONCISA - Fraudes Diners (CloudFormation Focus)

**Versión:** 2024.11 | **Fecha:** Febrero 2026 | **⭐ TODO CENTRADO EN CLOUDFORMATION**

---

## 📖 Tabla de Contenidos

1. [¿QUÉ ES CLOUDFORMATION?](#1-qué-es-cloudformation)
2. [Arquitectura (con CloudFormation)](#2-arquitectura-con-cloudformation)
3. [CloudFormation: 9 Recursos Creados](#3-cloudformation-9-recursos-creados)
4. [Parámetros de CloudFormation](#4-parámetros-de-cloudformation)
5. [Salidas (Outputs) de CloudFormation](#5-salidas-outputs-de-cloudformation)
6. [Flujo: Cliente → API Gateway → SageMaker](#6-flujo-cliente--api-gateway--sagemaker)
7. [Componentes FastAPI](#7-componentes-fastapi)
8. [Endpoints API](#8-endpoints-api)
9. [Deployment con CloudFormation](#9-deployment-con-cloudformation)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. ¿QUÉ ES CLOUDFORMATION?

**CloudFormation** es un servicio de AWS que automatiza la creación de infraestructura usando archivos YAML/JSON.

### Analogía Simple

```
CloudFormation = "Receta de Cocina"
├─ Ingredientes = Parámetros de entrada (ImageUri, InstanceType)
├─ Pasos = Recursos a crear (IAM, SageMaker, API Gateway)
└─ Resultado = Infraestructura completa lista para usar
```

### ¿POR QUÉ usamos CloudFormation?

✅ **Automático:** Un comando crea 9 recursos AWS   
✅ **Reproducible:** Mismo código = mismo resultado   
✅ **Versionable:** En Git como cualquier código   
✅ **Rápido:** Deploy en <10 minutos   
✅ **Fácil de destruir:** Borra TODO con un comando   

---

## 2. ARQUITECTURA (con CloudFormation)

```
┌─────────────────────────────────────────┐
│ CloudFormation Template                 │
│ (infra-sagemaker-complete.yaml)         │
└────────────────┬────────────────────────┘
                 │ aws cloudformation create-stack
                 ↓
        CloudFormation Engine
        ├─→ Crea IAM Roles
        ├─→ Crea SageMaker Model
        ├─→ Crea SageMaker Endpoint
        ├─→ Crea API Gateway REST API
        ├─→ Crea API Gateway Resource (/fraude)
        ├─→ Crea API Gateway Method (POST)
        ├─→ Crea API Gateway Deployment
        ├─→ Configura credenciales y permisos
        └─→ Retorna Outputs (URL)
                 ↓
        Infraestructura en AWS:
        ├─ SageMaker ejecutando tu modelo
        ├─ API Gateway exponiendo https://abc.../prod/fraude
        └─ Todo conectado automáticamente
```

---

## 3. CLOUDFORMATION: 9 RECURSOS CREADOS

**Archivo:** `infra-sagemaker-complete.yaml`

### Recurso 1: SageMakerExecutionRole (IAM)

```yaml
Propósito: Dar permisos a SageMaker
Permite:
  ✓ Descargar imagen Docker desde ECR
  ✓ Escribir logs en CloudWatch
  ✓ Acceder S3 si necesita
Usa: SageMaker service
```

### Recurso 2: APIGatewaySageMakerRole (IAM)

```yaml
Propósito: Dar permisos a API Gateway
Permite:
  ✓ Invocar SageMaker endpoint SOLO
Usa: API Gateway service
```

### Recurso 3: SageMaker::Model

```yaml
Propósito: Definir el modelo
Especifica:
  - Name: fraudes-model-{stack}
  - Image: {tu-imagen-ecr}
  - Program: main.py
  - Role: SageMakerExecutionRole
```

### Recurso 4: SageMaker::EndpointConfig

```yaml
Propósito: Configuración del endpoint (no ejecuta aún)
Especifica:
  - InstanceType: ml.m5.large (o parámetro)
  - InitialInstanceCount: 1
  - ModelName: fraudes-model
```

### Recurso 5: SageMaker::Endpoint

```yaml
Propósito: EJECUTAR el modelo en AWS
Estados:
  Creating →  (5-10 min)
  → InService (listo para inferencia)
URL Interna:
  arn:aws:sagemaker:.../endpoint/endpoint-fraudes-prod
```

### Recurso 6: ApiGateway::RestApi

```yaml
Propósito: Crear API REST pública HTTPS
Genera:
  Name: fraudes-api-prod
  Type: REGIONAL
  URL: https://{api-id}.execute-api.us-east-1.amazonaws.com
```

### Recurso 7: ApiGateway::Resource

```yaml
Propósito: Crear ruta /fraude
Path: GET https://.../prod/fraude
```

### Recurso 8: ApiGateway::Method

```yaml
Propósito: Conectar POST /fraude → SageMaker
Configuración:
  - HttpMethod: POST
  - Uri: arn:aws:apigateway:region:runtime.sagemaker:path/endpoints/endpoint-fraudes-{stack}/invocations
  - Credentials: APIGatewayRole.Arn
  - Transforma requests/responses automáticamente
```

### Recurso 9: ApiGateway::Deployment

```yaml
Propósito: Publicar API en el stage "prod"
Sin esto:  API existe pero no es accesible
Con esto:  https://{api-id}.execute-api.../prod/fraude ES VIVA
```

---

## 4. PARÁMETROS DE CLOUDFORMATION

Tu proporcionas cuando ejecutas el stack:

```bash
aws cloudformation create-stack ... \
  --parameters \
    ParameterKey=ImageUri,ParameterValue=761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest \
    ParameterKey=InstanceType,ParameterValue=ml.m5.large
```

| Parámetro | Ejemplo | Uso |
|-----------|---------|-----|
| `ImageUri` | `{ACCOUNT}.dkr.ecr.../fraud-api:latest` | ¿Cuál imagen Docker usar? |
| `InstanceType` | `ml.m5.large` | ¿Qué máquina para SageMaker? |

---

## 5. SALIDAS (OUTPUTS) DE CLOUDFORMATION

Cuando el stack termina, CloudFormation retorna:

```bash
aws cloudformation describe-stacks --stack-name fraud-detection-prod \
  --query 'Stacks[0].Outputs'
```

**Retorna:**

```json
[
  {
    "OutputKey": "ModelName",
    "OutputValue": "fraudes-model-prod"
  },
  {
    "OutputKey": "EndpointName",
    "OutputValue": "endpoint-fraudes-prod"
  },
  {
    "OutputKey": "ApiId",
    "OutputValue": "abc123xyz"
  },
  {
    "OutputKey": "ApiInvokeUrl",
    "OutputValue": "https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod/fraude"
    ← ⭐ ESTA ES LA URL QUE USA TU CLIENTE
  }
]
```

---

## 6. FLUJO: CLIENTE → API GATEWAY → SAGEMAKER

### Paso a Paso (5 pasos)

```
1. CLIENTE envía
   POST https://abc123.execute-api.us-east-1.amazonaws.com/prod/fraude
   {
     "transaction_id": "TRX-001",
     "monto": 150,
     "edad": 35,
     "ciudad": "Quito",
     "establecimiento": "Amazon",
     "especialidad": "ECOMMERCE"
   }
        ↓
2. API GATEWAY (creado por CloudFormation)
   ├─ Valida CORS
   ├─ Rate-limiting (si configurado)
   └─ Invoca SageMaker endpoint
        ↓
3. SAGEMAKER ENDPOINT (recurso 5 de CloudFormation)
   ├─ Ejecuta tu imagen Docker
   ├─ URI: /endpoints/endpoint-fraudes-{stack}/invocations
   └─ Usa credenciales APIGatewaySageMakerRole
        ↓
4. DOCKER CONTAINER (tu FastAPI)
   ├─ main.py carga FastAPI
   ├─ Pydantic valida input
   ├─ Modelo predice
   └─ Retorna JSON
        ↓
5. RESPUESTA vuelve al cliente
   {
     "schema_version": "1.0",
     "request_id": "REQ-A1B2C",
     "ml_score_0_999": 125,
     "model_meta": {...},
     "latency_ms": 45.23
   }
```

---

## 7. COMPONENTES FASTAPI

### Estructura

```
endpoint_prototipo/
├── main.py
│   ├── Inicializa FastAPI
│   ├── Carga modelo en startup
│   ├── Configura CORS
│   └─ Registra routers
│
├── schemas.py
│   ├── FraudPredictionRequest
│   ├── FraudPredictionResponse
│   └── HealthResponse
│
└── routers/
    ├── health.py → GET /health/
    ├── fraud_prediction.py → POST /fraud/predict
    └──                    → POST /fraud/batch-predict
```

### Request Schema

```python
{
  "transaction_id": str,      # ID transacción
  "monto": float (>0),       # Monto
  "edad": int (18-120),      # Edad
  "ciudad": str,             # Ciudad
  "establecimiento": str,    # Comercio
  "especialidad": str        # Categoría
}
```

### Response Schema

```python
{
  "schema_version": "1.0",
  "request_id": "REQ-XXXXX",     # Para auditoria
  "ml_score_0_999": 125,         # 0-999 (999=fraude)
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": 45.23            # Tiempo inferencia
}
```

---

## 8. ENDPOINTS API

### Health Check
```http
GET /health/
```
Response: `{"status": "healthy", "model_loaded": true, "version": "1.0.0"}`

### Single Prediction
```http
POST /fraud/predict
Content-Type: application/json

{JSON de request}
```
Response: `{JSON de response}`

### Batch Prediction
```http
POST /fraud/batch-predict
[{JSON request}, {JSON request}, ...]
```
Response: `[{JSON response}, {JSON response}, ...]`

---

## 9. DEPLOYMENT CON CLOUDFORMATION

### Step 1: Preparar Imagen Docker

```bash
# Build
docker build -t fraud-api:latest .

# Tag para ECR
docker tag fraud-api:latest {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# Login ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com

# Push
docker push {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest
```

### Step 2: Crear CloudFormation Stack

```bash
aws cloudformation create-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters \
    ParameterKey=ImageUri,ParameterValue={ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest \
    ParameterKey=InstanceType,ParameterValue=ml.m5.large \
  --capabilities CAPABILITY_NAMED_IAM
```

### ¿QUÉ PASA?

CloudFormation automáticamente:
1. Valida el template YAML
2. Crea 9 recursos en orden correcto (respetando dependencias)
3. Espera a que cada recurso esté listo antes de crear el siguiente
4. Si falla, rollback automático

### Step 3: Esperar & Obtener URL

```bash
# Esperar a que termine
aws cloudformation wait stack-create-complete --stack-name fraud-detection-prod

# Obtener URL
API_URL=$(aws cloudformation describe-stacks \
  --stack-name fraud-detection-prod \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiInvokeUrl`].OutputValue' \
  --output text)

echo $API_URL
# Output: https://abc123.execute-api.us-east-1.amazonaws.com/prod/fraude
```

### Step 4: Testear

```bash
curl -X POST $API_URL -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TEST-001",
    "monto": 150,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "Test",
    "especialidad": "TEST"
  }'
```

### Step 5: Actualizar Stack (si cambias algo)

```bash
aws cloudformation update-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters ParameterKey=InstanceType,ParameterValue=ml.m5.xlarge \
  --capabilities CAPABILITY_NAMED_IAM
```

### Step 6: Eliminar Stack (borra TODO)

```bash
aws cloudformation delete-stack --stack-name fraud-detection-prod

# Esperar
aws cloudformation wait stack-delete-complete --stack-name fraud-detection-prod
```

---

## 10. TROUBLESHOOTING

### CloudFormation Error: CREATE_FAILED

```bash
# Ver eventos
aws cloudformation describe-stack-events \
  --stack-name fraud-detection-prod \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Causas comunes:
# - ImageUri inválida (no existe en ECR)
# - Permisos IAM insuficientes
# - Cuota SageMaker excedida
```

### Error: "Model not loaded" (503)

```bash
# Ver logs del endpoint
aws logs tail /aws/sagemaker/Endpoints/endpoint-fraudes-prod --follow
```

### API Timeout (P95 > 200ms)

```bash
# Scale up instancia
aws cloudformation update-stack \
  --stack-name fraud-detection-prod \
  --parameters ParameterKey=InstanceType,ParameterValue=ml.m5.xlarge
```

---

**Status:** ✅ Production Ready  
**Last Update:** Febrero 2026
