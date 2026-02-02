# 🎯 SOLUCIÓN PARA ERROR 403 FORBIDDEN

## PROBLEMA
Error 403 al llamar al API Gateway significa que la integración está rechazando la solicitud.

## SOLUCIONES (En orden de facilidad)

---

## ✅ SOLUCIÓN 1: VIA AWS CONSOLE (Recomendado - Manual)

### Paso 1: Ve a API Gateway Console
```
https://console.aws.amazon.com/apigateway
```

### Paso 2: Selecciona `fraudes-api`

### Paso 3: Entra al recurso `/fraude` → Método `POST`

### Paso 4: En "Integration Request", cambia la configuración:

**Antes (que no funciona):**
- Integration type: `AWS_PROXY`
- URI: `arn:aws:apigateway:us-east-1:sagemaker:action/InvokeEndpoint`

**Después (lo correcto):**
- Integration type: `AWS`
- Integration HTTP method: `POST`
- URI: `arn:aws:apigateway:us-east-1:runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations`
- Execution role: `arn:aws:iam::822626720556:role/apigateway-sagemaker-proxy`

### Paso 5: En Integration Response
- Status 200
- Response templates: `{"application/json": ""}`

### Paso 6: Redeploy
```
Actions → Deploy API → Stage: prod
```

### Paso 7: Vuelve a intentar en Postman

---

## SOLUCIÓN 2: VIA AWS CLI (Automática)

```bash
# Establece estas variables
API_ID="tooahxop09"
RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?pathPart==`fraude`].id' --output text --region us-east-1)
ROLE_ARN="arn:aws:iam::822626720556:role/apigateway-sagemaker-proxy"

# Elimina integración anterior
aws apigateway delete-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --region us-east-1 2>/dev/null || true

# Crea nueva integración
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type AWS \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations" \
  --credentials $ROLE_ARN \
  --region us-east-1

# Redeploy
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region us-east-1
```

---

## SOLUCIÓN 3: USAR LAMBDA COMO INTERMEDIARIO (Más Robusto)

Si las soluciones anteriores no funcionan, crea una Lambda que actúe como proxy:

```python
import boto3
import json

sagemaker = boto3.client('sagemaker-runtime', region_name='us-east-1')

def lambda_handler(event, context):
    try:
        payload = json.loads(event['body'])
        
        response = sagemaker.invoke_endpoint(
            EndpointName='endpoint-fraudes-v5',
            ContentType='application/json',
            Body=json.dumps(payload)
        )
        
        result = json.loads(response['Body'].read().decode())
        
        return {
            'statusCode': 200,
            'body': json.dumps(result),
            'headers': {'Content-Type': 'application/json'}
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)}),
            'headers': {'Content-Type': 'application/json'}
        }
```

Luego conecta la Lambda a API Gateway.

---

## 📊 COMPARACIÓN DE SOLUCIONES

| Solución | Dificultad | Tiempo | Funciona |
|----------|-----------|--------|----------|
| Arreglo en Console | ⭐ Fácil | 5 min | ✅ Sí |
| Comandos AWS CLI | ⭐⭐ Media | 10 min | ✅ Sí |
| Lambda Proxy | ⭐⭐⭐ Difícil | 20 min | ✅⭐ Sí (más confiable) |

---

## ⚡ SIGUIENTE PASO

**Recomendación: Intenta la Solución 1 (AWS Console)**

Es la más rápida de verificar y ver si funciona.

1. Ve a https://console.aws.amazon.com/apigateway
2. Edita la integración según las instrucciones arriba
3. Redeploy
4. Vuelve a Postman y prueba

---

## 🆘 SI SIGUE SIN FUNCIONAR

Verifica:
1. El endpoint de SageMaker está en estado `InService`:
   ```
   aws sagemaker describe-endpoint --endpoint-name endpoint-fraudes-v5
   ```

2. El rol tiene los permisos correctos:
   ```
   aws iam list-role-policies --role-name apigateway-sagemaker-proxy
   ```

3. Han pasado algunos minutos desde el último cambio (AWS necesita tiempo para replicar)

---

**¿Listo para intentar la Solución 1 en la AWS Console?**
