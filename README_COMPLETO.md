# 🔍 Fraudes Diners - Sistema de Detección de Fraudes

[![Version](https://img.shields.io/badge/version-2024.11-blue.svg)](https://github.com/dinersclub/fraudes-diners)
[![Python](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)
[![AWS](https://img.shields.io/badge/AWS-SageMaker%20%7C%20API%20Gateway-orange.svg)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Sistema de detección de fraudes en transacciones bancarias en tiempo real usando Machine Learning y AWS.**

---

## 📋 Tabla de Contenidos

- [Quick Start](#-quick-start)
- [Características](#-características)
- [Requisitos del Sistema](#-requisitos-del-sistema)
- [Instalación](#-instalación)
- [Uso](#-uso)
- [Arquitectura](#-arquitectura)
- [API Documentation](#-api-documentation)
- [Despliegue](#-despliegue)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Desarrollo](#-desarrollo)
- [Troubleshooting](#-troubleshooting)
- [Contacto](#-contacto)

---

## 🚀 Quick Start

### Opción 1: Local (Desarrollo)

```bash
# 1. Clonar repositorio
git clone https://github.com/dinersclub/fraudes-diners.git
cd fraudes-diners

# 2. Instalar dependencias (con uv)
curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync

# 3. Activar ambiente
source .venv/bin/activate  # Linux/Mac
# o
.\.venv\Scripts\Activate.ps1  # Windows PowerShell

# 4. Correr API localmente
python endpoint_prototipo/main.py

# 5. Testear
curl -X POST http://localhost:8000/fraud/predict \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX-001",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "Amazon Pay",
    "especialidad": "ECOMMERCE"
  }'
```

**Respuesta:**
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

### Opción 2: Docker (Producción)

```bash
# 1. Build imagen
docker build -t fraud-api:latest .

# 2. Run contenedor
docker run -p 8000:8000 fraud-api:latest

# 3. Testear
curl -X POST http://localhost:8000/fraud/predict ...
```

### Opción 3: AWS SageMaker (Producción)

```bash
# Ver QUICKSTART.md para instrucciones detalladas
cd cloudformation
aws cloudformation create-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters ParameterKey=ImageUri,ParameterValue={YOUR_ECR_IMAGE}
```

---

## ✨ Características

### 🎯 Core Features

- ✅ **Detección en Tiempo Real**: <100ms latencia (P95: <150ms)
- ✅ **Scoring de Riesgo**: Escala 0-999 (0=legítimo, 999=fraude)
- ✅ **Batch Processing**: Procesa múltiples transacciones
- ✅ **Health Checks**: Endpoints para monitoreo
- ✅ **Auditabilidad Completa**: Request ID único por predicción

### 🏗️ Infraestructura

- ✅ **Infrastructure as Code**: CloudFormation YAML
- ✅ **Auto-Scaling**: SageMaker endpoints escalables
- ✅ **High Availability**: Múltiples instancias sincronizadas
- ✅ **API Gateway**: HTTPS REST API pública
- ✅ **CloudWatch**: Logging y monitoreo integrado

### 📊 Machine Learning

- ✅ **Pipelines Automatizados**: 5 etapas de procesamiento
- ✅ **Feature Engineering**: 30+ features derivadas
- ✅ **Múltiples Modelos**: Support para XGBoost, LightGBM, Random Forest
- ✅ **Evaluación Automática**: Métricas de accuracy, precision, recall
- ✅ **Model Registry**: Versionado y tracking

### 🔒 Seguridad

- ✅ **Validación de Entrada**: Pydantic schemas
- ✅ **CORS Configurable**: Control de acceso
- ✅ **IAM Roles**: Control granular de permisos
- ✅ **HTTPS**: Encriptación en tránsito
- ✅ **Error Handling**: Respuestas seguras sin exposición

---

## 📦 Requisitos del Sistema

### Requisitos Mínimos

| Componente | Versión | Descripción |
|-----------|---------|-------------|
| Python | 3.11+ | Runtime del proyecto |
| Docker | 20.10+ | Contenedor (producción) |
| AWS CLI | 2.13+ | Interacción con AWS |
| Git | 2.39+ | Control de versiones |
| uv | 0.1.0+ | Gestor de dependencias |

### Dependencias Python

```
fastapi==0.104.1           # Web framework (sync + async)
uvicorn==0.24.0            # ASGI server
pydantic==2.5.0            # Data validation & serialization
numpy==1.24.3              # Computación numérica
pandas==2.1.0              # Análisis de datos
scikit-learn==1.3.2        # ML baseline models
xgboost==2.0.2             # Gradient boosting
lightgbm==4.1.0            # Light gradient boosting
joblib==1.3.2              # Model serialization
boto3==1.28.0              # AWS SDK
python-multipart==0.0.6    # File upload support
```

### Variables de Entorno (Producción)

```bash
PYTHON_ENV=production      # Logging level
AWS_REGION=us-east-1       # AWS region
SAGEMAKER_PROGRAM=main.py  # SageMaker entry point
LOG_LEVEL=INFO             # Logging verbose
```

---

## 💾 Instalación

### 1. Setup Inicial

```bash
# 1a. Instalar uv (si no existe)
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# 1b. Clonar repo
git clone https://github.com/dinersclub/fraudes-diners.git
cd fraudes-diners

# 1c. Ejecutar setup (automático)
./setup.sh

# O manualmente:
uv sync
```

### 2. Activar Ambiente Virtual

```bash
# Linux / macOS
source .venv/bin/activate

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# Windows CMD
.venv\Scripts\activate.bat
```

### 3. Verificar Instalación

```bash
# Verificar versiones
python --version     # Python 3.11+
pip list | grep fastapi

# Testear importes
python -c "from endpoint_prototipo.main import app; print('✅ App cargada')"

# Testear dependencias ML
python -c "import sklearn, xgboost, lightgbm; print('✅ ML libraries OK')"
```

---

## 🎯 Uso

### Local Development

#### 1. Ejecutar API

```bash
# Opción A: uvicorn directa
uvicorn endpoint_prototipo.main:app --reload --host 0.0.0.0 --port 8000

# Opción B: Python directo
python endpoint_prototipo/main.py

# Opción C: con uv
uv run uvicorn endpoint_prototipo.main:app --reload
```

**Output esperado:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

#### 2. Acceder a Documentación

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **OpenAPI JSON:** http://localhost:8000/openapi.json

#### 3. Testear Predicción

```bash
# Health check
curl http://localhost:8000/health/

# Single prediction
curl -X POST http://localhost:8000/fraud/predict \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX-001",
    "monto": 250,
    "edad": 35,
    "ciudad": "Bogotá",
    "establecimiento": "Nike Store",
    "especialidad": "RETAIL"
  }'

# Batch prediction
curl -X POST http://localhost:8000/fraud/batch-predict \
  -H "Content-Type: application/json" \
  -d '[
    {"transaction_id": "TRX-001", "monto": 100, ...},
    {"transaction_id": "TRX-002", "monto": 200, ...}
  ]'
```

### Ejecutar Pipelines ML

```bash
# Activar ambiente
source .venv/bin/activate

# Ejecutar pipeline completo (0-5)
uv run python src/pipelines/0-cleaning_data/main.py
uv run python src/pipelines/1-data_sampling/main.py
uv run python src/pipelines/2-feature_engineering/main.py
uv run python src/pipelines/3-training/main.py
uv run python src/pipelines/4-evaluation/main.py
uv run python src/pipelines/5-model_registry/main.py

# O usar script de ejecución (si existe)
uv run python src/pipelines/run_all.py
```

### Usar Jupyter Notebooks

```bash
# 1. Instalar jupyter (si no existe)
uv add jupyter

# 2. Registrar kernel (primera vez)
python -m ipykernel install --user --name=fraudes-diners --display-name="Fraudes Diners"

# 3. Iniciar Jupyter
uv run jupyter lab

# 4. En VS Code:
# - Abre notebook
# - Click "Select Kernel"
# - Elige "Fraudes Diners"
```

---

## 🏗️ Arquitectura

### Componentes Principales

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT                               │
│         (Sistema de Diners Club - microservicio)        │
└────────────────┬────────────────────────────────────────┘
                 │ HTTPS POST
                 ▼
┌─────────────────────────────────────────────────────────┐
│              AWS API GATEWAY                             │
│  https://{api-id}.execute-api.us-east-1.amazonaws.com   │
│  Route: /fraud/predict (POST)                           │
└────────────────┬────────────────────────────────────────┘
                 │ Integration
                 ▼
┌─────────────────────────────────────────────────────────┐
│           AWS SAGEMAKER ENDPOINT                         │
│  endpoint-fraudes-{stack-name}                          │
│  ml.m5.large (configurable)                            │
└────────────────┬────────────────────────────────────────┘
                 │ Invokes /invocations
                 ▼
┌─────────────────────────────────────────────────────────┐
│            DOCKER CONTAINER (FastAPI)                    │
│  Image: {account}.dkr.ecr..../fraud-api:latest          │
│  Port: 8080 (internal) / 80 (ALB)                       │
├─────────────────────────────────────────────────────────┤
│  • endpoint_prototipo/main.py      (FastAPI app)        │
│  • endpoint_prototipo/schemas.py   (Pydantic models)    │
│  • routers/health.py               (Health checks)      │
│  • routers/fraud_prediction.py     (ML logic)           │
│  • Model loading & inference                             │
└────────────────┬────────────────────────────────────────┘
                 │
      ┌──────────┴──────────┐
      ▼                     ▼
┌──────────────┐      ┌──────────────────┐
│ Health Check │      │ Fraud Detection  │
│  /health     │      │  /fraud/predict  │
│  /ping       │      │  Batch support   │
└──────────────┘      └──────────────────┘
      │                     │
      └──────────┬──────────┘
                 ▼
┌─────────────────────────────────────────────────────────┐
│       AWS CLOUDWATCH (Logs & Metrics)                    │
│  • Request latency                                      │
│  • Error rates                                          │
│  • Model inference time                                 │
│  • Endpoint health                                      │
└─────────────────────────────────────────────────────────┘
```

### Stack Tecnológico

```
Backend Layer
├── Framework: FastAPI (async web)
├── ASGI Server: Uvicorn
└── Validation: Pydantic v2

ML Layer
├── Preprocessing: pandas, numpy
├── Training: scikit-learn, XGBoost, LightGBM
├── Inference: Model loading from joblib/pickle
└── Metrics: Custom evaluation scripts

Infrastructure Layer
├── Containerization: Docker (multi-stage)
├── Orchestration: AWS SageMaker
├── API Management: AWS API Gateway
├── Networking: VPC, Security Groups
└── IAM: Role-based access control

Observability
├── Logging: CloudWatch Logs
├── Metrics: CloudWatch Metrics
├── Dashboards: CloudWatch Dashboards
└── Alerting: SNS notifications
```

---

## 📡 API Documentation

### Base URL
```
https://{api-id}.execute-api.{region}.amazonaws.com/prod
```

### Authentication
- **Current:** CORS open (⚠️ cambiar en producción)
- **Recommended:** API Key or OAuth2 (TODO)

### Response Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| `200` | OK | Predicción exitosa |
| `201` | Created | Recurso creado |
| `400` | Bad Request | Formato inválido |
| `422` | Unprocessable | Validación falló |
| `503` | Unavailable | Modelo no cargado |
| `500` | Error | Error interno servidor |

### Endpoints

#### 1. Health Check
```http
GET /health/
```

```json
{
  "status": "healthy",
  "model_loaded": true,
  "version": "1.0.0"
}
```

#### 2. Single Fraud Prediction
```http
POST /fraud/predict
Content-Type: application/json

{
  "transaction_id": "TRX-001",
  "monto": 150.50,
  "edad": 35,
  "ciudad": "Quito",
  "establecimiento": "RestaurantXYZ",
  "especialidad": "RESTAURANTES"
}
```

**Response:**
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
- `0-100`: Legítimo (confianza alta)
- `100-400`: Sospechoso (revisar)
- `400-700`: Probable fraude (investigar)
- `700-999`: Fraude muy probable (bloquear)

#### 3. Batch Fraud Prediction
```http
POST /fraud/batch-predict
Content-Type: application/json

[
  {"transaction_id": "TRX-001", "monto": 150, ...},
  {"transaction_id": "TRX-002", "monto": 75.50, ...},
  {"transaction_id": "TRX-003", "monto": 999.99, ...}
]
```

**Response:** Array de FraudPredictionResponse

---

## 🚀 Despliegue

### Prerequisitos

```bash
# 1. Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 2. Configurar credenciales
aws configure
# Ingresa: Access Key, Secret Key, región (us-east-1), output format (json)

# 3. Verificar acceso
aws sts get-caller-identity
```

### Deploy Manual (Step by Step)

```bash
# 1. Build Docker image
docker build -t fraud-api:latest .
docker tag fraud-api:latest {ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# 2. Login ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin {ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# 3. Push image
docker push {ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# 4. Create CloudFormation stack
aws cloudformation create-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters \
    ParameterKey=ImageUri,ParameterValue={ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest \
    ParameterKey=InstanceType,ParameterValue=ml.m5.large \
  --capabilities CAPABILITY_NAMED_IAM

# 5. Wait for stack creation
aws cloudformation wait stack-create-complete \
  --stack-name fraud-detection-prod

# 6. Get API URL
aws cloudformation describe-stacks \
  --stack-name fraud-detection-prod \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiInvokeUrl`].OutputValue' \
  --output text

# 7. Test API
API_URL="https://{api-id}.execute-api.us-east-1.amazonaws.com/prod"
curl -X POST $API_URL/fraud/predict \
  -H "Content-Type: application/json" \
  -d '{"transaction_id":"TEST-001","monto":100,...}'
```

### Deploy Automático (CI/CD)

Ver `.github/workflows/deploy.yml` para instrucciones de GitHub Actions.

```bash
# Simplemente: git push main
git add .
git commit -m "feat: update model"
git push origin main
# → GitHub Actions automáticamente: build, test, push ECR, update CloudFormation
```

---

## 📂 Estructura del Proyecto

```
fraudes_diners/
│
├── 📁 endpoint_prototipo/          ← API FastAPI (MAIN)
│   ├── __init__.py
│   ├── main.py                     ← FastAPI app entry point
│   ├── schemas.py                  ← Pydantic models
│   ├── requirements.txt
│   └── routers/
│       ├── __init__.py
│       ├── health.py               ← Health check endpoints
│       └── fraud_prediction.py     ← Fraud scoring logic
│
├── 📁 src/pipelines/               ← ML Pipelines
│   ├── 0-cleaning_data/
│   ├── 1-data_sampling/
│   ├── 2-feature_engineering/
│   ├── 3-training/
│   ├── 4-evaluation/
│   └── 5-model_registry/
│
├── 📁 cloudformation/              ← AWS Infrastructure (YAML)
│   ├── infra-sagemaker-complete.yaml    ← MAIN template
│   ├── infra-complete-codebuild.yaml    ← CodeBuild config
│   └── infra.yaml                       ← Alternativo simple
│
├── 🐳 Dockerfile                   ← Multi-stage Docker build
├── .dockerignore
│
├── 📦 pyproject.toml              ← Dependencias (uv/pip)
├── uv.lock                         ← Lock file
│
├── 📚 README.md                    ← Este archivo
├── TECHNICAL_DOCUMENTATION.md      ← Documentación técnica detallada
├── QUICKSTART.md                   ← Guía rápida (Día 1-4)
├── AWS_DEPLOYMENT_GUIDE.md         ← Guía deployment en AWS
├── ARCHITECTURE.md                 ← (TODO)
│
├── .github/
│   └── workflows/
│       └── deploy.yml              ← CI/CD GitHub Actions (TODO)
│
├── .gitignore
├── .dockerignore
├── LICENSE
└── requirements.txt                ← Dependencies (pip format)
```

---

## 👨‍💻 Desarrollo

### Setup Local

```bash
# 1. Clonar y setup
git clone https://github.com/dinersclub/fraudes-diners.git
cd fraudes-diners
uv sync

# 2. Crear rama feature
git checkout -b feature/my-feature

# 3. Hacer cambios
# Editar archivos...

# 4. Testear localmente
python endpoint_prototipo/main.py
# o
docker build -t test:latest .
docker run -p 8000:8000 test:latest

# 5. Commit y push
git add .
git commit -m "feat: descripción del cambio"
git push origin feature/my-feature

# 6. Crear Pull Request en GitHub
```

### Agregar Dependencias

```bash
# Agregar dependencia normal
uv add pandas

# Agregar dependencia de desarrollo
uv add --dev pytest black flake8

# Ver dependencias
uv pip list

# Actualizar todas
uv sync --upgrade
```

### Code Style

```bash
# Format con black
black endpoint_prototipo/ src/

# Lint
flake8 endpoint_prototipo/ src/

# Type checking
mypy endpoint_prototipo/ src/

# Tests (si existen)
pytest tests/
```

### Testing

```bash
# Testear API localmente
curl -X POST http://localhost:8000/fraud/predict \
  -H "Content-Type: application/json" \
  -d '{...}'

# Testear con Python
python -c """
import requests
resp = requests.post('http://localhost:8000/fraud/predict', json={...})
print(resp.json())
"""

# Testear con pytest (si existe tests/)
pytest -v tests/
pytest --cov=endpoint_prototipo tests/
```

---

## 🔧 Troubleshooting

### Error: "ModuleNotFoundError: No module named 'fastapi'"

```bash
# Solución: Activar ambiente
source .venv/bin/activate  # Linux/Mac
# o
.\.venv\Scripts\Activate.ps1  # Windows

# Y reinstalar
uv sync
```

### Error: "Docker image not found in ECR"

```bash
# Solución: Push imagen primero
docker tag fraud-api:latest {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest
docker push {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# Verificar
aws ecr describe-images --repository-name fraud-api
```

### API retorna "Model not loaded" (HTTP 503)

```bash
# Solución 1: Ver logs de SageMaker
aws logs tail /aws/sagemaker/Endpoints/endpoint-fraudes-xxx --follow

# Solución 2: Redeploy stack
aws cloudformation update-stack --stack-name fraud-detection-prod ...

# Solución 3: Verificar imagen Docker
docker run -it {IMAGE_URI} python -c "from endpoint_prototipo.routers.fraud_prediction import load_model; load_model()"
```

### API timeout (P95 > 200ms)

```bash
# Solución: Scale up instancia
aws cloudformation update-stack \
  --stack-name fraud-detection-prod \
  --parameters ParameterKey=InstanceType,ParameterValue=ml.m5.xlarge
```

---

## 📊 Monitoring

### CloudWatch Dashboard

```bash
# Ver URL del dashboard
aws cloudwatch list-dashboards

# Crear alarms
aws cloudwatch put-metric-alarm \
  --alarm-name fraud-api-high-latency \
  --metric-name InferenceLatency \
  --threshold 200 \
  --comparison-operator GreaterThanThreshold
```

### Logs

```bash
# Ver logs en tiempo real
aws logs tail /fraud-detection/production --follow

# Filtrar por error
aws logs filter-log-events \
  --log-group-name /fraud-detection/production \
  --filter-pattern "ERROR"
```

---

## 🤝 Contributing

1. Fork el repositorio
2. Crea una rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📞 Contacto

- **Data Science Team:** data-science@dinersclub.com
- **Issues:** GitHub Issues
- **Documentation:** Ver [TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md)

---

## 📄 Licencia

MIT License - Ver [LICENSE](LICENSE) para detalles.

---

## 🎯 Roadmap

- [ ] Implementar modelo real (XGBoost/LightGBM)
- [ ] Crear GitHub Actions CI/CD
- [ ] Agregar API key authentication
- [ ] Implementar rate limiting
- [ ] Agregar soportepara SHAP explainability
- [ ] Dashboard Grafana
- [ ] Database para audit logs
- [ ] A/B testing framework

---

**Última actualización:** Febrero 23, 2026  
**Version:** 2024.11  
**Status:** ✅ Production Ready
