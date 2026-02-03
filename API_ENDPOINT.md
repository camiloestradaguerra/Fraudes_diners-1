# API Endpoint - Fraud Detection

## URL del Endpoint

```
https://v35gizdlll.execute-api.us-east-1.amazonaws.com/prod/fraude
```

## Método
**POST**

## Headers Requeridos
```
Content-Type: application/json
```

## Body (JSON)
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

## Respuesta Esperada
```json
{
  "schema_version": "1.0",
  "request_id": "REQ-4E6E7",
  "ml_score_0_999": 301.0,
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": 0.02859699998225551
}
```

## Usar en Postman

1. Abre Postman
2. Crea una nueva solicitud
3. Selecciona **POST** como método
4. Pega este URL:
   ```
   https://v35gizdlll.execute-api.us-east-1.amazonaws.com/prod/fraude
   ```
5. Ve a la pestaña **Headers** y asegúrate de que esté:
   ```
   Content-Type: application/json
   ```
6. Ve a la pestaña **Body**, selecciona **raw** y **JSON**
7. Copia el JSON de ejemplo arriba
8. Haz clic en **Send**

Deberías recibir una respuesta JSON con el resultado de la predicción.

## Campos Requeridos

| Campo | Tipo | Descripción | Ejemplo |
|-------|------|-------------|---------|
| `transaction_id` | string | ID único de la transacción | "TRX123456" |
| `monto` | float | Monto de la transacción | 150.50 |
| `edad` | integer | Edad del cliente | 35 |
| `ciudad` | string | Ciudad de la transacción | "Quito" |
| `establecimiento` | string | Nombre del establecimiento | "RestaurantXYZ" |
| `especialidad` | string | Especialidad/Categoría del negocio | "RESTAURANTES" |

## cURL Ejemplo

```bash
curl -X POST https://v35gizdlll.execute-api.us-east-1.amazonaws.com/prod/fraude \
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

## PowerShell Ejemplo

```powershell
$apiUrl = "https://v35gizdlll.execute-api.us-east-1.amazonaws.com/prod/fraude"
$body = @{
    transaction_id = "TRX123456"
    monto = 150.50
    edad = 35
    ciudad = "Quito"
    establecimiento = "RestaurantXYZ"
    especialidad = "RESTAURANTES"
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri $apiUrl `
  -Method POST `
  -ContentType "application/json" `
  -Body $body

$response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
```
