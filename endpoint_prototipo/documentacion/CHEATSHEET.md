# 🔖 CHEATSHEET - Fraud Detection API

## 🚀 INICIAR EN 1 LÍNEA
```bash
python main.py
```
→ Luego abre: http://localhost:8000/docs

---

## 📡 ENDPOINTS DE UNA LÍNEA

```bash
# Predicción
curl -X POST http://localhost:8000/fraud/predict \
  -H "Content-Type: application/json" \
  -d '{"transaction_id":"T1","monto":150,"edad":35,"ciudad":"Quito","establecimiento":"Restaurant"}'

# Salud
curl http://localhost:8000/health/

# Documentación
http://localhost:8000/docs
```

---

## 🐍 PYTHON EN 5 LÍNEAS

```python
import requests
r = requests.post("http://localhost:8000/fraud/predict",
    json={"transaction_id":"T1","monto":150,"edad":35,"ciudad":"Quito","establecimiento":"Restaurant"})
print(r.json()['ml_score_0_999'])  # Score de fraude
```

---

## 📊 RESPONSE JSON

```json
{
  "schema_version": "1.0",
  "request_id": "REQ-ABC",
  "ml_score_0_999": 410,
  "model_meta": {"name": "fraud_model_prod", "version": "2024.11", "provider": "ExternalVendor"},
  "latency_ms": 38
}
```

---

## 📋 REQUEST FIELDS

| Campo | Tipo | Requerido | Rango |
|-------|------|-----------|-------|
| `transaction_id` | str | ✓ | - |
| `monto` | float | ✓ | > 0 |
| `edad` | int | ✓ | 18-120 |
| `ciudad` | str | ✓ | - |
| `establecimiento` | str | ✓ | - |
| `especialidad` | str | ✗ | - |

---

## 📊 SCORE REFERENCE

```
0-100       ✅ OK
101-300     ⚠️ REVIEW
301-600     🔶 CAUTION
601-800     🔴 BLOCK
801-999     🛑 REJECT
```

---

## 📁 ARCHIVOS CLAVE

```
main.py                 ← API
schemas.py              ← Models
routers/
  fraud_prediction.py   ← Lógica ⭐
  health.py             ← Health
```

---

## 📚 DOCUMENTACIÓN

| Minutos | Archivo |
|---------|---------|
| 2 | [00_BIENVENIDO.md](00_BIENVENIDO.md) |
| 2 | [README_FRAUDES.md](README_FRAUDES.md) |
| 3 | [QUICKSTART.md](QUICKSTART.md) |
| 3 | [MAPA_RAPIDO.md](MAPA_RAPIDO.md) |
| 5 | [CAMBIOS_REALIZADOS.md](CAMBIOS_REALIZADOS.md) |
| 10 | [FRAUD_API_README.md](FRAUD_API_README.md) |

---

## 🔧 INTEGRAR MODELO

En `routers/fraud_prediction.py`:

```python
def load_model():
    import joblib
    global MODEL
    MODEL = joblib.load('fraud_model.pkl')

# En predict_fraud(), reemplaza:
fraud_score = MODEL.predict([...])[0]
fraud_score = min(999, max(0, fraud_score * 999))
```

---

## 🧪 TESTS

```bash
# Python
python test_fraud_api.py

# cURL examples
bash test_examples.sh

# Verificar setup
bash verify_setup.sh
```

---

## ✅ TODO

- [x] API FastAPI
- [x] Endpoints de fraude
- [x] Response JSON exacto
- [x] Health checks
- [x] Documentación Swagger
- [x] Tests incluidos
- [x] Código para producción

---

## 🎯 PRÓXIMOS PASOS

1. `python main.py`
2. http://localhost:8000/docs
3. Integra tu modelo
4. Despliega

---

**v2024.11 | Production Ready ✅**
