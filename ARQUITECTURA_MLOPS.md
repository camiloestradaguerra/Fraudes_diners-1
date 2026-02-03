# Arquitectura MLOps Completa - Diagrama de Flujo

## 🏗️ Diagrama Arquitectura Completa

```
┌──────────────────────────────────────────────────────────────────────┐
│                         DESARROLLO LOCAL                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────┐    ┌──────────────────────────────────────┐   │
│  │  Dockerfile     │    │  Código Python (FastAPI)            │   │
│  │                 │    │  - main.py                           │   │
│  │  FROM python... │────│  - schemas.py                        │   │
│  │  COPY . .       │    │  - routers/fraud_prediction.py       │   │
│  │  CMD python...  │    │  - requirements.txt                  │   │
│  └─────────────────┘    └──────────────────────────────────────┘   │
│           │                                                          │
│           │ (Dockerfile + Código)                                   │
│           ↓                                                          │
│      ┌────────────────────────────────────────┐                    │
│      │   docker build                         │                    │
│      │   -t fraudes-diners-v5:latest .       │                    │
│      └────────────────────────────────────────┘                    │
│           │                                                          │
│           ↓                                                          │
│      ┌────────────────────────────────────────┐                    │
│      │  Imagen Docker Local                   │                    │
│      │  fraudes-diners-v5:latest              │                    │
│      │  (2.4 GB - optimizada con .dockerignore)                    │
│      └────────────────────────────────────────┘                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                             │
                             │ (docker push)
                             ↓
        ┌────────────────────────────────────────────┐
        │          AWS ACCOUNT (761951921633)        │
        ├────────────────────────────────────────────┤
        │                                            │
        │  ┌──────────────────────────────────────┐  │
        │  │   ECR Repository                     │  │
        │  │   fraudes-diners-v5                  │  │
        │  │                                      │  │
        │  │   URI: 761951921633.dkr.ecr...      │  │
        │  └──────────────────────────────────────┘  │
        │             │                              │
        │             │ (SageMaker pulls)            │
        │             ↓                              │
        │  ┌──────────────────────────────────────┐  │
        │  │   SageMaker Model                    │  │
        │  │   fraudes-model-fraudes-api          │  │
        │  │                                      │  │
        │  │   Código: main.py (lógica fraude)    │  │
        │  │   Tipo: Python (no sklearn/xgb)      │  │
        │  └──────────────────────────────────────┘  │
        │             │                              │
        │             │                              │
        │             ↓                              │
        │  ┌──────────────────────────────────────┐  │
        │  │   SageMaker Endpoint                 │  │
        │  │   endpoint-fraudes-api               │  │
        │  │                                      │  │
        │  │   Instancia: ml.m5.large             │  │
        │  │   Estado: InService                  │  │
        │  │   Runtime: runtime.sagemaker (AWS)   │  │
        │  └──────┬───────────────────────────────┘  │
        │         │                                  │
        │         │ (Request interno)                │
        │         ↓                                  │
        │  ┌──────────────────────────────────────┐  │
        │  │   API Gateway                        │  │
        │  │   https://xyz123.execute-api...      │  │
        │  │                                      │  │
        │  │   - POST /fraude                     │  │
        │  │   - Integración: SageMaker           │  │
        │  │   - Credenciales: IAM Role ✓        │  │
        │  │   - Status: 200 OK                   │  │
        │  └──────┬───────────────────────────────┘  │
        │         │                                  │
        │         │ (Respuesta HTTPS)                │
        │         ↓                                  │
        │    ┌────────────────────────┐             │
        │    │   IAM Role             │             │
        │    │   apigateway-sagemaker │             │
        │    │   fraudes-api          │             │
        │    │                        │             │
        │    │   - Trust: API Gateway │             │
        │    │   - Permisos:          │             │
        │    │     sagemaker:Invoke   │             │
        │    └────────────────────────┘             │
        │                                            │
        └────────────────────────────────────────────┘
                             │
                             │ (HTTPS - Pública)
                             ↓
        ┌─────────────────────────────────────────┐
        │        CLIENTE (Tu aplicación)          │
        ├─────────────────────────────────────────┤
        │                                         │
        │  POST /fraude                           │
        │  {                                      │
        │    "transaction_id": "TRX-123",         │
        │    "monto": 150.5,                      │
        │    "edad": 35,                          │
        │    "ciudad": "Quito",                   │
        │    "establecimiento": "Restaurant",     │
        │    "especialidad": "RESTAURANTES"       │
        │  }                                      │
        │             ↓                           │
        │  Response: 200 OK                       │
        │  {                                      │
        │    "schema_version": "1.0",             │
        │    "request_id": "REQ-123",              │
        │    "ml_score_0_999": 301.0,              │
        │    "model_meta": {...}                  │
        │  }                                      │
        │                                         │
        └─────────────────────────────────────────┘
```

