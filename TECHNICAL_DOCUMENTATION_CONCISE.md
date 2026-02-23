# 📚 DOCUMENTACIÓN TÉCNICA - Fraudes Diners

**Versión:** 2024.11 | **Fecha:** Febrero 2026 | **Autor:** Data Science Team

---

## 📖 Tabla de Contenidos

1. [Visión General](#1-visión-general)
2. [Arquitectura del Sistema](#2-arquitectura-del-sistema)
3. [Componentes Principales](#3-componentes-principales)
4. [Stack Tecnológico](#4-stack-tecnológico)
5. [Flujo de Una Predicción](#5-flujo-de-una-predicción)
6. [API REST Endpoints](#6-api-rest-endpoints)
7. [Infraestructura Cloud](#7-infraestructura-cloud)
8. [Pipelines ML](#8-pipelines-ml)
9. [Despliegue](#9-despliegue)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Visión General

### Propósito
**Fraudes Diners** es un sistema de **detección de fraudes en tiempo real** que clasifica transacciones como fraudulentas o legítimas usando Machine Learning.

### Requisitos Clave
- ✅ Procesar transacciones en **<100ms** (P95: <150ms)
- ✅ Puntuaciones de riesgo **0-999** (0=legítimo, 999=fraude)
- ✅ **Auto-escalable** según carga
- ✅ Auditabilidad completa (request ID únicos)
- ✅ 99.9% uptime (máx 43 min downtime/mes)

### Stack Principal
| Componente | Tecnología |
|-----------|-----------|
| API | FastAPI 0.104.1 |
| ML | scikit-learn / XGBoost / LightGBM |
| Contenedor | Docker 24.0+ |
| Orquestación | AWS SageMaker |
| Infraestructura | CloudFormation (YAML) |
| Logging | AWS CloudWatch |
| Python | 3.11+ |

---

## 2. Arquitectura del Sistema

```
┌─────────────────────────────────────────────────┐
│          CLIENTE (Sistemas Diners)              │
└────────────────┬────────────────────────────────┘
                 │ HTTPS POST
                 ▼
┌─────────────────────────────────────────────────┐
│   AWS API Gateway (/fraud/predict)              │
│   https://{api-id}.execute-api.us-east-1...    │
└────────────────┬────────────────────────────────┘
                 │ Integration
                 ▼
┌─────────────────────────────────────────────────┐
│   AWS SageMaker Endpoint                        │
│   endpoint-fraudes-{stack} (ml.m5.large)       │
└────────────────┬────────────────────────────────┘
                 │ /invocations
                 ▼
┌─────────────────────────────────────────────────┐
│   Docker Container (FastAPI)                    │
│   Port 8080 → Fraud Detection Model            │
├─────────────────────────────────────────────────┤
│ • Health Checks (/health, /ping)               │
│ • Fraud Predictions (/fraud/predict)           │
│ • Batch Processing (/fraud/batch-predict)      │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│   AWS CloudWatch (Logs & Metrics)              │
└─────────────────────────────────────────────────┘
```

### Flujo de Componentes

```
Entrada de Cliente
    ↓
API Gateway (validación, rate-limiting)
    ↓
SageMaker Runtime (invoca endpoint)
    ↓
FastAPI Application
    ├─ Validación con Pydantic
    ├─ Carga de features
    ├─ Predicción del modelo
    ├─ Cálculo de latencia
    └─ Generación de response
        ↓
    CloudWatch (registro de logs)
        ↓
    Respuesta al cliente
```

---

## 3. Componentes Principales

### 3.1 FastAPI Application (`endpoint_prototipo/main.py`)

**Responsabilidades:**
- Inicializar app Flask
- Configurar CORS y middleware
- Cargar modelo en startup (lifespan)
- Registrar routers

**Configuración base:**
```python
app = FastAPI(
    title="Fraud Detection API",
    version="2024.11",
    lifespan=lifespan
)

# CORS (abierto en dev, restringir en producción)
app.add_middleware(CORSMiddleware, allow_origins=["*"])
```

**Endpoints especiales:**
- `GET /` - Info API
- `GET /ping` - SageMaker health
- `POST /invocations` - SageMaker inference
- `GET /docs` - Swagger UI
- `GET /redoc` - ReDoc docs

### 3.2 Pydantic Schemas (`endpoint_prototipo/schemas.py`)

**Request:**
```python
class FraudPredictionRequest(BaseModel):
    transaction_id: str              # ID transacción
    monto: float (>0)               # Monto transacción
    edad: int (18-120)              # Edad cliente
    ciudad: str                      # Ciudad
    establecimiento: str             # Comercio
    especialidad: str                # Categoría
```

**Response:**
```python
class FraudPredictionResponse(BaseModel):
    schema_version: str              # "1.0"
    request_id: str                 # "REQ-XXXXX"
    ml_score_0_999: float           # 0-999
    model_meta: ModelMeta           # Metadata
    latency_ms: float               # Tiempo inferencia
```

### 3.3 Routers

**health.py:**
```python
GET /health/
├─ Verificar modelo cargado
├─ Status: healthy/degraded/unhealthy
└─ Response: {status, model_loaded, version}
```

**fraud_prediction.py:**
```python
POST /fraud/predict
├─ Input: FraudPredictionRequest
├─ Output: FraudPredictionResponse
└─ Lógica: validar → predecir → retornar

POST /fraud/batch-predict
├─ Input: List[FraudPredictionRequest]
└─ Output: List[FraudPredictionResponse]
```

### 3.4 Docker Container

**Multi-stage build:**
- **Stage 1 (Builder):** Compila dependencias
- **Stage 2 (Runtime):** Imagen opcional (~2.4 GB)

**Features:**
- Base: Python 3.11-slim
- Pre-compila librerías (mejor performance)
- 65% más pequeño que build simple
- Expone puerto 8080

---

## 4. Stack Tecnológico

### Backend
- **Framework:** FastAPI (async HTTP)
- **Server:** Uvicorn (ASGI)
- **Validation:** Pydantic v2

### ML
- **Preprocessing:** pandas, numpy
- **Models:** scikit-learn, XGBoost, LightGBM
- **Serialization:** joblib, pickle

### Infrastructure
- **Containerization:** Docker
- **Orchestration:** AWS SageMaker
- **API Management:** AWS API Gateway
- **IAM:** Role-Based Access Control

### Observability
- **Logs:** CloudWatch Logs
- **Metrics:** CloudWatch Metrics
- **Dashboards:** CloudWatch Dashboards
- **Alerts:** SNS notifications

### Data Science
- **Versioning:** Git
- **Dependencies:** uv (ultra-fast package manager)
- **Notebooks:** Jupyter Lab

---

## 5. Flujo de Una Predicción

### Paso a Paso (7 pasos)

```
1. CLIENTE envía HTTP POST /fraud/predict
   {"transaction_id":"TRX-001", "monto":150, ...}
   
2. API GATEWAY recibe
   ├─ Valida headers
   ├─ Aplica rate-limiting
   └─ Enruta a SageMaker
   
3. SAGEMAKER invoca endpoint
   └─ URI: /endpoints/endpoint-fraudes-xxx/invocations
   
4. DOCKER CONTAINER FastAPI
   ├─ Pydantic valida input
   ├─ Comienza timing
   └─ Genera request_id único
   
5. MODELO PREDICE
   ├─ Procesa features
   ├─ Ejecuta model.predict()
   └─ Obtiene score 0-999
   
6. FASTAPI retorna Response
   {
     "request_id": "REQ-A1B2C",
     "ml_score_0_999": 125,
     "latency_ms": 45.23,
     ...
   }
   
7. CLOUDWATCH registra logs
   ├─ Request JSON
   ├─ Response JSON
   ├─ Latencia
   └─ Status code
```

### Transformación de Features (Actual - Mock)

```python
# Cálculo simple de score
base_score = min(999, max(0, request.monto * 2))

# Ajustes por edad
if request.edad < 25 or request.edad > 70:
    base_score *= 1.1

# Normalizar 0-999
fraud_score = min(999, max(0, base_score))
```

**TODO:** Implementar features reales (log transform, encoding, normalization, etc)

---

## 6. API REST Endpoints

### Base URL
```
https://{api-id}.execute-api.us-east-1.amazonaws.com/prod
```

### 6.1 Health Check
```http
GET /health/
```

**Response (200):**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "version": "1.0.0"
}
```

---

### 6.2 Fraud Prediction (Single)
```http
POST /fraud/predict
Content-Type: application/json

{
  "transaction_id": "TRX-001",
  "monto": 250.50,
  "edad": 35,
  "ciudad": "Quito",
  "establecimiento": "Amazon Pay",
  "especialidad": "ECOMMERCE"
}
```

**Response (200):**
```json
{
  "schema_version": "1.0",
  "request_id": "REQ-A1B2C",
  "ml_score_0_999": 125,
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": 45.23
}
```

**Score Interpretation:**
- `0-100`: Legítimo ✅
- `100-400`: Sospechoso ⚠️
- `400-700`: Probable fraude 🚩
- `700-999`: Muy probable fraude 🔴

---

### 6.3 Fraud Prediction (Batch)
```http
POST /fraud/batch-predict
[
  {"transaction_id": "TRX-001", "monto": 150, ...},
  {"transaction_id": "TRX-002", "monto": 75.50, ...}
]
```

**Response:** Array de FraudPredictionResponse

---

### Status Codes
| Code | Significado |
|------|-------------|
| 200 | Predicción exitosa |
| 422 | Validación de input falló |
| 503 | Modelo no cargado |
| 500 | Error interno |

---

## 7. Infraestructura Cloud

### Archivo: `infra-sagemaker-complete.yaml`

**Parámetros:**
- `ImageUri`: URI imagen Docker en ECR
- `InstanceType`: Tipo instancia SageMaker (default: `ml.m5.large`)

**Recursos creados:**

| Recurso | Descripción |
|---------|------------|
| **IAM Roles** | Permisos para SageMaker, API Gateway |
| **ECR Repository** | Registro para imagen Docker |
| **SageMaker Model** | Definición de modelo |
| **SageMaker Endpoint** | Instancia ejecutando modelo |
| **API Gateway** | REST endpoint público HTTPS |

**Outputs:**
```
ModelName          → fraudes-model-{stack}
EndpointName       → endpoint-fraudes-{stack}
ApiInvokeUrl       → https://{id}.execute-api.../prod/fraude
```

### Deploy CloudFormation

```bash
# Create stack
aws cloudformation create-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters \
    ParameterKey=ImageUri,ParameterValue={ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest \
    ParameterKey=InstanceType,ParameterValue=ml.m5.large \
  --capabilities CAPABILITY_NAMED_IAM

# Wait for creation
aws cloudformation wait stack-create-complete --stack-name fraud-detection-prod

# Get API URL
aws cloudformation describe-stacks --stack-name fraud-detection-prod \
  --query 'Stacks[0].Outputs'
```

---

## 8. Pipelines ML

### Estructura de Pipelines

```
src/pipelines/
├── 0-cleaning_data/       → Limpieza y validación
├── 1-data_sampling/       → Muestreo estratificado
├── 2-feature_engineering/ → Creación de features
├── 3-training/            → Entrenamiento
├── 4-evaluation/          → Evaluación de métricas
└── 5-model_registry/      → Guardado de modelo
```

### Flujo Pipeline

**Stage 0: Data Cleaning**
- Input: `fraudes.csv` (datos crudos)
- Output: `fraudes_clean.parquet`
- Operaciones: nulls, duplicados, validación tipos

**Stage 1-2: Feature Engineering**
- Temporal: hora, día, fin de semana, mes
- Monetarias: log(monto), categorización
- Geográficas: encoding ciudad/país
- Derivadas: avg/frequency por usuario

**Stage 3-4: Training & Evaluation**
- Modelos: LightGBM (recomendado)
- Métricas: accuracy, precision, recall, F1, ROC-AUC
- Output: `modelo_fraudes.pkl`

**Stage 5: Model Registry**
- Versionado del modelo
- Metadata: accuracy, hyperparameters
- Artefactos en S3/MLflow

### Ejecución

```bash
# Ejecutar pipeline completo
uv run python src/pipelines/0-cleaning_data/main.py
uv run python src/pipelines/1-data_sampling/main.py
# ... etc hasta stage 5
```

---

## 9. Despliegue

### Prerequisitos

```bash
# 1. AWS CLI
aws configure
aws sts get-caller-identity  # Verificar

# 2. Docker
docker --version

# 3. Git
git --version
```

### Deploy Step-by-Step

```bash
# 1. Build Docker image
docker build -t fraud-api:latest .
docker tag fraud-api:latest {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# 2. Login ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com

# 3. Push image
docker push {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# 4. Deploy CloudFormation
aws cloudformation create-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters ParameterKey=ImageUri,ParameterValue={ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest \
  --capabilities CAPABILITY_NAMED_IAM

# 5. Wait & Test
aws cloudformation wait stack-create-complete --stack-name fraud-detection-prod
API_URL=$(aws cloudformation describe-stacks --stack-name fraud-detection-prod \
  --query 'Stacks[0].Outputs[0].OutputValue' --output text)
curl -X POST $API_URL -H "Content-Type: application/json" -d '{...}'
```

### CI/CD Automático

**GitHub Actions** (`.github/workflows/deploy.yml`):
1. Push a main → automáticamente:
   - Build Docker image
   - Push a ECR
   - Update CloudFormation stack
   - Espera a que esté "InService"

---

## 10. Troubleshooting

### Error: "Model not loaded" (503)

**Causa:** Modelo no se cargó en startup

**Solución:**
```bash
# Ver logs
aws logs tail /aws/sagemaker/Endpoints/endpoint-fraudes-xxx --follow

# Describir endpoint
aws sagemaker describe-endpoint --endpoint-name endpoint-fraudes-xxx

# Redeploy
aws cloudformation update-stack --stack-name fraud-detection-prod ...
```

---

### Error: Timeout API (P95 > 200ms)

**Causa:** Instancia insuficiente o modelo pesado

**Solución:**
```bash
# Scale up instancia
aws cloudformation update-stack --stack-name fraud-detection-prod \
  --parameters ParameterKey=InstanceType,ParameterValue=ml.m5.xlarge
```

---

### Error: 422 Unprocessable Entity

**Causa:** Datos inválidos en request

**Validar según esquema:**
```json
{
  "transaction_id": "TRX-001",  ✅ string
  "monto": 100,                 ✅ >0
  "edad": 35,                   ✅ 18-120
  "ciudad": "Quito",            ✅ string
  "establecimiento": "...",     ✅ string
  "especialidad": "..."         ✅ string
}
```

---

### Error: CloudFormation Stack Failed

**Debug:**
```bash
# Ver eventos fallidos
aws cloudformation describe-stack-events \
  --stack-name fraud-detection-prod \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Causas comunes:
# - ImageUri inválida (no existe en ECR)
# - Permisos IAM insuficientes
# - Cuota SageMaker excedida
# - Region no soportada
```

---

## Monitoreo Básico

### CloudWatch Logs
```bash
# Ver logs en tiempo real
aws logs tail /fraud-detection/production --follow

# Filtrar por error
aws logs filter-log-events --log-group-name /fraud-detection/production \
  --filter-pattern "ERROR"
```

### Métricas Clave
- **Latencia:** P95 < 150ms
- **Errores:** < 1%
- **Throughput:** 1000+ TPS

---

## 📝 Checklist Deployment

- [ ] Imagen Docker construida
- [ ] Imagen pusheada a ECR
- [ ] CloudFormation template revisado
- [ ] Stack creado exitosamente
- [ ] Endpoint en "InService"
- [ ] Health check retorna 200
- [ ] Predicción test exitosa
- [ ] Logs en CloudWatch visibles

---

**Status:** ✅ Production Ready  
**Last Update:** Febrero 23, 2026
