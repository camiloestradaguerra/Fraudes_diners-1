# 🔍 Fraudes Diners - Detección de Fraudes con CloudFormation

**Sistema ML en tiempo real para detección de fraudes en AWS usando CloudFormation.**

---

## 🌟 ¿Qué es este Proyecto?

Un **sistema completo de detección de fraudes** que:
- ✅ Procesa transacciones en **<100ms** con ML
- ✅ Usa **CloudFormation** para crear infraestructura automática en AWS
- ✅ Implementa **API REST REST con API Gateway** y **SageMaker**
- ✅ Incluye **pipelines completos** de limpieza, feature engineering y training

### Diagrama de lo que CloudFormation Crea

```
Ejecutas:  aws cloudformation create-stack --template-body file://infra-sagemaker-complete.yaml
                                                    ↓
CloudFormation AUTOMÁTICAMENTE crea:
┌─────────────────────────────────────────────┐
│ 1. IAM Roles (permisos)                    │
│ 2. SageMaker Model (definición)            │
│ 3. SageMaker Endpoint (instancia)          │
│ 4. API Gateway (API pública HTTPS)         │
│ 5. Conecta todo automáticamente            │
│ 6. Retorna URL para usar                   │
└─────────────────────────────────────────────┘

Resultado: API en producción en <5 minutos
```

---

## 🚀 Quick Start

### 1. Local (Dev)
```bash
# Setup
curl -LsSf https://astral.sh/uv/install.sh | sh
git clone https://github.com/dinersclub/fraudes-diners.git
cd fraudes-diners
uv sync
source .venv/bin/activate

# Correr API
python endpoint_prototipo/main.py
curl http://localhost:8000/fraud/predict ...
```

### 2. Docker (Test)
```bash
docker build -t fraud-api:latest .
docker run -p 8000:8000 fraud-api:latest
```

### 3. AWS CloudFormation (Producción) ⭐
```bash
# 1. Build y push imagen a ECR
docker build -t fraud-api:latest .
docker tag ... {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest
docker push {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# 2. Deploy con CloudFormation
aws cloudformation create-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters ParameterKey=ImageUri,ParameterValue={ACCOUNT}.dkr.ecr...fraud-api:latest \
  --capabilities CAPABILITY_NAMED_IAM

# 3. CloudFormation crea TODO automáticamente
# 4. Obtener URL
aws cloudformation describe-stacks --stack-name fraud-detection-prod \
  --query 'Stacks[0].Outputs'

# 5. Ya puedes predecir
curl -X POST https://{api-url}/fraud/predict ...
```

---

## 📦 Gestión de Dependencias (uv)

```bash
# Agregar
uv add xgboost

# Desarrollo
uv add --dev pytest

# Remover
uv remove nombre-paquete

# Actualizar
uv sync --upgrade
```

---

## 📂 Documentación

| Documento | Contenido |
|-----------|-----------|
| **[TECHNICAL_DOCUMENTATION_CONCISE.md](TECHNICAL_DOCUMENTATION_CONCISE.md)** | ⭐ **10 páginas, foco CloudFormation** |
| **[TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md)** | 30 páginas, detalles completos |
| **[README_COMPLETO.md](README_COMPLETO.md)** | README profesional extenso |

---

## 🎯 Flujo CloudFormation Explicado

### Qué hace `infra-sagemaker-complete.yaml`:

```yaml
Template: infra-sagemaker-complete.yaml
    ↓
Inputs (parámetros):
  - ImageUri: "tu-imagen-docker-en-ecr"
  - InstanceType: "ml.m5.large" (configurable)
    ↓
CloudFormation CREA:
  1. SageMakerExecutionRole
     └─ Permisos: ECR, CloudWatch, S3
  
  2. APIGatewaySageMakerRole
     └─ Permisos: invocar SageMaker
  
  3. SageMaker::Model (fraudes-model)
     └─ Apunta a: tu imagen Docker
  
  4. SageMaker::EndpointConfig
     └─ Configura: instancia, réplicas
  
  5. SageMaker::Endpoint (VIVO)
     └─ Ejecuta: tu modelo en máquina
  
  6. ApiGateway::RestApi
     └─ Crea: API HTTPS pública
  
  7. ApiGateway::Resource (/fraude)
     └─ Path: /fraude
  
  8. ApiGateway::Method (POST)
     └─ POST /fraude → SageMaker endpoint
  
  9. ApiGateway::Deployment
     └─ Publica: en stage "prod"
    ↓
Outputs (lo que retorna):
  - ApiInvokeUrl: https://abc.../prod/fraude ← USA ESTO
  - EndpointName: endpoint-fraudes-prod
  - ModelName: fraudes-model-prod
```

### Conexión Real

