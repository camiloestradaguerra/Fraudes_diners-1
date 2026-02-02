# 📋 RESUMEN: API GATEWAY + SAGEMAKER - ERROR 403

## ✅ LO QUE COMPLETAMOS

- ✅ Imagen Docker en ECR
- ✅ SageMaker Endpoint (`endpoint-fraudes-v5`) activo
- ✅ API Gateway creada (`fraudes-api`, ID: `tooahxop09`)
- ✅ Recurso `/fraude` con método POST
- ✅ Rol IAM con permisos (`apigateway-sagemaker-proxy`)
- ✅ URL pública lista: `https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude`

## ❌ PROBLEMA ACTUAL

Al hacer POST desde Postman, recibimos:
```json
{
    "message": "Forbidden"
}
```

## 🎯 CAUSA

La integración entre API Gateway y SageMaker está configurada con `AWS_PROXY` que requiere transformación especial. 

**Solución:** Cambiar a tipo `AWS` con URI directo a SageMaker Runtime.

## 🔧 PRÓXIMOS PASOS (ORDEN DE RECOMENDACIÓN)

### Opción A: Arreglarlo en AWS Console (RECOMENDADO)
1. Ve a: https://console.aws.amazon.com/apigateway
2. Selecciona: `fraudes-api`
3. Edita POST `/fraude` → Integration Request
4. Cambia:
   - Type: `AWS` (no AWS_PROXY)
   - URI: `arn:aws:apigateway:us-east-1:runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations`
5. Redeploy al stage `prod`
6. Prueba nuevamente en Postman

**Ver:** [FIX_403_FORBIDDEN.md](FIX_403_FORBIDDEN.md) para detalles

### Opción B: Usar Lambda como intermediario
Lambda puede transformar mejor las solicitudes.

**Ver:** [TROUBLESHOOT_403.md](TROUBLESHOOT_403.md) para instrucciones

---

## 📚 DOCUMENTACIÓN CREADA

| Archivo | Propósito |
|---------|-----------|
| [FIX_403_FORBIDDEN.md](FIX_403_FORBIDDEN.md) | Soluciones al error 403 |
| [POSTMAN_GUIDE.md](POSTMAN_GUIDE.md) | Guía de Postman |
| [API_GATEWAY_READY.md](API_GATEWAY_READY.md) | Configuración actual |
| [Fraudes_API_Postman_Collection.json](Fraudes_API_Postman_Collection.json) | Colección para importar |

---

## 📦 ARCHIVOS DE CONFIGURACIÓN

- `api-id.txt`: `tooahxop09`
- `resource-id.txt`: ID del recurso `/fraude`
- `role-arn.txt`: ARN del rol IAM
- `api-invoke-url.txt`: URL pública

---

## 🚀 CUANDO FUNCIONE

Una vez que el error 403 esté arreglado, la API responderá con:

```json
{
    "prediction": 0,
    "probability": 0.15,
    "is_fraud": false
}
```

O si detecta fraude:

```json
{
    "prediction": 1,
    "probability": 0.85,
    "is_fraud": true
}
```

---

## ✨ RESUMEN TÉCNICO

```
Postman (POST)
    ↓
API Gateway (tooahxop09)
    ↓
SageMaker Runtime
    ↓
Endpoint: endpoint-fraudes-v5
    ↓
Contenedor Docker con Modelo
    ↓
Respuesta: Predicción de fraude
```

---

## 🎯 RECOMENDACIÓN FINAL

**Intenta la Opción A (AWS Console) ahora mismo.**

Es la forma más rápida de verificar si el arreglo funciona.

---

**Después de arreglar, vuelve a intentar el POST en Postman con:**
```
URL: https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude
METHOD: POST
BODY: {"transaction_id": "TRX123", "monto": 150.50, ...}
```