---

## 🔄 Flujo Paso a Paso del Pipeline

### **Ejecución: `python deploy-completo.py --stack-name fraudes-api`**

```
┌─────────────────────────────────────────────────────────────┐
│  PASO 1: DOCKER BUILD                                       │
├─────────────────────────────────────────────────────────────┤
│  Acción: docker build -t fraudes-diners-v5:latest .         │
│  Entrada: Dockerfile + endpoint_prototipo/                  │
│  Salida: Imagen local lista                                 │
│  Tiempo: ~5 minutos                                         │
│  ✓ Automático                                               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  PASO 2: ECR SETUP                                          │
├─────────────────────────────────────────────────────────────┤
│  Acción: Crear repositorio ECR (si no existe)              │
│  Comando: aws ecr create-repository                         │
│  Resultado: ECR listo                                       │
│  Tiempo: ~10 segundos                                       │
│  ✓ Automático                                               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  PASO 3: DOCKER PUSH A ECR                                  │
├─────────────────────────────────────────────────────────────┤
│  Acciones:                                                  │
│  1. docker login (obtener credenciales ECR)                 │
│  2. docker tag (etiquetar con URI ECR)                      │
│  3. docker push (subir imagen)                              │
│  Resultado: Imagen en la nube                               │
│  Tiempo: ~2-5 minutos                                       │
│  ✓ Automático                                               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  PASO 4: IAM SETUP                                          │
├─────────────────────────────────────────────────────────────┤
│  Acciones:                                                  │
│  1. Crear rol: sagemaker-execution-fraudes-api              │
│  2. Adjuntar: AmazonSageMakerFullAccess                     │
│  3. Adjuntar: AmazonEC2ContainerRegistryReadOnly            │
│  Resultado: Rol con permisos                                │
│  Tiempo: ~10 segundos                                       │
│  ✓ Automático                                               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  PASO 5: CLOUDFORMATION DEPLOY                              │
├─────────────────────────────────────────────────────────────┤
│  Archivo: infra-sagemaker-complete.yaml                     │
│  Parámetros:                                                │
│  - ImageUri: [ECR_URI]                                      │
│  - SageMakerRoleArn: [ARN]                                  │
│                                                             │
│  Recursos creados en orden:                                 │
│  1. SageMaker Model                                         │
│  2. SageMaker EndpointConfig                                │
│  3. SageMaker Endpoint ← (ESPERA aquí ~15 min)             │
│  4. IAM Role (API Gateway)                                  │
│  5. IAM Policy (permisos)                                   │
│  6. API Gateway REST API                                    │
│  7. API Gateway Resource (/fraude)                          │
│  8. API Gateway Method (POST)                               │
│  9. API Gateway Deployment (prod)                           │
│                                                             │
│  Resultado: Sistema completo                                │
│  Tiempo: ~15-20 minutos                                     │
│  ✓ Automático                                               │
└─────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  SALIDA FINAL                                               │
├─────────────────────────────────────────────────────────────┤
│  Archivos generados:                                        │
│  - api-invoke-url.txt (URL pública)                         │
│  - endpoint-name.txt (nombre endpoint)                      │
│  - deployment-config.json (configuración)                   │
│                                                             │
│  Estado: ✅ READY FOR USE                                  │
│  Duración total: ~25-30 minutos                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Matriz: Quién Hace Qué

| Componente | Responsable | Automatizado |
|-----------|------------|--------------|
| Docker Build | Script Python (subprocess) | ✅ SÍ |
| ECR Repo | Script Python (boto3) | ✅ SÍ |
| Docker Push | Script Python (subprocess) | ✅ SÍ |
| IAM Role (SageMaker) | Script Python (boto3) | ✅ SÍ |
| SageMaker Model | CloudFormation | ✅ SÍ |
| SageMaker Endpoint | CloudFormation | ✅ SÍ |
| IAM Role (API Gateway) | CloudFormation | ✅ SÍ |
| API Gateway | CloudFormation | ✅ SÍ |
| **TOTAL** | **100% Automático** | **✅ SÍ** |

---

## 🔐 Seguridad en la Arquitectura

```
┌─────────────────────────────────────────────────────┐
│  CLIENTE (Internet)                                 │
└────────────────┬──────────────────────────────────┘
                 │
                 │ HTTPS (encriptado)
                 │
