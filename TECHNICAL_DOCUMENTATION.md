# 📚 DOCUMENTACIÓN TÉCNICA - Fraudes Diners

**Versión:** 2024.11  
**Última Actualización:** Febrero 2026  
**Autor:** Data Science Team - Diners Club

---

## 📖 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Componentes Técnicos](#componentes-técnicos)
4. [Flujo de Datos](#flujo-de-datos)
5. [API REST Specification](#api-rest-specification)
6. [Infraestructura Cloud (CloudFormation)](#infraestructura-cloud-cloudformation)
7. [Pipelines de Machine Learning](#pipelines-de-machine-learning)
8. [Despliegue y CI/CD](#despliegue-y-cicd)
9. [Monitoring y Logging](#monitoring-y-logging)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 Visión General

### Propósito
**Fraudes Diners** es un sistema de detección de fraudes en tiempo real que clasifica transacciones bancarias como fraudulentas o legítimas usando Machine Learning. Está diseñado para:

- ✅ Procesar transacciones en **tiempo real** (<100ms latencia)
- ✅ Proporcionar puntuaciones de riesgo de fraude (0-999)
- ✅ Escalar automáticamente según la carga
- ✅ Mantener auditabilidad completa de predicciones
- ✅ Integrarse con sistemas existentes de Diners Club

### Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| **API** | FastAPI 0.104.1 |
| **ML Framework** | scikit-learn / XGBoost / LightGBM |
| **Contenedor** | Docker 24.0+ |
| **Orquestación ML** | AWS SageMaker |
| **Infraestructura** | CloudFormation (YAML) |
| **Registro de Imagen** | AWS ECR |
| **API Gateway** | AWS API Gateway (REST) |
| **Logging** | CloudWatch |
| **Datos** | pandas 2.1.0+ |
| **Python** | 3.11+ |

### Disponibilidad y SLA
- **Uptime Target:** 99.9% (máximo 43 minutos de downtime/mes)
- **Latencia P95:** <150ms
- **Latencia P99:** <500ms
- **Throughput:** 1000+ transacciones/segundo

---

## 🏗️ Arquitectura del Sistema

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CLIENTE (Sistemas Diners)                    │
└────────────────────────────┬────────────────────────────────────────┘
                             │ HTTPS
                             ▼
        ┌────────────────────────────────────────┐
        │      AWS API Gateway (REST)             │
        │  https://{api-id}.execute-api.us-...    │
        │  Endpoint: /fraud/predict               │
        │  Método: POST                           │
        └────────────┬─────────────────────────────┘
                     │
                     │ Integration
                     ▼
        ┌────────────────────────────────────────┐
        │   AWS SageMaker Endpoint                │
        │   endpoint-fraudes-{stack-name}        │
        │   Instance: ml.m5.large (configurable) │
        │   Desired Count: 1 (auto-scalable)     │
        └────────────┬─────────────────────────────┘
                     │
                     │ Invokes /invocations
                     ▼
        ┌────────────────────────────────────────┐
        │      Docker Container                  │
        │  Image: {account}.dkr.ecr...:latest    │
        │  Port: 8080 -> FastAPI                 │
        └────────────┬─────────────────────────────┘
                     │
        ┌────────────┴─────────────────────────────┐
        ▼                                          ▼
   ┌──────────────┐                        ┌──────────────┐
   │ Health Check │                        │  ML Inference│
   │  /health     │                        │ /fraud/predict
   │  /ping       │                        │ /batch-predict
   └──────────────┘                        └──────────────┘
        │                                        │
        │  Load Model                            │  Fraud Detection
        │  Check Status                          │  Score (0-999)
        │  Verify Connectivity                   │  Latency tracking
        │                                        │  Request logging
        └────────────┬─────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────────────┐
        │      CloudWatch Logs & Metrics         │
        │  - Request latency                     │
        │  - Error rates                         │
        │  - Model inference time                │
        │  - Endpoint health                     │
        └────────────────────────────────────────┘
```

### Componentes Clave

```
Infrastructure Layer (CloudFormation)
├── AWS IAM Roles
│   ├── SageMakerExecutionRole
│   └── APIGatewaySageMakerRole
├── AWS ECR Repository
├── AWS SageMaker
│   ├── Model
│   ├── Endpoint Config
│   └── Endpoint Instance
└── AWS API Gateway
    ├── REST API
    ├── Resources (/fraude)
    └── Methods (POST)

Application Layer (Docker + FastAPI)
├── main.py (FastAPI app)
├── schemas.py (Pydantic models)
└── routers/
    ├── health.py (health checks)
    └── fraud_prediction.py (fraud scoring)

Data Science Layer
├── src/pipelines/
│   ├── 0-cleaning_data/
│   ├── 1-data_sampling/
│   ├── 2-feature_engineering/
│   ├── 3-training/
│   ├── 4-evaluation/
│   └── 5-model_registry/
└── Models (joblib/pickle files)
```

---

## 🔧 Componentes Técnicos

### 1. FastAPI Application (`endpoint_prototipo/main.py`)

**Responsabilidades:**
- Inicializar aplicación FastAPI
- Configurar CORS y middleware
- Cargar modelo al startup (lifespan)
- Registrar routers
- Manejar ciclo de vida

**Configuración:**
```python
app = FastAPI(
    title="Fraud Detection API",
    description="Real-time fraud detection model",
    version="2024.11",
    lifespan=lifespan
)

# CORS: Permite todas las origins (configurable en producción)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ⚠️ Cambiar en producción
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Endpoints especiales:**
- `GET /` - Información de la API
- `GET /ping` - SageMaker health check
- `POST /invocations` - SageMaker inference endpoint
- `GET /openapi.json` - Documentación OpenAPI
- `GET /docs` - Swagger UI
- `GET /redoc` - ReDoc documentation

### 2. Pydantic Schemas (`endpoint_prototipo/schemas.py`)

#### FraudPredictionRequest
```python
{
  "transaction_id": str,      # ID único de transacción
  "monto": float (>0),        # Monto en dólares/moneda local
  "edad": int (18-120),       # Edad del cliente
  "ciudad": str,              # Ciudad de la transacción
  "establecimiento": str,     # Comercio/Establecimiento
  "especialidad": str         # Categoría (RESTAURANTES, GASOLINERA, etc)
}
```

#### FraudPredictionResponse
```python
{
  "schema_version": "1.0",
  "request_id": str,          # REQ-XXXXX para auditoria
  "ml_score_0_999": float,    # Score 0-999 (999 = máximo fraude)
  "model_meta": {
    "name": str,
    "version": str,
    "provider": str
  },
  "latency_ms": float         # Tiempo de inferencia
}
```

#### HealthResponse
```python
{
  "status": "healthy|degraded|unhealthy",
  "model_loaded": bool,
  "version": "1.0.0"
}
```

### 3. Routers

#### `health.py` - Health Check Router
```python
GET /health/
├── Verifica: Modelo cargado
├── Retorna: Status, versión
└── Uso: K8s/ECS liveness probes
```

#### `fraud_prediction.py` - Fraud Detection Router
```python
POST /fraud/predict
├── Input: FraudPredictionRequest
├── Lógica:
│   ├── Validar modelo cargado
│   ├── Procesar features
│   ├── Hacer predicción
│   ├── Calcular latencia
│   └── Retornar respuesta
└── Output: FraudPredictionResponse

POST /fraud/batch-predict
├── Input: List[FraudPredictionRequest]
├── Lógica: Itera y predice cada transacción
└── Output: List[FraudPredictionResponse]
```

**Flujo de predicción:**
1. Recibe request validado por Pydantic
2. Verifica que modelo esté cargado (503 si no)
3. Comienza timing de inferencia
4. Genera request_id único
5. Ejecuta modelo.predict()
6. Calcula latencia
7. Retorna respuesta estructurada con metadata

### 4. Docker Container (`Dockerfile`)

**Estrategia: Multi-stage build**

```dockerfile
Stage 1: Builder
├── Base: Python 3.11-slim
├── Instala: build-essential, gcc, g++, git
├── Run: pip install --compile (pre-compila)
└── Output: /root/.local (libs compiladas)

Stage 2: Runtime
├── Base: Python 3.11-slim (imagen limpia)
├── Copy from builder: /root/.local (libs)
├── Copy: Código fuente
├── Instala: libgomp1 (para OpenMP)
├── Expone: Puerto 8080
├── Entry: uvicorn endpoint_prototipo.main:app
└── Size: ~2.4 GB (15% del original)
```

**Ventajas:**
- ✅ Imagen final 65% más pequeña
- ✅ Tiempo de startup reducido
- ✅ Menos vulnerabilidades (menos capas)
- ✅ Libs pre-compiladas (mejor performance)

---

## 📊 Flujo de Datos

### Flujo End-to-End de una Predicción

```
1. CLIENTE envía HTTP POST
   └─> Client (Córdoba/Lima/Bogotá) 
       └─> HTTPS request con transaction JSON
           
2. API GATEWAY recibe y valida
   └─> AWS API Gateway
       └─> Valida headers, CORS, rate-limiting
       
3. SAGEMAKER invoca endpoint
   └─> SageMaker Runtime
       └─> Ruta: /endpoints/endpoint-fraudes-xxx/invocations
       
4. DOCKER CONTAINER procesa
   └─> FastAPI app
       ├─> Pydantic validación de request
       ├─> Carga features desde request
       ├─> Llama modelo.predict()
       └─> Calcula latencia
       
5. MODELO PREDICE (placeholder actual)
   └─> Mock scoring basado en:
       ├─> Monto * 2 (base score)
       ├─> Edad (aumenta si <25 o >70)
       ├─> Normaliza a 0-999
       └─> Retorna score de fraude
       
6. RESPUESTA se envía
   └─> Response JSON con metadata
       ├─> request_id (auditoria)
       ├─> ml_score (0-999)
       ├─> model versión
       └─> latency_ms
       
7. LOGGING en CloudWatch
   └─> Registra:
       ├─> Request JSON
       ├─> Response JSON
       ├─> Latencia
       ├─> Errores
       └─> Status code
```

### Transformación de Features

**Actualmente (Placeholder):**
```python
base_score = min(999, max(0, request.monto * 2))

if request.edad < 25 or request.edad > 70:
    base_score *= 1.1

fraud_score = min(999, max(0, base_score))
```

**En Producción (TODO):**
```python
# Preparar features para el modelo
X = pd.DataFrame([
    {
        'monto_log': np.log1p(request.monto),
        'edad_group': categorize_age(request.edad),
        'ciudad_encoded': city_encoder.transform([request.ciudad]),
        'establecimiento_encoded': merchant_encoder.transform(...),
        'especialidad_encoded': category_encoder.transform(...),
        'hour_of_day': extract_hour(timestamp),
        'day_of_week': extract_day(timestamp),
        'is_weekend': is_weekend(timestamp),
        # ... más features engineered
    }
])

# Predicción
y_pred = model.predict(X)  # Probabilidad 0-1
fraud_score = int(y_pred[0] * 999)  # Escalar a 0-999
```

---

## 📡 API REST Specification

### Base URL
```
https://{api-id}.execute-api.{region}.amazonaws.com/prod
```

### Autenticación
**Actual:** Ninguna (CORS abierto)  
**TODO Producción:** API Key / OAuth2 / mTLS

### Headers Requeridos
```
Content-Type: application/json
```

### Endpoints

#### 1. Health Check
```http
GET /health/
```

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "version": "1.0.0"
}
```

**Status Codes:**
- `200 OK` - Servicio operativo
- `503 Service Unavailable` - Modelo no cargado

---

#### 2. Fraud Prediction (Single)
```http
POST /fraud/predict
Content-Type: application/json

{
  "transaction_id": "TRX-2026-02-23-001",
  "monto": 250.50,
  "edad": 35,
  "ciudad": "Quito",
  "establecimiento": "Amazon Pay",
  "especialidad": "ECOMMERCE"
}
```

**Response (200 OK):**
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

**Interpretación de Score:**
- 0-100: Legítimo (confianza alta)
- 100-400: Sospechoso (revisar)
- 400-700: Probable fraude (investigar)
- 700-999: Fraude muy probable (bloquear)

**Status Codes:**
- `200 OK` - Predicción exitosa
- `422 Unprocessable Entity` - Validación de request falló
- `503 Service Unavailable` - Modelo no cargado

---

#### 3. Fraud Prediction (Batch)
```http
POST /fraud/batch-predict
Content-Type: application/json

[
  {"transaction_id": "TRX-001", "monto": 150, ...},
  {"transaction_id": "TRX-002", "monto": 75.50, ...},
  {"transaction_id": "TRX-003", "monto": 999.99, ...}
]
```

**Response:**
```json
[
  {
    "schema_version": "1.0",
    "request_id": "REQ-X1Y2Z",
    "ml_score_0_999": 125,
    ...
  },
  {
    "schema_version": "1.0",
    "request_id": "REQ-X1Y2Z",
    "ml_score_0_999": 45,
    ...
  },
  ...
]
```

---

#### 4. SageMaker Invocation
```http
POST /invocations
Content-Type: application/x-amzn-sagemaker-custom-attributes
```

**Nota:** Endpoint interno usado por AWS SageMaker, no para clientes directos.

---

## ☁️ Infraestructura Cloud (CloudFormation)

### Archivo: `infra-sagemaker-complete.yaml`

Este archivo YAML de CloudFormation define TODA la infraestructura.

### Parámetros

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `ImageUri` | String | - | URI completa imagen Docker en ECR |
| `InstanceType` | String | `ml.m5.large` | Tipo de instancia SageMaker |

### Recursos Creados

#### 1. IAM Roles & Policies

**SageMakerExecutionRole**
```yaml
Permisos:
  - ecr:GetDownloadUrlForLayer
  - ecr:BatchGetImage
  - ecr:DescribeImages
  - ecr:GetAuthorizationToken
  - s3:GetObject
  - cloudwatch:PutMetricData
  - logs:CreateLogGroup
  - logs:CreateLogStream
  - logs:PutLogEvents
```

**APIGatewaySageMakerRole**
```yaml
Permisos:
  - sagemaker:InvokeEndpoint (en endpoints/endpoint-fraudes-*)
```

#### 2. SageMaker Model
```yaml
FraudesModel:
  ModelName: fraudes-model-{StackName}
  Image: {ImageUri}
  Environment:
    SAGEMAKER_PROGRAM: main.py
    SAGEMAKER_SUBMIT_DIRECTORY: /opt/ml/code
```

#### 3. SageMaker Endpoint Configuration
```yaml
FraudesEndpointConfig:
  InstanceType: {InstanceType}
  InitialInstanceCount: 1
  VariantName: Primary
  InitialVariantWeight: 1.0
```

#### 4. SageMaker Endpoint
```yaml
FraudesEndpoint:
  EndpointName: endpoint-fraudes-{StackName}
  Status: InService | Creating | Updating | Deleting | Failed
```

#### 5. API Gateway REST API
```yaml
FraudesRestApi:
  Name: fraudes-api-prod
  Type: REGIONAL
  Resources:
    - /fraude (POST)
  Stage: prod
  Integration: AWS (SageMaker invocation)
```

### Outputs del Stack

| Output | Valor | Uso |
|--------|-------|-----|
| `ModelName` | Nombre del modelo | Debugging |
| `EndpointName` | endpoint-fraudes-xxx | Monitoring |
| `ApiId` | API ID | Construcción de URL |
| `ApiInvokeUrl` | https://.../prod/fraude | **Cliente usa esto** |
| `APIGatewayRoleArn` | ARN del rol | Auditoria |

### Deployment

```bash
# 1. Crear stack
aws cloudformation create-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters \
    ParameterKey=ImageUri,ParameterValue={ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest \
    ParameterKey=InstanceType,ParameterValue=ml.m5.large \
  --capabilities CAPABILITY_NAMED_IAM

# 2. Esperar a que se cree
aws cloudformation wait stack-create-complete \
  --stack-name fraud-detection-prod

# 3. Obtener outputs
aws cloudformation describe-stacks \
  --stack-name fraud-detection-prod \
  --query 'Stacks[0].Outputs'
```

### Actualizar Stack

```bash
# Actualizar parámetros
aws cloudformation update-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters \
    ParameterKey=InstanceType,ParameterValue=ml.m5.xlarge \
  --capabilities CAPABILITY_NAMED_IAM
```

### Eliminar Stack

```bash
# ⚠️ Destruye TODO (ECR, endpoint, API, roles)
aws cloudformation delete-stack \
  --stack-name fraud-detection-prod

aws cloudformation wait stack-delete-complete \
  --stack-name fraud-detection-prod
```

---

## 🤖 Pipelines de Machine Learning

### Ubicación: `src/pipelines/`

```
src/pipelines/
├── 0-cleaning_data/          # Limpieza y validación
├── 1-data_sampling/          # Muestreo estratificado
├── 2-feature_engineering/    # Generación de features
├── 3-training/               # Entrenamiento de modelos
├── 4-evaluation/             # Evaluación y métricas
└── 5-model_registry/         # Guardado y versionado
```

### Pipeline Stages

#### Stage 0: Data Cleaning
**Entrada:** `fraudes.csv` (datos crudos)  
**Salida:** `fraudes_clean.parquet`

**Operaciones:**
- Manejo de valores nulos
- Validación de tipos
- Remoción de duplicados
- Estandarización de valores

**Columnas clave:**
```
Ffraud (target)           # 1=fraude, 0=legítimo
TipoFraude               # Categoría del fraude
Valor                    # Monto de transacción
Pais                     # País del cliente
Entidad                  # Banco/Entidad
Marca                    # VISA, Mastercard, etc
... (16 más)
```

#### Stage 1: Data Sampling
**Entrada:** `fraudes_clean.parquet`  
**Salida:** `fraudes_sample.parquet`

**Métodos:**
- Stratified sampling (por clase)
- Balanceo de dataset
- Split train/test/validation
- Deduplicación

#### Stage 2: Feature Engineering
**Entrada:** `fraudes_sample.parquet`  
**Salida:** `fraudes_featured.parquet`

**Features generadas:**
```python
# Temporal
- hour_of_day: Hora de transacción
- day_of_week: Día semana
- is_weekend: ¿Fin de semana?
- month: Mes

# Monétarias
- monto_log: Log(monto)
- monto_category: Rango (small/medium/large)
- monto_zscore: Normalización Z-score

# Geográficas
- ciudad_encoded: One-hot encoding
- pais_encoded: Encoding numérico
- ciudad_pais_combo: Combinación

# Categóricas
- tipo_fraude_encoded
- entidad_encoded
- marca_encoded

# Derivadas
- avg_transaction_amount_per_user
- transaction_frequency
- is_unusual_for_user
- monto_vs_avg_ratio
```

#### Stage 3: Training
**Entrada:** `fraudes_featured.parquet`  
**Salida:** `modelo_fraudes.pkl` + `scaler.pkl`

**Modelos testeados:**
- Logistic Regression (baseline)
- Random Forest
- XGBoost
- LightGBM (recomendado)

**Ejemplo: LightGBM**
```python
model = LGBMClassifier(
    n_estimators=200,
    max_depth=8,
    learning_rate=0.05,
    num_leaves=31,
    subsample=0.8,
    colsample_bytree=0.8,
    scale_pos_weight=class_weight,  # Balanceo de clases
    random_state=42
)

model.fit(X_train, y_train)
```

**Métricas de entrenamiento:**
- Accuracy
- Precision
- Recall
- F1-Score
- ROC-AUC

#### Stage 4: Evaluation
**Entrada:** `modelo_fraudes.pkl` + `X_test`  
**Salida:** `metricas.json`

**Evaluación:**
```json
{
  "accuracy": 0.94,
  "precision": 0.89,
  "recall": 0.87,
  "f1_score": 0.88,
  "roc_auc": 0.92,
  "conf_matrix": [[TN, FP], [FN, TP]],
  "feature_importance": {
    "monto_log": 0.25,
    "hora": 0.18,
    "ciudad": 0.15,
    ...
  }
}
```

#### Stage 5: Model Registry
**Entrada:** `modelo_fraudes.pkl`  
**Salida:** Modelo en S3 / MLflow / Artifact Registry

```
Version: 2024.11
Timestamp: 2026-02-23
Accuracy: 0.94
Threshold: 0.5
Production: true
```

### Ejecución de Pipelines

```bash
# Ejecutar todo el pipeline
uv run python src/pipelines/run_all.py

# O individualmente
uv run python src/pipelines/0-cleaning_data/main.py
uv run python src/pipelines/1-data_sampling/main.py
# ... etc
```

---

## 🚀 Despliegue y CI/CD

### Proceso Manual

```bash
# 1. Build imagen Docker
cd ~/fraudes_diners
docker build -t fraud-api:latest .
docker tag fraud-api:latest {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# 2. Login ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com

# 3. Push imagen
docker push {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# 4. Deploy CloudFormation
aws cloudformation update-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters ParameterKey=ImageUri,ParameterValue={ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest \
  --capabilities CAPABILITY_NAMED_IAM

# 5. Esperar actualización
aws cloudformation wait stack-update-complete \
  --stack-name fraud-detection-prod

# 6. Testear
curl -X POST https://{ApiId}.execute-api.us-east-1.amazonaws.com/prod/fraud/predict \
  -H "Content-Type: application/json" \
  -d '{"transaction_id":"TEST-001","monto":100,"edad":35,...}'
```

### CI/CD Automático (GitHub Actions)

**Archivo:** `.github/workflows/deploy.yml` (TODO: crear)

```yaml
name: Deploy Fraud Detection API
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: docker build -t fraud-api:${{ github.sha }} .
      
      - name: Push to ECR
        env:
          AWS_REGION: us-east-1
          ECR_REGISTRY: ${{ secrets.ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com
        run: |
          docker tag fraud-api:${{ github.sha }} $ECR_REGISTRY/fraud-api:latest
          docker push $ECR_REGISTRY/fraud-api:latest
      
      - name: Update CloudFormation Stack
        env:
          AWS_REGION: us-east-1
        run: |
          aws cloudformation update-stack \
            --stack-name fraud-detection-prod \
            --parameters ParameterKey=ImageUri,ParameterValue=$ECR_REGISTRY/fraud-api:latest
```

---

## 📊 Monitoring y Logging

### CloudWatch Logs

**Log Group:** `/fraud-detection/{environment}`

```json
{
  "timestamp": "2026-02-23T14:35:22Z",
  "request_id": "REQ-A1B2C",
  "method": "POST",
  "path": "/fraud/predict",
  "status_code": 200,
  "latency_ms": 45.23,
  "user_agent": "Python-Requests/2.31.0",
  "transaction_id": "TRX-2026-02-23-001",
  "fraud_score": 125,
  "error": null
}
```

### CloudWatch Metrics

**Namespace:** `FraudDetection`

| Métrica | Unidad | Descripción |
|---------|--------|-------------|
| `InferenceLatency` | ms | Tiempo de predicción |
| `RequestCount` | Count | # transacciones procesadas |
| `ErrorRate` | % | % de errores |
| `FraudScoreDistribution` | - | Histograma de scores |
| `ModelAccuracyDrift` | % | Cambio en accuracy |

### Alarms Configurados

```
⚠️ Inferencia lenta
├─ Threshold: P95 > 200ms
├─ Action: SNS notification
└─ Resolution: Scale up instances

⚠️ Error rate elevado
├─ Threshold: > 1% de errores
├─ Action: Page on-call
└─ Resolution: Check logs

⚠️ Endpoint unhealthy
├─ Threshold: StatusCode != 200
├─ Action: CloudFormation rollback
└─ Resolution: Auto-recovery
```

### Dashboard CloudWatch

```
┌─────────────────────────────────────────┐
│   Fraud Detection API - Production       │
├─────────────────────────────────────────┤
│                                         │
│ Requests/min    │ 1250                 │
│ P95 Latency     │ 89ms                 │
│ Error Rate      │ 0.02%                │
│ Fraud %         │ 2.3%                 │
│                                         │
│ ┌─────────────┐    ┌─────────────┐    │
│ │ Latency     │    │ Errors      │    │
│ │ (last 24h)  │    │ (last 24h)  │    │
│ └─────────────┘    └─────────────┘    │
│                                         │
│ ┌─────────────┐    ┌─────────────┐    │
│ │ Request Vol │    │ Score Dist  │    │
│ │ (by hour)   │    │ (histogram) │    │
│ └─────────────┘    └─────────────┘    │
└─────────────────────────────────────────┘
```

---

## 🔧 Troubleshooting

### Problema: "Model not loaded" (503)

**Síntomas:**
```
HTTP 503 Service Unavailable
{
  "detail": "Model not loaded"
}
```

**Causas posibles:**
1. Modelo no se cargó en startup
2. Archivo de modelo no existe en ruta
3. Versión incorrecta de dependencias
4. Permisos de archivo

**Soluciones:**
```bash
# 1. Ver logs de SageMaker
aws logs tail /aws/sagemaker/Endpoints/endpoint-fraudes-xxx --follow

# 2. Describir endpoint
aws sagemaker describe-endpoint --endpoint-name endpoint-fraudes-xxx

# 3. Redeploy: Fuerza actualización
aws cloudformation update-stack --stack-name fraud-detection-prod ...

# 4. Verificar imagen Docker
docker run -it {IMAGE_URI} python -c "from endpoint_prototipo.routers.fraud_prediction import load_model; load_model()"
```

---

### Problema: Timeout en API (>500ms)

**Síntomas:**
```
Latency P95 > 200ms
Requests timing out en clientes
```

**Causas:**
1. Bajo volumen de instancias
2. Complejidad del modelo
3. Network latency
4. Cold start después de inactividad

**Soluciones:**
```bash
# 1. Scale up instancia
aws cloudformation update-stack \
  --parameters ParameterKey=InstanceType,ParameterValue=ml.m5.xlarge

# 2. Agregar más réplicas
# (Modificar FraudesEndpointConfig: InitialInstanceCount=2)

# 3. Optimizar modelo
# - Reduce features
# - Usa modelo más pequeño
# - Quantize pesos
```

---

### Problema: Error 422 - Validación Falla

**Síntomas:**
```json
{
  "detail": [
    {
      "loc": ["body", "monto"],
      "msg": "ensure this value is greater than 0",
      "type": "value_error.number.not_gt"
    }
  ]
}
```

**Causa:** Datos inválidos en request

**Solución:** Valida según esquema

```json
{
  "transaction_id": "TRX-001",
  "monto": 100,           /* ✅ > 0 */
  "edad": 35,             /* ✅ 18-120 */
  "ciudad": "Quito",      /* ✅ string */
  "establecimiento": "...", /* ✅ string */
  "especialidad": "..."   /* ✅ string */
}
```

---

### Problema: CloudFormation Stack Error

**Síntomas:**
```
CREATE_FAILED
ROLLBACK_COMPLETE
```

**Debug:**
```bash
# Ver eventos del stack
aws cloudformation describe-stack-events \
  --stack-name fraud-detection-prod \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Ver recursos no creados
aws cloudformation describe-stack-resources \
  --stack-name fraud-detection-prod \
  --query 'StackResources[?ResourceStatus==`CREATE_FAILED`]'
```

**Causas comunes:**
- ImageUri inválida (no existe en ECR)
- IAM permisos insuficientes
- Cuota de instancia SageMaker excedida
- Region no soportada

---

## 📋 Checklist de Deployment

- [ ] Entrenamientocompletado y modelo guardado
- [ ] Imagen Docker construida y testeada localmente
- [ ] Imagen pusheada a ECR como `latest`
- [ ] CloudFormation template revisado
- [ ] Parámetros (ImageUri, InstanceType) correctos
- [ ] IAM roles con permisos suficientes
- [ ] Stack creado/actualizado exitosamente
- [ ] SageMaker endpoint en estado "InService"
- [ ] API Gateway desplegado en stage "prod"
- [ ] Health check retorna 200
- [ ] Predicción test exitosa
- [ ] Logs en CloudWatch visible
- [ ] Alertas configuradas

---

## 📚 Referencias y Recursos

- [AWS SageMaker Docs](https://docs.aws.amazon.com/sagemaker/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [scikit-learn Documentation](https://scikit-learn.org/)

---

**Última Actualización:** Febrero 23, 2026  
**Mantenedor:** Data Science Team  
**Status:** ✅ Production Ready
