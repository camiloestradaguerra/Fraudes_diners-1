# 📮 GUÍA PARA PROBAR EN POSTMAN

## ✅ OPCIÓN 1: IMPORTAR LA COLECCIÓN (RECOMENDADO)

### Pasos:
1. **Abre Postman** (descarga desde https://www.postman.com/downloads/ si no lo tienes)

2. **Haz click en "File" en la esquina superior izquierda**
   ```
   File → Import
   ```

3. **Selecciona el archivo:**
   ```
   Fraudes_API_Postman_Collection.json
   ```
   (Está en tu carpeta del proyecto)

4. **¡Listo!** Verás 3 requests ya configuradas:
   - ✅ Test Fraude Detection (básico)
   - ✅ Test Fraude - Monto Alto
   - ✅ Test Fraude - Edad Baja

5. **Solo haz click en cualquier request y "Send"** ➡️

---

## 📝 OPCIÓN 2: CONFIGURAR MANUALMENTE

Si prefieres crear la request manualmente en Postman:

### Paso 1: Nueva Request
```
Click en "+" o "New" → "HTTP"
```

### Paso 2: Configura como POST
```
Método: POST
URL: https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude
```

### Paso 3: Headers
Ve a la pestaña "Headers" y asegúrate que esté:
```
Key:   Content-Type
Value: application/json
```

### Paso 4: Body
Ve a la pestaña "Body":
1. Selecciona **"raw"**
2. En el dropdown, selecciona **"JSON"**
3. Pega este JSON:

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

### Paso 5: Enviar
**Haz click en "Send"** (botón azul a la derecha)

### Paso 6: Ver Respuesta
La respuesta aparecerá en la parte inferior bajo "Response"

---

## 🧪 ESCENARIOS DE PRUEBA

### Test 1: Transacción Normal (Bajo riesgo)
```json
{
    "transaction_id": "TRX001",
    "monto": 50.00,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "Supermercado",
    "especialidad": "TIENDAS"
}
```
**Resultado esperado:** Probablemente NO es fraude

---

### Test 2: Transacción Sospechosa (Alto riesgo)
```json
{
    "transaction_id": "TRX002",
    "monto": 5000.00,
    "edad": 22,
    "ciudad": "New York",
    "establecimiento": "Casino",
    "especialidad": "ENTRETENIMIENTO"
}
```
**Resultado esperado:** Podría ser fraude

---

### Test 3: Transacción Muy Sospechosa
```json
{
    "transaction_id": "TRX003",
    "monto": 10000.00,
    "edad": 19,
    "ciudad": "Las Vegas",
    "establecimiento": "Casino Luxury",
    "especialidad": "ENTRETENIMIENTO"
}
```
**Resultado esperado:** Probablemente SÍ es fraude

---

## 📊 ENTENDER LA RESPUESTA

Cuando hagas click en "Send", recibirás una respuesta JSON similar a:

```json
{
    "prediction": 0,
    "probability": 0.15,
    "is_fraud": false
}
```

**Campos:**
- `prediction`: `0` = No es fraude, `1` = Es fraude
- `probability`: Confianza de la predicción (0-1)
- `is_fraud`: `true` o `false` para facilitar la lectura

---

## ⚡ SOLUCIONAR PROBLEMAS

### ❌ Error 403 (Forbidden)
```
"User is not authorized to perform: apigateway:GET"
```
**Solución:** Verifica que el rol IAM tenga permisos

### ❌ Error 500 (Internal Server Error)
```
"The endpoint is not in the InService state"
```
**Solución:** El endpoint de SageMaker no está listo. Espera un momento y reintentar.

### ❌ Error 404 (Not Found)
```
"Invalid API Key or Resource"
```
**Solución:** Verifica que la URL sea exacta (cópiala de aquí)

### ❌ Timeout (Solicitud tardó demasiado)
**Solución:** En Postman → Settings → Timeout → aumenta a 60 segundos

---

## 🔄 PRÓXIMOS PASOS

Después de probar:

1. **Integra esta URL en tu aplicación:**
   ```
   https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude
   ```

2. **Usa en tu código (Python ejemplo):**
   ```python
   import requests
   
   response = requests.post(
       'https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude',
       json={
           "transaction_id": "TRX123",
           "monto": 150.50,
           "edad": 35,
           "ciudad": "Quito",
           "establecimiento": "Restaurant",
           "especialidad": "RESTAURANTES"
       }
   )
   
   print(response.json())
   ```

3. **O en JavaScript/TypeScript:**
   ```javascript
   const response = await fetch(
       'https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude',
       {
           method: 'POST',
           headers: { 'Content-Type': 'application/json' },
           body: JSON.stringify({
               transaction_id: 'TRX123',
               monto: 150.50,
               edad: 35,
               ciudad: 'Quito',
               establecimiento: 'Restaurant',
               especialidad: 'RESTAURANTES'
           })
       }
   );
   ```

---

## ✅ CHECKLIST FINAL

- ✅ API Gateway creada (`tooahxop09`)
- ✅ Integrada con SageMaker
- ✅ Endpoint `endpoint-fraudes-v5` activo
- ✅ Colección Postman lista
- ✅ URL funcionando
- ⏳ **PENDIENTE: Probar en Postman**

---

**¡Ahora abre Postman e importa la colección! 🚀**
