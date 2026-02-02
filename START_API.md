# Guía de Ejecución - Fraud Detection API

## ✅ Estado Actual
La FastAPI está **completamente funcional** sin Terraform ni IaC. 

## 🚀 Ejecución Local

### Opción 1: Con uvicorn (Recomendado para desarrollo)
```bash
cd Fraudes_diners
python -m uvicorn endpoint_prototipo.main:app --host 127.0.0.1 --port 8000 --reload
```

### Opción 2: Script Python directo
```bash
cd Fraudes_diners
python endpoint_prototipo/main.py
```

## 📍 Acceder a la API

### Endpoints principales:
- **Health Check**: `http://localhost:8000/health`
- **Swagger UI (Docs)**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **Raíz**: `http://localhost:8000/`

### Ejemplos de uso:

#### 1. Health Check
```bash
curl -X GET http://localhost:8000/health
```

#### 2. Predicción de Fraude (POST)
```bash
curl -X POST http://localhost:8000/fraud/predict \
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

#### 3. Batch Prediction
```bash
curl -X POST http://localhost:8000/fraud/batch-predict \
  -H "Content-Type: application/json" \
  -d '[
    {
      "transaction_id": "TRX001",
      "monto": 100.0,
      "edad": 25,
      "ciudad": "Quito",
      "establecimiento": "Store1",
      "especialidad": "GENERAL"
    },
    {
      "transaction_id": "TRX002",
      "monto": 5000.0,
      "edad": 45,
      "ciudad": "Guayaquil",
      "establecimiento": "Store2",
      "especialidad": "GENERAL"
    }
  ]'
```

## 📊 Respuesta de Predicción

```json
{
  "schema_version": "1.0",
  "request_id": "REQ-ABC12",
  "ml_score_0_999": 301.0,
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": 2.34
}
```

## 🔧 Cambios Realizados

### Correcciones de Compatibilidad
- ✅ Migrado de `@router.on_event("startup")` a `lifespan` context manager
- ✅ Agregado `model_config = {"protected_namespaces": ()}` en esquemas Pydantic
- ✅ Actualizado FastAPI 0.108.0 y Uvicorn 0.25.0

### Dependencias Instaladas
```
fastapi==0.108.0
uvicorn[standard]==0.25.0
pydantic==2.5.3
torch==2.1.0
pandas==2.1.3
numpy==1.26.2
joblib==1.3.2
pyarrow==14.0.1
```

## 🌐 Próximos Pasos: Migración a CloudFormation

### Plan de Migración
1. **Dockerizar la aplicación** (Dockerfile ya existe)
2. **Crear plantilla CloudFormation** con:
   - ECS Cluster
   - ECS Task Definition
   - ECS Service
   - ALB (Application Load Balancer)
   - Auto Scaling Group
   - ECR Repository para imágenes Docker

3. **Eliminar Terraform** (directorio `/terraform`)

### Archivos a Crear
- `cloudformation/fraud-detection-api-template.yaml`
- `cloudformation/deploy.sh` (script de deployment)
- `cloudformation/parameters.json` (configuración de parámetros)

## ⚠️ Notas de Seguridad

- La API actual usa CORS con `allow_origins=["*"]` (permitir todos los orígenes)
- **Para producción**: Restringir a dominios específicos
- El modelo es un placeholder - implementar carga real del modelo en producción
- Añadir autenticación (JWT, API Keys, etc.)

## 📝 TODO

- [ ] Implementar carga real del modelo
- [ ] Añadir autenticación a los endpoints
- [ ] Configurar logging en producción
- [ ] Crear tests unitarios
- [ ] Crear plantilla CloudFormation
- [ ] Documentar variables de entorno
- [ ] Crear script de deployment
