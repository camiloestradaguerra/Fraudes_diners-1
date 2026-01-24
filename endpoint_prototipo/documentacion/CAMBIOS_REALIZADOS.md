# Resumen de Cambios - Endpoint de Predicción de Fraudes

## Descripción General
Se ajustó el endpoint prototipo de recomendaciones de establecimientos para convertirlo en un **endpoint de predicción de fraudes en tiempo real** que devuelve un score de riesgo entre 0-999 con los metadatos del modelo.

## Cambios Realizados

### 1. **schemas.py** - Nuevos esquemas Pydantic
   - ❌ Eliminados: `RecommendationRequest`, `RecommendationItem`, `RecommendationResponse`
   - ✅ Agregados: 
     - `FraudPredictionRequest` - Schema para solicitudes con campos de transacción
     - `FraudPredictionResponse` - Schema con la estructura JSON especificada
     - `ModelMeta` - Schema para metadatos del modelo
   
   **Estructura de respuesta JSON:**
   ```json
   {
       "schema_version": "1.0",
       "request_id": "REQ-99991",
       "ml_score_0_999": 410,
       "model_meta": {
           "name": "fraud_model_prod",
           "version": "2024.11",
           "provider": "ExternalVendor"
       },
       "latency_ms": 38
   }
   ```

### 2. **main.py** - Actualización de aplicación principal
   - ✅ Cambio de título: "RecSys V3 - Establecimientos Recommendation API" → "Fraud Detection API"
   - ✅ Cambio de descripción: Ahora describe predicción de fraudes
   - ✅ Versión actualizada: "1.0.0" → "2024.11"
   - ✅ Importación actualizada: `from entrypoint.routers import health, fraud_prediction`
   - ✅ Router registrado: Cambio de `recommendations` a `fraud_prediction`
   - ✅ Endpoint raíz actualizado con nueva descripción

### 3. **routers/fraud_prediction.py** - Nuevo router de predicción
   - ✅ Archivo creado completamente nuevo
   - **Endpoints implementados:**
     - `POST /fraud/predict` - Predicción individual
     - `POST /fraud/batch-predict` - Predicción en lote
   
   **Características:**
   - Generación automática de request_id único
   - Medición de latencia de inferencia
   - Predicción mock implementada (puede reemplazarse con modelo real)
   - Validación de entrada y manejo de errores
   - Load model en startup

### 4. **routers/health.py** - Sin cambios
   - ✅ Mantiene funcionalidad original
   - Endpoint `/health/` sigue disponible

## Campos de Request

| Campo | Tipo | Requerido | Validación | Ejemplo |
|-------|------|-----------|-----------|---------|
| `transaction_id` | string | Sí | - | "TRX123456" |
| `monto` | float | Sí | > 0 | 150.50 |
| `edad` | int | Sí | 18-120 | 35 |
| `ciudad` | string | Sí | - | "Quito" |
| `establecimiento` | string | Sí | - | "RestaurantXYZ" |
| `especialidad` | string | No | default: "GENERAL" | "RESTAURANTES" |

## Campos de Response

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `schema_version` | string | Versión del esquema (ej: "1.0") |
| `request_id` | string | ID único de solicitud (ej: "REQ-A1B2C") |
| `ml_score_0_999` | float | Score de fraude 0-999 |
| `model_meta.name` | string | Nombre del modelo |
| `model_meta.version` | string | Versión del modelo |
| `model_meta.provider` | string | Proveedor del modelo |
| `latency_ms` | float | Tiempo de inferencia en ms |

## Archivos Nuevos Creados

1. **FRAUD_API_README.md** - Documentación completa de la API
   - Explicación de endpoints
   - Ejemplos de request/response
   - Guía de instalación y ejecución
   - Interpretación de scores
   - Instrucciones para integración del modelo real

2. **test_fraud_api.py** - Script de pruebas Python
   - Tests de health check
   - Test de predicción individual
   - Test de predicción en batch
   - Test de transacciones de alto y bajo riesgo
   - Comparación de scores

3. **test_examples.sh** - Script bash con ejemplos cURL
   - Ejemplos de llamadas HTTP
   - Fácil prueba desde terminal

4. **API_EXAMPLES.json** - Ejemplos en JSON
   - Estructura de requests/responses
   - Interpretación de scores
   - Escenarios de ejemplo
   - Códigos de estado HTTP

## Cómo Usar

### 1. Iniciar la API
```bash
python main.py
```

### 2. Hacer una predicción
```bash
curl -X POST "http://localhost:8000/fraud/predict" \
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

### 3. Ver documentación interactiva
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Integración con Modelo Real

Para usar tu modelo de fraude actual, actualiza la función `load_model()` en [routers/fraud_prediction.py](routers/fraud_prediction.py):

```python
def load_model():
    global MODEL, DEVICE
    import joblib
    # Carga tu modelo actual
    MODEL = joblib.load('path/to/your/fraud_model.pkl')
```

Luego actualiza la predicción en `predict_fraud()`:

```python
# Preparar features
features = prepare_features(request)

# Predicción con tu modelo
fraud_score = MODEL.predict(features)[0]

# Normalizar a 0-999
fraud_score = min(999, max(0, fraud_score * 999))
```

## Diferencias Principales

| Aspecto | Anterior (Recomendaciones) | Nuevo (Fraudes) |
|---------|--------------------------|-----------------|
| Propósito | Recomendaciones de restaurantes | Predicción de fraude |
| Output | Lista de establecimientos | Score de riesgo 0-999 |
| Campos entrada | id_persona, hora, k | transaction_id, monto, edad |
| Latencia | - | Medida e incluida en respuesta |
| Request ID | - | Incluido en respuesta |
| Modelo meta | - | Nombre, versión, proveedor |

## Próximos Pasos

1. ✅ Reemplazar predicción mock con tu modelo real
2. ✅ Ajustar campos de request según tus necesidades
3. ✅ Integrar con tu pipeline de ML
4. ✅ Desplegar en AWS SageMaker (si es necesario)
5. ✅ Implementar logging y monitoreo

## Documentación Disponible

- 📄 [FRAUD_API_README.md](FRAUD_API_README.md) - Guía completa de la API
- 💾 [API_EXAMPLES.json](API_EXAMPLES.json) - Ejemplos en JSON
- 🧪 [test_fraud_api.py](test_fraud_api.py) - Script de pruebas Python
- 🔌 [test_examples.sh](test_examples.sh) - Ejemplos de cURL
