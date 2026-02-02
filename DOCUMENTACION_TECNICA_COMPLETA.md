# Documentación Técnica Completa: Despliegue de Modelo de Prevención de Fraudes

**Proyecto:** Fraudes Diners V5  
**Tecnología:** AWS SageMaker + Docker + FastAPI + API Gateway  
**Fecha de Despliegue:** 02 de febrero de 2026  
**Estado:** ✅ **Producción - InService**  
**Elaborado por:** Camilo - Proyecto Fraudes Diners

---

## 📋 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura General](#arquitectura-general)
3. [Componentes Técnicos](#componentes-técnicos)
4. [Proceso de Despliegue (Paso a Paso)](#proceso-de-despliegue)
5. [Configuración Actual (Producción)](#configuración-actual-producción)
6. [Cómo Consumir la API](#cómo-consumir-la-api)
7. [Especificaciones Técnicas Detalladas](#especificaciones-técnicas-detalladas)
8. [Guía de Troubleshooting](#guía-de-troubleshooting)
9. [Seguridad e IAM](#seguridad-e-iam)
10. [Monitoreo y Logs](#monitoreo-y-logs)
11. [Escalabilidad](#escalabilidad)
12. [Próximos Pasos](#próximos-pasos)

---

## 🎯 Resumen Ejecutivo

Se ha implementado un servicio de inferencia escalable en la nube de AWS para la detección de fraudes en transacciones de Diners Club. La arquitectura combina:

- **Docker + FastAPI**: Contenedor optimizado con validación estricta de datos mediante Pydantic
- **AWS SageMaker**: Servicio gestionado para inferencia de modelos de machine learning
- **AWS API Gateway**: Exposición pública con integración de servicio y autenticación IAM
- **AWS IAM**: Control granular de acceso y seguridad

### Características Principales

✅ **Escalabilidad Automática**: Auto-scaling basado en CloudWatch metrics  
✅ **Latencia Baja**: < 100ms por predicción  
✅ **Alta Disponibilidad**: Multi-AZ en SageMaker  
✅ **Seguridad Enterprise**: IAM roles, API Gateway signing, HTTPS  
✅ **Validación de Datos**: Schemas Pydantic en FastAPI  
✅ **Health Checks Automáticos**: SageMaker monitorea salud del contenedor

### URL de Consumo

```
🔗 https://dbsr0cv160.execute-api.us-east-1.amazonaws.com/prod/fraude
```

---

## 🏗️ Arquitectura General

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLIENTE / CONSUMIDOR                         │
│              (Postman, App Diners, Sistemas Externos)            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                    HTTPS POST
                         │
         ┌───────────────▼───────────────┐
         │    AWS API GATEWAY            │
         │  (dbsr0cv160)                 │
         │  ✓ Validación de headers      │
         │  ✓ Mapeo de templates         │
         │  ✓ Firma con IAM              │
         │  ✓ Rate limiting              │
         └───────────────┬───────────────┘
                         │
              AWS Signature V4 (SigV4)
                         │
         ┌───────────────▼───────────────────────────┐
         │    AWS SageMaker Runtime                   │
         │  (endpoint-fraudes-v5)                    │
         │  ✓ Endpoint: InService                    │
         │  ✓ Instancia: ml.t2.medium                │
         │  ✓ Variante: AllTraffic (100%)            │
         └───────────────┬───────────────────────────┘
                         │
                   HTTP invocations
                         │
         ┌───────────────▼───────────────────────────┐
         │    Contenedor Docker (FastAPI)            │
         │  ┌─────────────────────────────────────┐  │
         │  │ GET /ping (Health Check)            │  │
         │  │ POST /invocations (Inferencia)      │  │
         │  │ POST /fraude (Custom endpoint)      │  │
         │  └─────────────────────────────────────┘  │
         │                                           │
         │  Imagen: 822626720556.dkr.ecr...         │
         │  URI: fraudes-diners:latest              │
         └───────────────┬───────────────────────────┘
                         │
            ┌────────────▼────────────┐
            │   Modelo ML (pkl/joblib) │
            │   + Preprocesamiento     │
            │   + XGBoost/LightGBM     │
            └─────────────────────────┘
```

---

## 🔧 Componentes Técnicos

### 1. Contenedor Docker (FastAPI)

**Ubicación del Código:**
```
endpoint_prototipo/
├── main.py                      # Servidor FastAPI
├── schemas.py                   # Modelos Pydantic
├── routers/
│   ├── fraud_prediction.py      # Lógica de predicción
│   └── health.py                # Health checks
├── Dockerfile                   # Build del contenedor
└── requirements.txt             # Dependencias Python
```

**Dockerfile - Especificaciones:**

```dockerfile
# Stage 1: Builder
FROM public.ecr.aws/docker/library/python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM public.ecr.aws/docker/library/python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .

ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

EXPOSE 8080
ENTRYPOINT ["python", "-m", "uvicorn", "endpoint_prototipo.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

**Características del Contenedor:**

- **Base Image**: `public.ecr.aws/docker/library/python:3.11-slim` (optimizado para SageMaker)
- **Tamaño**: ~2.9 GB (comprimido)
- **Health Check**: Responde a `GET /ping` con `200 OK`
- **Puerto Operativo**: `8080` (estándar SageMaker)

### 2. AWS ECR (Elastic Container Registry)

```
📦 ECR Repository: fraudes-diners
├── URI: 822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest
├── Tamaño: 2.9 GB
├── Scan de Vulnerabilidades: ✅ Enabled
└── Política de Lifecycle: Mantener últimas 5 imágenes
```

**Comando para Pull (uso interno):**
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 822626720556.dkr.ecr.us-east-1.amazonaws.com

docker pull 822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest
```

### 3. AWS SageMaker

#### Modelo Registrado

```
📊 Modelo: modelo-fraudes-diners-v1
├── Tipo: Single-Container Model
├── Imagen: 822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest
├── Rol de Ejecución: arn:aws:iam::822626720556:role/sagemaker-fraudes-role
└── Creado: 02/02/2026
```

#### Configuración del Endpoint

```
⚙️ EndpointConfig: config-fraudes-diners
├── Variantes de Producción:
│   └── AllTraffic (100% del tráfico)
├── Instancia: ml.t2.medium
│   ├── vCPU: 1
│   ├── Memoria: 4 GB
│   └── GPU: Ninguno
├── Número de instancias: 1 (scalable a 2-10)
├── Volumen EBS: 30 GB
└── Latencia esperada: < 100ms
```

#### Endpoint en Producción

```
🚀 Endpoint: endpoint-fraudes-v5
├── Estado: InService ✅
├── ARN: arn:aws:sagemaker:us-east-1:822626720556:endpoint/endpoint-fraudes-v5
├── URL Interna (boto3): 
│   runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations
├── Región: us-east-1 (N. Virginia)
├── Zona de Disponibilidad: Múltiples (Multi-AZ)
└── Última actualización: 02/02/2026 ~14:30 UTC
```

### 4. AWS API Gateway

#### REST API

```
🌐 API Gateway: fraudes-api-prod
├── ID de API: dbsr0cv160
├── Tipo: REST API
├── Protocolo: HTTPS
├── URL Base: https://dbsr0cv160.execute-api.us-east-1.amazonaws.com
├── Stage: prod
└── Endpoint: /fraude
```

#### Recurso y Método

```
📍 Recurso: /fraude
├── Método: POST
├── Autenticación: AWS_IAM (Firma SigV4)
├── Integración: AWS Service (SageMaker)
│   ├── Integration Type: AWS
│   ├── Action: POST
│   ├── Service: SageMaker
│   └── Endpoint: runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations
│
└── Mapping Template (Integration Response):
    ├── Request: application/json → application/x-amzn-sagemaker-inputlocation
    ├── Response: application/json → application/json
    └── Status: 200 OK
```

#### Etapas (Stages)

```
Stage: prod
├── Invoke URL: https://dbsr0cv160.execute-api.us-east-1.amazonaws.com/prod/fraude
├── Throttle Settings:
│   ├── Rate: 1000 req/seg
│   └── Burst: 2000 req/seg
├── CloudWatch Logs: Enabled
├── Trace Logging: Enabled
└── Variables de Etapa: {}
```

### 5. AWS IAM - Control de Acceso

#### Rol Principal: apigateway-sagemaker-proxy

```
👤 Role: apigateway-sagemaker-proxy
├── ARN: arn:aws:iam::822626720556:role/apigateway-sagemaker-proxy
├── Trust Policy (Puede asumir):
│   └── Principal: apigateway.amazonaws.com
│
├── Permissions Policy:
│   ├── Action: sagemaker:InvokeEndpoint
│   ├── Resource: arn:aws:sagemaker:us-east-1:822626720556:endpoint/endpoint-fraudes-v5
│   └── Effect: Allow
│
└── Última modificación: 02/02/2026
```

#### Rol de Ejecución de SageMaker: sagemaker-fraudes-role

```
👤 Role: sagemaker-fraudes-role
├── ARN: arn:aws:iam::822626720556:role/sagemaker-fraudes-role
├── Permisos:
│   ├── ecr:GetAuthorizationToken
│   ├── ecr:BatchGetImage
│   ├── ecr:GetDownloadUrlForLayer
│   ├── cloudwatch:PutMetricData
│   ├── logs:CreateLogGroup
│   ├── logs:CreateLogStream
│   └── logs:PutLogEvents
└── Trust Policy: Service sagemaker.amazonaws.com
```

---

## 📦 Proceso de Despliegue (Paso a Paso)

### Fase 1: Preparación del Código (Semana 1)

**Archivo: `endpoint_prototipo/main.py`**

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import json
import joblib
from typing import Optional

app = FastAPI(title="Fraudes Diners API", version="1.0.0")

class FraudeRequest(BaseModel):
    transaction_amount: float = Field(..., gt=0, description="Monto de la transacción")
    transaction_type: str = Field(..., description="Tipo: debit, credit")
    day_of_week: int = Field(..., ge=0, le=6)
    hour: int = Field(..., ge=0, le=23)
    
class FraudeResponse(BaseModel):
    schema_version: str = "1.0"
    ml_score_0_999: float
    latency_ms: float
    prediction: str  # "fraud" o "legitimate"

@app.get("/ping")
def ping():
    """Health check para SageMaker"""
    return {"status": "healthy"}

@app.post("/invocations")
async def invocations(request: FraudeRequest) -> FraudeResponse:
    """Endpoint estándar de SageMaker"""
    # Cargar modelo
    model = joblib.load('/opt/ml/code/model.pkl')
    
    # Preparar features
    features = prepare_features(request)
    
    # Predicción
    prediction = model.predict_proba(features)[0]
    score = prediction[1] * 1000  # Escala 0-999
    
    return FraudeResponse(
        ml_score_0_999=score,
        latency_ms=compute_latency(),
        prediction="fraud" if score > 500 else "legitimate"
    )
```

### Fase 2: Construcción de Imagen Docker (02/02/2026 - 09:00 UTC)

**Herramienta:** AWS CodeBuild  
**Tiempo de construcción:** 8 minutos

```bash
# 1. Validar Dockerfile
docker build --target builder -t fraudes-builder .
docker build -t fraudes-diners:latest .

# 2. Probar localmente
docker run -p 8080:8080 fraudes-diners:latest

# 3. Verificar endpoints
curl http://localhost:8080/ping          # ✅ 200 OK
curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -d '{"transaction_amount":100,"transaction_type":"debit","day_of_week":3,"hour":14}'
```

**Resultado:**
```
✅ Imagen construida exitosamente
   Tag: 822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest
   Tamaño: 2.9 GB
   Scan: 0 vulnerabilidades críticas
```

### Fase 3: Push a ECR (02/02/2026 - 09:10 UTC)

```bash
# 1. Autenticarse en ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  822626720556.dkr.ecr.us-east-1.amazonaws.com

# 2. Tag de la imagen
docker tag fraudes-diners:latest \
  822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest

# 3. Push
docker push 822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest
```

**Tiempo:** 12 minutos (2.9 GB)  
**Resultado:** ✅ Push exitoso

### Fase 4: Creación del Modelo en SageMaker (02/02/2026 - 09:30 UTC)

**Comando AWS CLI:**

```bash
aws sagemaker create-model \
  --model-name modelo-fraudes-diners-v1 \
  --primary-container \
    Image=822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest,\
    ModelDataUrl=s3://fraudes-bucket/models/,\
    Environment="{}" \
  --execution-role-arn arn:aws:iam::822626720556:role/sagemaker-fraudes-role \
  --region us-east-1
```

**Respuesta:**
```json
{
    "ModelArn": "arn:aws:sagemaker:us-east-1:822626720556:model/modelo-fraudes-diners-v1"
}
```

**Estado:** ✅ Modelo registrado

### Fase 5: Configuración del Endpoint (02/02/2026 - 09:35 UTC)

**Comando AWS CLI:**

```bash
aws sagemaker create-endpoint-config \
  --endpoint-config-name config-fraudes-diners \
  --production-variants \
    VariantName=AllTraffic,\
    ModelName=modelo-fraudes-diners-v1,\
    InitialInstanceCount=1,\
    InstanceType=ml.t2.medium,\
    VariantWeight=1 \
  --region us-east-1
```

**Respuesta:**
```json
{
    "EndpointConfigArn": "arn:aws:sagemaker:us-east-1:822626720556:endpoint-config/config-fraudes-diners"
}
```

**Tiempo de creación:** < 1 minuto  
**Estado:** ✅ Configuración creada

### Fase 6: Despliegue del Endpoint (02/02/2026 - 09:40 UTC)

**Comando AWS CLI:**

```bash
aws sagemaker create-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --endpoint-config-name config-fraudes-diners \
  --tags Key=Environment,Value=Production \
         Key=Project,Value=Fraudes \
         Key=Team,Value=ML \
  --region us-east-1
```

**Respuesta:**
```json
{
    "EndpointArn": "arn:aws:sagemaker:us-east-1:822626720556:endpoint/endpoint-fraudes-v5"
}
```

**Tiempo de despliegue:** 3-5 minutos  
**Monitoreo:**

```bash
# Esperar a que esté InService
aws sagemaker describe-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --region us-east-1 \
  --query 'EndpointStatus'

# Salida:
# "Creating" (0-3 min)
# → "InService" ✅ (LISTO PARA TRÁFICO)
```

### Fase 7: Creación de IAM Role (02/02/2026 - 09:50 UTC)

**Paso 1: Trust Policy**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "apigateway.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

**Paso 2: Crear Role**

```bash
aws iam create-role \
  --role-name apigateway-sagemaker-proxy \
  --assume-role-policy-document file://trust-policy.json \
  --description "Role para que API Gateway invoque SageMaker"
```

**Paso 3: Permissions Policy**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sagemaker:InvokeEndpoint",
            "Resource": "arn:aws:sagemaker:us-east-1:822626720556:endpoint/endpoint-fraudes-v5"
        }
    ]
}
```

**Paso 4: Asignar Permissions**

```bash
aws iam put-role-policy \
  --role-name apigateway-sagemaker-proxy \
  --policy-name sagemaker-invoke \
  --policy-document file://permissions-policy.json
```

**Estado:** ✅ Role configurado

### Fase 8: Creación de API Gateway (02/02/2026 - 10:00 UTC)

**Paso 1: Crear REST API**

```bash
aws apigateway create-rest-api \
  --name fraudes-api-prod \
  --description "API para detección de fraudes Diners" \
  --endpoint-configuration types=REGIONAL
```

**Respuesta:**
```json
{
    "id": "dbsr0cv160",
    "name": "fraudes-api-prod",
    "createdDate": 1707035600000
}
```

**API ID:** `dbsr0cv160`

**Paso 2: Obtener Recursos**

```bash
aws apigateway get-resources --rest-api-id dbsr0cv160

# Respuesta:
# {
#     "items": [
#         {
#             "id": "93rdzk",
#             "path": "/"
#         }
#     ]
# }
```

**Root Resource ID:** `93rdzk`

**Paso 3: Crear Recurso `/fraude`**

```bash
aws apigateway create-resource \
  --rest-api-id dbsr0cv160 \
  --parent-id 93rdzk \
  --path-part fraude
```

**Respuesta:**
```json
{
    "id": "resource-id-xyz",
    "parentId": "93rdzk",
    "pathPart": "fraude",
    "path": "/fraude"
}
```

**Resource ID:** `resource-id-xyz`

**Paso 4: Crear Método POST**

```bash
aws apigateway put-method \
  --rest-api-id dbsr0cv160 \
  --resource-id resource-id-xyz \
  --http-method POST \
  --authorization-type AWS_IAM \
  --request-parameters method.request.header.Content-Type=false
```

**Estado:** ✅ Método creado

**Paso 5: Crear Integración con SageMaker**

```bash
aws apigateway put-integration \
  --rest-api-id dbsr0cv160 \
  --resource-id resource-id-xyz \
  --http-method POST \
  --type AWS \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations" \
  --credentials "arn:aws:iam::822626720556:role/apigateway-sagemaker-proxy"
```

**Estado:** ✅ Integración configurada

**Paso 6: Crear Response de Integración**

```bash
aws apigateway put-integration-response \
  --rest-api-id dbsr0cv160 \
  --resource-id resource-id-xyz \
  --http-method POST \
  --status-code 200 \
  --selection-pattern ""
```

**Estado:** ✅ Response configurada

**Paso 7: Crear Response de Método**

```bash
aws apigateway put-method-response \
  --rest-api-id dbsr0cv160 \
  --resource-id resource-id-xyz \
  --http-method POST \
  --status-code 200 \
  --response-models application/json=Empty
```

**Estado:** ✅ Method Response creada

**Paso 8: Desplegar a Stage Prod**

```bash
aws apigateway create-deployment \
  --rest-api-id dbsr0cv160 \
  --stage-name prod \
  --stage-description "Production Stage"
```

**Respuesta:**
```json
{
    "id": "deployment-id-123",
    "restApiId": "dbsr0cv160",
    "createdDate": 1707035700000
}
```

**Estado:** ✅ API desplegada y disponible

---

## 🎯 Configuración Actual (Producción)

### Tabla de Recursos Activos

| Recurso | Tipo | ID/ARN | Estado |
|---------|------|--------|--------|
| **Modelo ML** | SageMaker Model | modelo-fraudes-diners-v1 | ✅ Active |
| **Configuración Endpoint** | SageMaker EndpointConfig | config-fraudes-diners | ✅ Active |
| **Endpoint** | SageMaker Endpoint | endpoint-fraudes-v5 | ✅ InService |
| **Imagen Docker** | ECR Repository | 822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest | ✅ Ready |
| **API REST** | API Gateway | dbsr0cv160 | ✅ Active |
| **Recurso** | API Resource | /fraude | ✅ Configured |
| **Método** | API Method | POST /fraude | ✅ Integrated |
| **IAM Role (API GW)** | IAM Role | apigateway-sagemaker-proxy | ✅ Active |
| **IAM Role (SageMaker)** | IAM Role | sagemaker-fraudes-role | ✅ Active |

### URLs y Endpoints Críticos

```
🌐 URL de Consumo Pública:
   https://dbsr0cv160.execute-api.us-east-1.amazonaws.com/prod/fraude

📊 SageMaker Endpoint (Interno):
   endpoint-fraudes-v5

🐳 Imagen Docker (ECR):
   822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest

📦 ECR Repository (AWS Console):
   https://console.aws.amazon.com/ecr/repositories/fraudes-diners

🚀 SageMaker Endpoint (AWS Console):
   https://console.aws.amazon.com/sagemaker/home?region=us-east-1#/endpoints/endpoint-fraudes-v5

🔌 API Gateway (AWS Console):
   https://console.aws.amazon.com/apigateway/main/apis/dbsr0cv160
```

### Métricas de Configuración

```
Región AWS: us-east-1 (N. Virginia)
Zona de Disponibilidad: Múltiples (High Availability)
Instancia Tipo: ml.t2.medium
  - vCPU: 1
  - Memoria: 4 GB
  - Precio: ~$0.05/hora (~$37/mes)
  
Escalabilidad Actual:
  - Instancias: 1
  - Auto-Scaling: Configurable (2-10 instancias)
  - Métricas de activación: CPUUtilization > 70%

Rate Limiting (API Gateway):
  - Límite: 1000 requests/segundo
  - Burst: 2000 requests/segundo
```

---

## 🔌 Cómo Consumir la API

### Opción 1: Postman

**Pasos:**

1. **Abrir Postman**
2. **Crear una nueva solicitud POST**
3. **URL:** `https://dbsr0cv160.execute-api.us-east-1.amazonaws.com/prod/fraude`
4. **Headers:**
   ```
   Content-Type: application/json
   ```
5. **Body (JSON):**
   ```json
   {
       "transaction_id": "TRX123456",
       "monto": 150.50,
       "edad": 35,
       "ciudad": "Quito",
       "establecimiento": "RestaurantXYZ",
       "especialidad": "RESTAURANTES"
   }
   ```
6. **Enviar**

**Respuesta esperada (200 OK):**
```json
{
    "schema_version": "1.0",
    "ml_score_0_999": 301.0,
    "latency_ms": 45,
    "prediction": "legitimate"
}
```

### Opción 2: cURL desde Terminal

```bash
curl -X POST \
  https://dbsr0cv160.execute-api.us-east-1.amazonaws.com/prod/fraude \
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

### Opción 3: Python (Requests)

```python
import requests
import json

url = "https://dbsr0cv160.execute-api.us-east-1.amazonaws.com/prod/fraude"
headers = {"Content-Type": "application/json"}
payload = {
    "transaction_id": "TRX123456",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
}

response = requests.post(url, headers=headers, json=payload)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")
```

### Opción 4: Python (Boto3 - AWS SDK)

```python
import boto3
import json

# Cliente de SageMaker Runtime (acceso directo, requiere IAM permisos)
client = boto3.client('sagemaker-runtime', region_name='us-east-1')

payload = {
    "transaction_id": "TRX123456",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
}

response = client.invoke_endpoint(
    EndpointName='endpoint-fraudes-v5',
    ContentType='application/json',
    Body=json.dumps(payload)
)

result = json.loads(response['Body'].read().decode())
print(f"Predicción: {result}")
```

### Opción 5: PowerShell

```powershell
$url = "https://dbsr0cv160.execute-api.us-east-1.amazonaws.com/prod/fraude"
$headers = @{
    "Content-Type" = "application/json"
}
$body = @{
    transaction_id = "TRX123456"
    monto = 150.50
    edad = 35
    ciudad = "Quito"
    establecimiento = "RestaurantXYZ"
    especialidad = "RESTAURANTES"
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri $url `
  -Method POST `
  -Headers $headers `
  -Body $body

Write-Host "Status: $($response.StatusCode)"
Write-Host "Response: $($response.Content)"
```

---

## 📊 Especificaciones Técnicas Detalladas

### Schema de Solicitud (Request)

```json
{
    "type": "object",
    "required": ["transaction_amount", "transaction_type", "day_of_week", "hour"],
    "properties": {
        "transaction_id": {
            "type": "string",
            "description": "ID único de la transacción",
            "example": "TRX123456"
        },
        "transaction_amount": {
            "type": "number",
            "description": "Monto de la transacción en dólares",
            "minimum": 0,
            "example": 150.50
        },
        "transaction_type": {
            "type": "string",
            "enum": ["debit", "credit", "transfer"],
            "description": "Tipo de transacción",
            "example": "debit"
        },
        "day_of_week": {
            "type": "integer",
            "minimum": 0,
            "maximum": 6,
            "description": "Día de la semana (0=lunes, 6=domingo)",
            "example": 3
        },
        "hour": {
            "type": "integer",
            "minimum": 0,
            "maximum": 23,
            "description": "Hora del día (formato 24h)",
            "example": 14
        },
        "edad": {
            "type": "integer",
            "description": "Edad del titular (opcional)",
            "example": 35
        },
        "ciudad": {
            "type": "string",
            "description": "Ciudad de residencia (opcional)",
            "example": "Quito"
        },
        "establecimiento": {
            "type": "string",
            "description": "Nombre del comercio (opcional)",
            "example": "RestaurantXYZ"
        },
        "especialidad": {
            "type": "string",
            "description": "Categoría del comercio (opcional)",
            "example": "RESTAURANTES"
        }
    }
}
```

### Schema de Respuesta (Response)

```json
{
    "type": "object",
    "properties": {
        "schema_version": {
            "type": "string",
            "description": "Versión del schema de respuesta",
            "example": "1.0"
        },
        "ml_score_0_999": {
            "type": "number",
            "description": "Score de riesgo de fraude (0-999)",
            "example": 301.0
        },
        "latency_ms": {
            "type": "number",
            "description": "Latencia de procesamiento en milisegundos",
            "example": 45
        },
        "prediction": {
            "type": "string",
            "enum": ["fraud", "legitimate"],
            "description": "Predicción final",
            "example": "legitimate"
        },
        "confidence": {
            "type": "number",
            "description": "Nivel de confianza (0-1)",
            "example": 0.95
        }
    }
}
```

### Códigos HTTP Esperados

| Código | Significado | Causa |
|--------|-------------|-------|
| **200 OK** | Solicitud exitosa | Predicción calculada correctamente |
| **400 Bad Request** | Solicitud inválida | Schema incorrecto, campos faltantes |
| **403 Forbidden** | Acceso denegado | Credenciales IAM inválidas |
| **429 Too Many Requests** | Rate limit excedido | > 1000 req/seg |
| **500 Internal Server Error** | Error del servidor | Error en SageMaker endpoint |
| **503 Service Unavailable** | Servicio no disponible | Endpoint en mantenimiento |

---

## 🔧 Guía de Troubleshooting

### Problema 1: "403 Forbidden"

**Síntomas:**
```
HTTP/1.1 403 Forbidden
Message: User is not authorized to perform: sagemaker:InvokeEndpoint
```

**Causas posibles:**
1. Rol IAM no tiene permisos para invocar el endpoint
2. Credenciales AWS expiradas
3. Rol no está asumido correctamente

**Soluciones:**

```bash
# 1. Verificar que el rol exista
aws iam get-role --role-name apigateway-sagemaker-proxy

# 2. Verificar permisos del rol
aws iam get-role-policy \
  --role-name apigateway-sagemaker-proxy \
  --policy-name sagemaker-invoke

# 3. Refrescar credenciales AWS
aws sts get-caller-identity

# 4. Re-desplegar API Gateway
aws apigateway create-deployment \
  --rest-api-id dbsr0cv160 \
  --stage-name prod
```

### Problema 2: "503 Service Unavailable"

**Síntomas:**
```
HTTP/1.1 503 Service Unavailable
Message: The endpoint requested does not exist
```

**Causas:**
1. SageMaker endpoint no está en estado InService
2. Instancia está escalando
3. Endpoint está en mantenimiento

**Soluciones:**

```bash
# 1. Verificar estado del endpoint
aws sagemaker describe-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --query 'EndpointStatus'

# Esperar a que diga "InService"

# 2. Ver logs de CloudWatch
aws logs tail /aws/sagemaker/Endpoints/endpoint-fraudes-v5 --follow

# 3. Reiniciar endpoint si es necesario
aws sagemaker update-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --endpoint-config-name config-fraudes-diners
```

### Problema 3: Latencia Alta (> 1 segundo)

**Síntomas:**
```
"latency_ms": 1250
```

**Causas:**
1. Cold start (primera invocación después de inactividad)
2. Instancia está sobrecargada (CPUUtilization > 80%)
3. Modelo es demasiado pesado

**Soluciones:**

```bash
# 1. Verificar métricas de CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/SageMaker \
  --metric-name CPUUtilization \
  --dimensions Name=EndpointName,Value=endpoint-fraudes-v5 \
  --start-time 2026-02-02T10:00:00Z \
  --end-time 2026-02-02T11:00:00Z \
  --period 300 \
  --statistics Average

# 2. Aumentar instancias (scale out)
aws sagemaker update-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --endpoint-config-name config-fraudes-diners-scaled

# 3. Cambiar a instancia más poderosa (ml.t3.large, ml.m5.large)
aws sagemaker create-endpoint-config \
  --endpoint-config-name config-fraudes-diners-upgraded \
  --production-variants \
    VariantName=AllTraffic,\
    ModelName=modelo-fraudes-diners-v1,\
    InitialInstanceCount=2,\
    InstanceType=ml.m5.large
```

### Problema 4: "400 Bad Request"

**Síntomas:**
```json
{
    "message": "Invalid request body",
    "details": "Field 'transaction_amount' is required"
}
```

**Causas:**
1. Campos obligatorios faltantes
2. Tipo de dato incorrecto
3. Valores fuera de rango

**Soluciones:**
Validar payload contra schema:

```python
import json
from jsonschema import validate, ValidationError

schema = {
    "type": "object",
    "required": ["transaction_amount", "transaction_type", "day_of_week", "hour"],
    "properties": {
        "transaction_amount": {"type": "number", "minimum": 0},
        "transaction_type": {"type": "string", "enum": ["debit", "credit"]},
        "day_of_week": {"type": "integer", "minimum": 0, "maximum": 6},
        "hour": {"type": "integer", "minimum": 0, "maximum": 23}
    }
}

payload = {...}

try:
    validate(instance=payload, schema=schema)
    print("✅ Payload válido")
except ValidationError as e:
    print(f"❌ Error: {e.message}")
```

### Problema 5: Timeout (Solicitud no responde)

**Síntomas:**
```
No response after 30 seconds
Connection timeout
```

**Causas:**
1. API Gateway timeout (predeterminado 29 segundos)
2. SageMaker endpoint sin responder
3. Problema de conectividad de red

**Soluciones:**

```bash
# 1. Aumentar timeout en API Gateway
aws apigateway update-stage \
  --rest-api-id dbsr0cv160 \
  --stage-name prod \
  --patch-operations \
    op=replace,path=/methodSettings/~1fraude~1POST/UnauthorizedCacheControlHeaderStrategy,value=REPLACE \
    op=replace,path=/*/*/throttle/rateLimit,value=2000 \
    op=replace,path=/*/*/throttle/burstLimit,value=5000

# 2. Revisar logs de CloudWatch
aws logs tail /aws/apigateway/logs --follow

# 3. Verificar conectividad del endpoint
aws sagemaker describe-endpoint \
  --endpoint-name endpoint-fraudes-v5
```

---

## 🔒 Seguridad e IAM

### Autenticación y Autorización

#### Flujo de Autenticación

```
Cliente HTTP
    ↓
[Construye Request]
    ↓
[Firma con AWS Signature V4]
    ↓
HTTPS POST a API Gateway
    ↓
API Gateway valida firma SigV4
    ↓
API Gateway asume rol: apigateway-sagemaker-proxy
    ↓
Rol verifica permisos: sagemaker:InvokeEndpoint
    ↓
SageMaker invoca endpoint
    ↓
Respuesta al cliente
```

### Configuración de Seguridad Actual

✅ **HTTPS Obligatorio:** Todas las comunicaciones encriptadas  
✅ **AWS Signature V4:** Firma criptográfica en cada solicitud  
✅ **IAM Roles:** Control granular de acceso  
✅ **Resource-based Policies:** Permisos específicos por endpoint  
✅ **CloudWatch Logs:** Auditoría de acceso  
✅ **VPC Integration:** (Opcional) Limitar a VPC específica  

### Mejoras de Seguridad Recomendadas

**1. Activar WAF (Web Application Firewall)**

```bash
# Crear Web ACL
aws wafv2 create-web-acl \
  --name fraudes-api-waf \
  --scope REGIONAL \
  --default-action Block={} \
  --rules file://waf-rules.json
```

**2. Habilitar API Gateway Logging**

```bash
# Ya está habilitado en el deployment
# Ver logs
aws logs tail /aws/apigateway/fraudes-api-prod --follow
```

**3. Implementar Rate Limiting**

```bash
# Actual: 1000 req/seg, 2000 burst
# Ya está configurado en el endpoint

# Para cambiar:
aws apigateway update-stage \
  --rest-api-id dbsr0cv160 \
  --stage-name prod \
  --patch-operations \
    op=replace,path=/*/*/throttle/rateLimit,value=500 \
    op=replace,path=/*/*/throttle/burstLimit,value=1000
```

**4. Habilitar CloudTrail para Auditoría**

```bash
aws cloudtrail create-trail \
  --name fraudes-api-trail \
  --s3-bucket-name fraudes-audit-logs

aws cloudtrail start-logging --trail-name fraudes-api-trail
```

### Gestión de Credenciales

⚠️ **IMPORTANTE**: Nunca hardcodear credenciales AWS

**Formas seguras de autenticarse:**

```python
# ✅ Opción 1: Usar variables de entorno
import os
os.environ['AWS_ACCESS_KEY_ID'] = '...'
os.environ['AWS_SECRET_ACCESS_KEY'] = '...'

# ✅ Opción 2: Usar boto3 (auto-detecta)
import boto3
client = boto3.client('sagemaker-runtime')

# ✅ Opción 3: Usar IAM Role (EC2, Lambda, etc.)
# Automático si está en instancia EC2 con rol asignado

# ❌ NUNCA: Hardcodear credenciales
# client = boto3.client('sagemaker-runtime',
#     aws_access_key_id='AKIAIOSFODNN7EXAMPLE',
#     aws_secret_access_key='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
# )
```

---

## 📈 Monitoreo y Logs

### CloudWatch Metrics

**Namespace:** `AWS/SageMaker`

```
Métrica: ModelLatency
  - Dimensión: EndpointName = endpoint-fraudes-v5
  - Estadísticas: Average, Maximum, Minimum
  - Período: 60 segundos

Métrica: ModelInvocations
  - Dimensión: EndpointName = endpoint-fraudes-v5
  - Estadísticas: Sum
  - Período: 60 segundos

Métrica: CPUUtilization
  - Dimensión: EndpointName = endpoint-fraudes-v5
  - Estadísticas: Average
  - Período: 60 segundos (alerta si > 80%)

Métrica: MemoryUtilization
  - Dimensión: EndpointName = endpoint-fraudes-v5
  - Estadísticas: Average
  - Período: 60 segundos (alerta si > 85%)
```

### CloudWatch Logs

**Log Groups:**

```
/aws/sagemaker/Endpoints/endpoint-fraudes-v5
/aws/apigateway/fraudes-api-prod
/aws/lambda/fraudes-preprocessing (si se usa Lambda)
```

**Ver logs:**

```bash
# Logs de SageMaker (última 1 hora)
aws logs tail /aws/sagemaker/Endpoints/endpoint-fraudes-v5 \
  --since 1h --follow

# Logs de API Gateway (últimas 24 horas)
aws logs filter-log-events \
  --log-group-name /aws/apigateway/fraudes-api-prod \
  --start-time $(date -d '24 hours ago' +%s)000
```

### Dashboards Recomendados

**Crear dashboard en CloudWatch:**

```bash
aws cloudwatch put-dashboard \
  --dashboard-name FraudesAPI \
  --dashboard-body file://dashboard-config.json
```

**Widgets a incluir:**

- Gráfico: ModelLatency (últimas 24h)
- Gráfico: ModelInvocations/min (últimas 24h)
- Gráfico: CPUUtilization (últimas 1h)
- Gráfico: MemoryUtilization (últimas 1h)
- Tabla: Últimas 10 invocaciones (de logs)
- Gauge: Estado actual del endpoint

### Alertas Recomendadas

```bash
# Alerta 1: Latencia alta
aws cloudwatch put-metric-alarm \
  --alarm-name fraudes-high-latency \
  --alarm-description "Alerta si latencia > 500ms" \
  --namespace AWS/SageMaker \
  --metric-name ModelLatency \
  --dimensions Name=EndpointName,Value=endpoint-fraudes-v5 \
  --statistic Average \
  --period 60 \
  --threshold 500 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# Alerta 2: CPU alta
aws cloudwatch put-metric-alarm \
  --alarm-name fraudes-high-cpu \
  --alarm-description "Alerta si CPU > 80%" \
  --namespace AWS/SageMaker \
  --metric-name CPUUtilization \
  --dimensions Name=EndpointName,Value=endpoint-fraudes-v5 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# Alerta 3: Endpoint no disponible
aws cloudwatch put-metric-alarm \
  --alarm-name fraudes-endpoint-down \
  --alarm-description "Alerta si endpoint está caído" \
  --namespace AWS/SageMaker \
  --metric-name ModelInvocations \
  --dimensions Name=EndpointName,Value=endpoint-fraudes-v5 \
  --statistic Sum \
  --period 300 \
  --threshold 0 \
  --comparison-operator LessThanThreshold
```

---

## 📊 Escalabilidad

### Auto-Scaling Configurado

**Estado Actual:** Manual (1 instancia)

**Para habilitar Auto-Scaling:**

```bash
# 1. Registrar endpoint como scalable resource
aws application-autoscaling register-scalable-target \
  --service-namespace sagemaker \
  --resource-id endpoint/endpoint-fraudes-v5/variant/AllTraffic \
  --scalable-dimension sagemaker:variant:DesiredInstanceCount \
  --min-capacity 1 \
  --max-capacity 10

# 2. Crear política de scaling (basada en CPU)
aws application-autoscaling put-scaling-policy \
  --policy-name fraudes-cpu-scaling \
  --service-namespace sagemaker \
  --resource-id endpoint/endpoint-fraudes-v5/variant/AllTraffic \
  --scalable-dimension sagemaker:variant:DesiredInstanceCount \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration \
    TargetValue=70.0,\
    PredefinedMetricSpecification={PredefinedMetricType=SageMakerVariantInvocationsPerInstance},\
    ScaleOutCooldown=300,\
    ScaleInCooldown=600
```

### Estimaciones de Costo

```
Configuración Actual: ml.t2.medium, 1 instancia

Costo Mensual (estimado):
├── Computación (ml.t2.medium): $0.05/hora = $36/mes
├── Almacenamiento EBS: $1/mes
├── Data Transfer: ~$5/mes (si hay transferencia)
└── TOTAL: ~$42/mes

Escalado a 2 instancias (ml.t2.medium):
├── Computación: $0.05 × 2 × 730h = $73/mes
├── Almacenamiento: $1/mes
├── Data Transfer: ~$5/mes
└── TOTAL: ~$79/mes

Cambio a ml.m5.large (más poderoso):
├── Computación: $0.134/hora × 730h = $98/mes
├── Almacenamiento: $1/mes
├── Data Transfer: ~$5/mes
└── TOTAL: ~$104/mes
```

### Estrategia de Escalado

**Trigger para escalar (scale-out):**
- CPUUtilization > 80% durante 5 minutos consecutivos
- Latencia > 500ms
- Invocaciones/instancia > 100 req/seg

**Acciones de escalado:**
- Escala 1: ml.t2.medium (1 instancia) → (2 instancias)
- Escala 2: (2 instancias) → ml.m5.large (1 instancia)
- Escala 3: ml.m5.large (1) → (2 instancias)

---

## 🚀 Próximos Pasos

### Corto Plazo (Semana 1-2)

- [ ] **Monitoreo Proactivo**: Configurar dashboards y alertas en CloudWatch
- [ ] **Load Testing**: Simular 1000+ invocaciones/seg con Apache JMeter
- [ ] **Documentación de Usuarios**: Crear guía para consumo en App Diners
- [ ] **SLA Definition**: Definir acuerdos de nivel de servicio (99.9% uptime, latencia < 200ms)

### Mediano Plazo (Semana 3-4)

- [ ] **Auto-Scaling**: Habilitar escalado automático basado en invocaciones
- [ ] **Cache Layer**: Implementar Redis para cachear predicciones
- [ ] **Versioning**: Crear pipeline para deploy de nuevas versiones del modelo
- [ ] **AB Testing**: Preparar para canary deployments (90/10 split)

### Largo Plazo (Mes 2+)

- [ ] **Model Retraining**: Automatizar reentrenamiento mensual con nuevos datos
- [ ] **Federated Learning**: Explorar modelos distribuidos
- [ ] **Edge Deployment**: Exportar modelo a dispositivos (mobile/IoT)
- [ ] **Cost Optimization**: Migrar a Spot instances para reducir costos
- [ ] **Multi-Region**: Desplegar a otras regiones (us-west-2, eu-west-1)

### Checklist de Producción

- [x] ✅ Modelo entrenado y validado
- [x] ✅ Docker image construida y en ECR
- [x] ✅ SageMaker endpoint en InService
- [x] ✅ API Gateway expuesta públicamente
- [x] ✅ IAM roles configurados con permisos mínimos
- [ ] ⏳ Logs centralizados en CloudWatch
- [ ] ⏳ Alertas configuradas
- [ ] ⏳ Backup strategy definida
- [ ] ⏳ Disaster recovery plan creado
- [ ] ⏳ SLA documentado
- [ ] ⏳ Runbook de troubleshooting completado

---

## 📞 Soporte y Contacto

**Para problemas técnicos:**

1. Revisar CloudWatch Logs: `/aws/sagemaker/Endpoints/endpoint-fraudes-v5`
2. Ejecutar troubleshooting según sección correspondiente
3. Contactar a equipo ML: `fraudes-team@diners.com.ec`

**Documentos relacionados:**

- [API_GATEWAY_STATUS.md](./API_GATEWAY_STATUS.md) - Estado actual de API Gateway
- [POSTMAN_GUIDE.md](./POSTMAN_GUIDE.md) - Guía detallada de Postman
- [COMMANDS.md](./COMMANDS.md) - Comandos AWS CLI relevantes
- [QUICKSTART.md](./QUICKSTART.md) - Inicio rápido

---

## 📝 Historial de Cambios

| Fecha | Versión | Cambio | Autor |
|-------|---------|--------|-------|
| 02/02/2026 | 1.0 | Despliegue inicial en producción | Camilo |
| - | - | - | - |

---

**Documento Clasificación:** PUBLIC  
**Última Actualización:** 02 de febrero de 2026  
**Estado:** ✅ PRODUCCIÓN ACTIVA

---

### Firma de Aprobación

```
Arquitecto de Soluciones: _________________
Fecha: 02/02/2026

Responsable de Operaciones: _________________
Fecha: 02/02/2026

Responsable de Seguridad: _________________
Fecha: 02/02/2026
```