┌────────────────▼──────────────────────────────────┐
│  API GATEWAY                                       │
│  - Autenticación: NONE (opcional: agregar API Key)│
│  - Rate limiting: Disponible                       │
│  - Logging: CloudWatch                             │
└────────────────┬──────────────────────────────────┘
                 │
                 │ Request interno (AWS PrivateLink)
                 │
┌────────────────▼──────────────────────────────────┐
│  ASSUME ROLE (IAM)                                 │
│  Rol: apigateway-sagemaker-fraudes-api             │
│  Principal: apigateway.amazonaws.com               │
│  Permisos: sagemaker:InvokeEndpoint (específico)   │
└────────────────┬──────────────────────────────────┘
                 │
                 │ Invocación con credenciales
                 │
┌────────────────▼──────────────────────────────────┐
│  SAGEMAKER ENDPOINT                                │
│  - Ubicación: VPC de AWS (privada)                 │
│  - Acceso: Solo via IAM o Lambda/API Gateway       │
│  - Logs: CloudWatch                                │
└────────────────┬──────────────────────────────────┘
                 │
                 │ Respuesta
                 │
┌────────────────▼──────────────────────────────────┐
│  CLIENTE (Respuesta)                               │
└─────────────────────────────────────────────────────┘
```

---

## ✅ Checklist de Validación

Después de ejecutar `deploy-completo.py`:

```
┌─ DOCKER ─────────────────────────────────────────┐
│ [ ] docker images | grep fraudes-diners-v5        │
│     Resultado: Imagen local existe                │
└──────────────────────────────────────────────────┘

┌─ ECR ────────────────────────────────────────────┐
│ [ ] aws ecr describe-repositories                 │
│     Resultado: Repositorio fraudes-diners-v5      │
│                                                  │
│ [ ] aws ecr describe-images                       │
│     Resultado: Imagen con tag latest              │
└──────────────────────────────────────────────────┘

┌─ SAGEMAKER ──────────────────────────────────────┐
│ [ ] aws sagemaker describe-models                 │
│     Resultado: Model fraudes-model-fraudes-api    │
│                                                  │
│ [ ] aws sagemaker describe-endpoint               │
│     Resultado: Status = InService                 │
│     Endpoint Name = endpoint-fraudes-api          │
└──────────────────────────────────────────────────┘

┌─ API GATEWAY ────────────────────────────────────┐
│ [ ] aws apigateway get-rest-apis                  │
│     Resultado: API fraudes-api-prod               │
│                                                  │
│ [ ] curl $(cat api-invoke-url.txt)                │
│     Resultado: Status 200 OK + JSON response      │
└──────────────────────────────────────────────────┘

┌─ IAM ────────────────────────────────────────────┐
│ [ ] aws iam get-role --role-name sagemaker-...   │
│     Resultado: Rol existe                         │
│                                                  │
│ [ ] aws iam get-role --role-name apigateway-...  │
│     Resultado: Rol existe                         │
└──────────────────────────────────────────────────┘

┌─ CLOUDFORMATION ─────────────────────────────────┐
│ [ ] aws cloudformation describe-stacks            │
│     Resultado: Stack Status = CREATE_COMPLETE     │
└──────────────────────────────────────────────────┘
```

---

## 🚀 Comando Final

```bash
# Una línea que hace TODO
python deploy-completo.py --stack-name fraudes-api

# Resultado: Sistema MLOps completo y funcionando
# - Dockerfile compilado ✅
# - Imagen en ECR ✅
# - SageMaker Endpoint ready ✅
# - API Gateway pública ✅
# - Listo para requests ✅
```

---

**Arquitectura Versión**: 1.0  
**Última Actualización**: 2026-02-02  
**Documentación**: MLOPS_PIPELINE_COMPLETO.md
