# Fraud Detection API

API en tiempo real para predicción de fraude en transacciones.

## Descripción

Este endpoint proporciona predicciones de probabilidad de fraude para transacciones, devolviendo un score de riesgo en escala 0-999 junto con metadatos del modelo e información de latencia.

## Estructura de Respuesta

Todas las predicciones de fraude devuelven el siguiente JSON:

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

### Campos de Respuesta

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `schema_version` | string | Versión del esquema API (ej: "1.0") |
| `request_id` | string | Identificador único de la solicitud |
| `ml_score_0_999` | float | Score de riesgo de fraude (0-999, donde 999 = máximo riesgo) |
| `model_meta` | object | Metadatos del modelo utilizado |
| `model_meta.name` | string | Nombre del modelo |
| `model_meta.version` | string | Versión del modelo |
| `model_meta.provider` | string | Proveedor del modelo |
| `latency_ms` | float | Tiempo de inferencia en milisegundos |

## Endpoints

### 1. Predicción Individual

**POST** `/fraud/predict`

Predice la probabilidad de fraude para una transacción individual.

#### Request

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

#### Ejemplo con curl

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

#### Response

```json
{
    "schema_version": "1.0",
    "request_id": "REQ-A1B2C",
    "ml_score_0_999": 301.0,
    "model_meta": {
        "name": "fraud_model_prod",
        "version": "2024.11",
        "provider": "ExternalVendor"
    },
    "latency_ms": 12.5
}
```

### 2. Predicción en Lote (Batch)

**POST** `/fraud/batch-predict`

Predice la probabilidad de fraude para múltiples transacciones en una sola solicitud.

#### Request

```json
[
    {
        "transaction_id": "TRX123456",
        "monto": 150.50,
        "edad": 35,
        "ciudad": "Quito",
        "establecimiento": "RestaurantXYZ",
        "especialidad": "RESTAURANTES"
    },
    {
        "transaction_id": "TRX123457",
        "monto": 5000.00,
        "edad": 72,
        "ciudad": "Guayaquil",
        "establecimiento": "JoyeriaXYZ",
        "especialidad": "JOYERIAS"
    }
]
```

#### Response

```json
[
    {
        "schema_version": "1.0",
        "request_id": "REQ-X1Y2Z",
        "ml_score_0_999": 301.0,
        "model_meta": {
            "name": "fraud_model_prod",
            "version": "2024.11",
            "provider": "ExternalVendor"
        },
        "latency_ms": 12.5
    },
    {
        "schema_version": "1.0",
        "request_id": "REQ-A2B3C",
        "ml_score_0_999": 775.0,
        "model_meta": {
            "name": "fraud_model_prod",
            "version": "2024.11",
            "provider": "ExternalVendor"
        },
        "latency_ms": 15.3
    }
]
```

### 3. Health Check

**GET** `/health/`

Verifica el estado de salud de la API y si el modelo está cargado.

#### Response

```json
{
    "status": "healthy",
    "model_loaded": true,
    "version": "1.0.0"
}
```

## Instalación y Ejecución

### 1. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 2. Ejecutar la API

```bash
python main.py
```

La API estará disponible en `http://localhost:8000`

### 3. Acceder a la documentación interactiva

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Campos de Request

| Campo | Tipo | Requerido | Descripción | Ejemplo |
|-------|------|-----------|-------------|---------|
| `transaction_id` | string | Sí | ID único de la transacción | "TRX123456" |
| `monto` | float | Sí | Monto de la transacción (> 0) | 150.50 |
| `edad` | int | Sí | Edad del cliente (18-120) | 35 |
| `ciudad` | string | Sí | Ciudad de la transacción | "Quito" |
| `establecimiento` | string | Sí | Nombre del establecimiento | "RestaurantXYZ" |
| `especialidad` | string | No | Tipo de establecimiento | "RESTAURANTES" |

## Interpretación del Score

El `ml_score_0_999` indica el nivel de riesgo de fraude:

- **0-100**: Riesgo muy bajo - Transacción probablemente legítima
- **101-300**: Riesgo bajo - Transacción sospechosa pero probablemente legítima
- **301-600**: Riesgo moderado - Requiere revisión adicional
- **601-800**: Riesgo alto - Probablemente fraudulenta
- **801-999**: Riesgo muy alto - Muy probablemente fraudulenta

## Códigos de Error

| Código | Descripción |
|--------|-------------|
| 200 | Predicción exitosa |
| 400 | Solicitud inválida (datos faltantes o inválidos) |
| 503 | Modelo no cargado - Servicio no disponible |
| 500 | Error interno del servidor |

## Ejemplo Python

```python
import requests

url = "http://localhost:8000/fraud/predict"

payload = {
    "transaction_id": "TRX123456",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
}

response = requests.post(url, json=payload)
result = response.json()

print(f"Request ID: {result['request_id']}")
print(f"Fraud Score: {result['ml_score_0_999']}")
print(f"Latency: {result['latency_ms']} ms")
print(f"Model: {result['model_meta']['name']} v{result['model_meta']['version']}")
```

## TODO: Integración del Modelo Real

Para integrar tu modelo de fraude actual, actualiza la función `predict_fraud` en [routers/fraud_prediction.py](routers/fraud_prediction.py):

1. Carga tu modelo en la función `load_model()`
2. Prepara los features en `predict_fraud()`
3. Ejecuta la predicción con tu modelo
4. Retorna el score normalizado a escala 0-999

Ejemplo:

```python
def load_model():
    global MODEL, DEVICE
    import joblib
    MODEL = joblib.load('path/to/your/model.pkl')

@router.post("/fraud/predict", response_model=FraudPredictionResponse)
async def predict_fraud(request: FraudPredictionRequest):
    # ... código existente ...
    
    # Preparar features
    features = prepare_features(request)
    
    # Predicción
    fraud_score = MODEL.predict(features)[0]
    
    # Normalizar a 0-999
    fraud_score = min(999, max(0, fraud_score * 999))
    
    # ... resto del código ...
```
