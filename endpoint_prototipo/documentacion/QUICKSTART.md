# 🚀 Quick Start - Fraud Detection API

## Inicio Rápido

### 1️⃣ Verificar que las dependencias están instaladas

```bash
pip install -r requirements.txt
```

### 2️⃣ Iniciar la API

```bash
python main.py
```

Deberías ver:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### 3️⃣ Probar la API

#### Opción A: Usar Swagger UI (Recomendado)
Abre tu navegador en: http://localhost:8000/docs

Aquí puedes probar todos los endpoints de forma interactiva.

#### Opción B: Usar cURL

```bash
# Health Check
curl http://localhost:8000/health/

# Predicción de fraude (transacción de bajo riesgo)
curl -X POST "http://localhost:8000/fraud/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX001",
    "monto": 50.00,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestauranteCafe",
    "especialidad": "RESTAURANTES"
  }'

# Predicción de fraude (transacción de alto riesgo)
curl -X POST "http://localhost:8000/fraud/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX002",
    "monto": 8500.00,
    "edad": 82,
    "ciudad": "Guayaquil",
    "establecimiento": "TiendaDesconocida",
    "especialidad": "ELECTRONICA"
  }'
```

#### Opción C: Usar Python

```python
import requests

response = requests.post(
    "http://localhost:8000/fraud/predict",
    json={
        "transaction_id": "TRX123",
        "monto": 150.50,
        "edad": 35,
        "ciudad": "Quito",
        "establecimiento": "RestaurantXYZ",
        "especialidad": "RESTAURANTES"
    }
)

result = response.json()
print(f"Fraud Score: {result['ml_score_0_999']}")
print(f"Request ID: {result['request_id']}")
```

#### Opción D: Ejecutar script de pruebas

```bash
python test_fraud_api.py
```

## 📊 Interpretar los Resultados

El `ml_score_0_999` indica el nivel de riesgo:

| Score | Interpretación | Acción |
|-------|---|---|
| 0-100 | ✅ Muy bajo riesgo | Aprobar automáticamente |
| 101-300 | ⚠️ Riesgo bajo | Posible aprobación |
| 301-600 | 🔶 Riesgo moderado | Revisar manualmente |
| 601-800 | 🔴 Riesgo alto | Bloquear/Investigar |
| 801-999 | 🛑 Muy alto riesgo | Bloquear inmediatamente |

## 📚 Documentación Completa

- **[CAMBIOS_REALIZADOS.md](CAMBIOS_REALIZADOS.md)** - Resumen de cambios
- **[FRAUD_API_README.md](FRAUD_API_README.md)** - Documentación detallada
- **[API_EXAMPLES.json](API_EXAMPLES.json)** - Ejemplos en JSON

## 🔧 Integración con Tu Modelo

El endpoint actualmente usa una predicción **mock** simple. Para integrar tu modelo de fraude:

1. Abre [routers/fraud_prediction.py](routers/fraud_prediction.py)
2. Edita la función `load_model()`:
   ```python
   def load_model():
       global MODEL, DEVICE
       import joblib
       MODEL = joblib.load('path/to/your/fraud_model.pkl')
   ```
3. Edita la función `predict_fraud()` para usar tu modelo real:
   ```python
   # Reemplazar la línea de predicción mock con:
   fraud_score = MODEL.predict([...features...])[0]
   ```

## 📡 Endpoints Disponibles

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health/` | Verificar estado de la API |
| POST | `/fraud/predict` | Predicción para una transacción |
| POST | `/fraud/batch-predict` | Predicción para múltiples transacciones |
| GET | `/docs` | Swagger UI (documentación interactiva) |
| GET | `/redoc` | ReDoc (documentación alternativa) |

## ❓ Problemas Comunes

### Error: "Port 8000 already in use"
Cambia el puerto en `main.py`:
```python
uvicorn.run(app, host="0.0.0.0", port=8001)  # Usa otro puerto
```

### Error: "Model not loaded"
Asegúrate de que el modelo se carga correctamente en `load_model()`

### ImportError: No module named 'entrypoint'
La estructura de carpetas debe estar correcta. El script debe ejecutarse desde el directorio padre de `endpoint_prototipo`.

## 🎯 Próximos Pasos

1. Integra tu modelo de fraude real
2. Ajusta los campos de request según tus necesidades
3. Calibra los thresholds de riesgo
4. Deseña en producción (AWS SageMaker, Docker, etc.)

## 💡 Consejos

- Usa Swagger UI (`/docs`) para pruebas rápidas
- Revisa los logs de Uvicorn para debug
- Implementa logging adicional en `predict_fraud()`
- Considera agregar autenticación/tokens para producción

¡Listo para usar! 🎉
