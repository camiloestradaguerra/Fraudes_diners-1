# 🎉 API GATEWAY LISTA PARA USAR

## ✅ CONFIGURACIÓN COMPLETADA EXITOSAMENTE

Tu API Gateway ha sido creada y desplegada exitosamente en AWS.

---

## 📍 URL DEL ENDPOINT

```
https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude
```

---

## 🧪 INSTRUCCIONES PARA PROBAR EN POSTMAN

### 1. **Abrir Postman**
   - Si no lo tienes, descárgalo desde: https://www.postman.com/downloads/

### 2. **Crear Nueva Request**
   - Click en **"+"** o **"New"**
   - Selecciona **"HTTP"**

### 3. **Configurar la Solicitud**

**Método:**
```
POST
```

**URL:**
```
https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude
```

**Headers:**
```
Content-Type: application/json
```

**Body (selecciona "raw" y "JSON"):**
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

### 4. **Hacer Click en "Send"**

### 5. **Ver la Respuesta**
   - Deberías recibir la predicción de fraude del modelo de SageMaker

---

## 💻 ALTERNATIVA: PROBAR DESDE PYTHON/CURL

### Con Python:
```bash
python test_api_gateway.py
```

### Con cURL:
```bash
curl -X POST https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude \
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

---

## 📋 DETALLES TÉCNICOS

| Componente | Valor |
|---|---|
| **API ID** | `tooahxop09` |
| **Recurso** | `/fraude` |
| **Método** | `POST` |
| **Stage** | `prod` |
| **Integración** | AWS SageMaker Runtime |
| **Endpoint** | `endpoint-fraudes-v5` |
| **Región** | `us-east-1` |
| **IAM Role** | `apigateway-sagemaker-proxy` |

---

## ✨ FLUJO DE LA SOLICITUD

```
Postman/Cliente HTTP
    ↓
API Gateway (https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude)
    ↓
SageMaker Runtime InvokeEndpoint
    ↓
SageMaker Endpoint (endpoint-fraudes-v5)
    ↓
Contenedor Docker con tu modelo
    ↓
Respuesta: Predicción de fraude
```

---

## 🔧 SI HAY PROBLEMAS

### Error 403 (Forbidden)
- Verifica que la IAM Role tenga permisos

### Error 500 (Internal Server Error)
- El endpoint de SageMaker podría no estar en estado "InService"
- Verifica: `aws sagemaker describe-endpoint --endpoint-name endpoint-fraudes-v5`

### Error de Timeout
- El endpoint podría estar tardando en responder
- Aumenta el timeout en Postman o en tu cliente HTTP

---

## ✅ CONFIRMACIÓN DE CONFIGURACIÓN

```
Rol de IAM:                  ✅ apigateway-sagemaker-proxy
API Gateway:                 ✅ fraudes-api (ID: tooahxop09)
Recurso /fraude:             ✅ Creado
Método POST:                 ✅ Configurado
Integración SageMaker:       ✅ Configurada
Deployment:                  ✅ prod
Permisos:                    ✅ sagemaker:InvokeEndpoint
```

---

**🎊 ¡Tu API está lista para consumir!**

Próximo paso: Abre Postman y envía tu primera solicitud.