```
Cliente HTTP:
POST https://abc123.execute-api.us-east-1.amazonaws.com/prod/fraude
  {"transaction_id": "TRX-001", "monto": 150, ...}
        ↓
API Gateway (creada por CloudFormation)
        ↓
SageMaker Endpoint (creado por CloudFormation)
        ↓
Docker Container (ejecutando main.py)
        ↓
FastAPI → predice → retorna score
        ↓
Respuesta JSON al cliente
```

---

## 🏗️ Estructura del Proyecto

```
fraudes_diners/
├── 📄 infra-sagemaker-complete.yaml    ← CLOUDFORMATION (✨ PRINCIPAL)
├── 🐳 Dockerfile                       ← Imagen Docker
├── 📁 endpoint_prototipo/              ← API FastAPI
│   ├── main.py
│   ├── schemas.py
│   └── routers/
├── 📁 src/pipelines/                   ← ML Pipelines
├── 📚 TECHNICAL_DOCUMENTATION_CONCISE.md
├── 📚 TECHNICAL_DOCUMENTATION.md
└── README.md (este archivo)
```

---

## 🔧 Desarrollo Local

```bash
# 1. Setup
source .venv/bin/activate

# 2. Ejecutar API
uvicorn endpoint_prototipo.main:app --reload

# 3. Testear
curl http://localhost:8000/health/
curl -X POST http://localhost:8000/fraud/predict ...

# 4. Ver docs
# Abre: http://localhost:8000/docs (Swagger)
```

---

## ☁️ Despliegue en AWS

Toda la infraestructura se crea automáticamente con CloudFormation:

```bash
# Step 1: Build Docker
docker build -t fraud-api:latest .

# Step 2: Push a ECR (registro Docker en AWS)
docker push {ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/fraud-api:latest

# Step 3: CloudFormation crea TODO
aws cloudformation create-stack \
  --stack-name fraud-detection-prod \
  --template-body file://infra-sagemaker-complete.yaml \
  --parameters ParameterKey=ImageUri,ParameterValue=... \
  --capabilities CAPABILITY_NAMED_IAM

# ✨ CloudFormation automáticamente:
#    - Crea IAM roles
#    - Crea SageMaker model
#    - Crea SageMaker endpoint
#    - Crea API Gateway
#    - Conecta todo
#    - Retorna URL

# Step 4: Usar
curl -X POST https://{ApiInvokeUrl} ...
```

---

## 📖 Documentación Técnica

### Para Entender CloudFormation
→ **[TECHNICAL_DOCUMENTATION_CONCISE.md](TECHNICAL_DOCUMENTATION_CONCISE.md)** (10 páginas)

### Para Detalles Completos
→ **[TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md)** (30 páginas)

---

**Status:** ✅ Production Ready  
**Última actualización:** Febrero 2026

### 📓 Jupyter Notebooks

Para usar Jupyter con el ambiente virtual:

**1. Registrar el kernel (solo primera vez):**
```bash
./register_kernel.sh
```

O manualmente:
```bash
source .venv/bin/activate
python -m ipykernel install --user --name=fraudes-diners --display-name="Python 3.12 (fraudes-diners)"
```

**2. Ejecutar Jupyter:**
```bash
uv run jupyter lab
```

O activar el ambiente y luego:

```bash
source .venv/bin/activate
jupyter lab
```

**3. En VS Code:**
- Abre el notebook
- Haz clic en "Select Kernel" (esquina superior derecha)
- Selecciona "Python 3.12 (fraudes-diners)"

Ver [KERNEL_SETUP.md](KERNEL_SETUP.md) para más detalles.

### 📂 Estructura del Proyecto

```
fraudes_diners/
├── src/
│   └── pipelines/
│       ├── 0-cleaning_data/
│       ├── 1-data_sampling/
│       ├── 2-feature_engineering/
│       ├── 3-training/
│       ├── 4-evaluation/
│       └── 5-model_registry/
├── notebooks/
├── pyproject.toml          # Configuración del proyecto y dependencias
├── setup.sh                # Script de configuración rápida
└── README.md
```

### 🛠️ Dependencias Principales

- **pandas**: Manipulación y análisis de datos
- **numpy**: Computación numérica
- **scikit-learn**: Machine learning
- **matplotlib & seaborn**: Visualización
- **jupyter**: Notebooks interactivos
- **boto3 & awscli**: Integración con AWS

### 💡 Ventajas de usar uv

- ⚡ **10-100x más rápido** que pip
- 🔒 Resolución de dependencias determinista
- 🎯 Compatible con pip y requirements.txt
- 📦 Gestión integrada de ambientes virtuales
- 🚀 Sin necesidad de instalar virtualenv o venv

### 📝 Notas

- El archivo `pyproject.toml` define todas las dependencias del proyecto
- El ambiente virtual se crea automáticamente en `.venv/`
- No es necesario commitear `.venv/` al repositorio (está en `.gitignore`)
