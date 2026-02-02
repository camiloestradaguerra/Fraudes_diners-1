# 📋 CONFIGURACIÓN MANUAL DE API GATEWAY (Si el script falla)

Si el terminal está bloqueado, sigue estos pasos MANUALMENTE en la AWS Console:

## PASO 1: Crear API Gateway Rest API
1. Ve a **AWS Console → API Gateway**
2. Click en **Create API**
3. Selecciona **REST API** → **Build**
4. Configura:
   - API Name: `fraudes-api`
   - Description: `API Gateway proxy para SageMaker endpoint`
   - Endpoint Type: `Regional`
5. Click **Create API**

## PASO 2: Crear Recurso /fraude
1. En la consola de API Gateway, selecciona tu API
2. Click en el recurso raíz **/**
3. Click **Actions** → **Create Resource**
4. Configura:
   - Resource Name: `fraude`
   - Resource Path: `/fraude`
5. Click **Create Resource**

## PASO 3: Crear Método POST
1. Con el recurso `/fraude` seleccionado
2. Click **Actions** → **Create Method** → **POST**
3. Tipo de integración: **AWS Service**
4. Configura:
   - AWS Region: `us-east-1`
   - AWS Service: `SageMaker Runtime`
   - HTTP Method: `POST`
   - Action Type: `Use path override`
   - Path: `endpoints/endpoint-fraudes-v5/invocations`
   - Execution Role: Pegaaquí el ARN del rol:
     ```
     arn:aws:iam::822626720556:role/apigateway-sagemaker-proxy
     ```
5. Click **Save**

## PASO 4: Configurar Mapping Template
1. En el método POST creado, ve a **Integration Request**
2. Expande **Mapping Templates**
3. Haz click en **Add mapping template**
4. Content-Type: `application/json`
5. En el template editor, escribe:
   ```
   $input.json('$')
   ```
6. Click **Save**

## PASO 5: Desplegar API
1. En API Gateway, click **Actions** → **Deploy API**
2. Stage: `prod` (o crear nuevo)
3. Click **Deploy**
4. AWS te mostrará la **Invoke URL**

## PASO 6: La URL será similar a:
```
https://ABC1234XYZ.execute-api.us-east-1.amazonaws.com/prod/fraude
```

## PASO 7: Probar en Postman
1. Abre **Postman**
2. Crea request **POST** a la URL anterior
3. Headers:
   - `Content-Type: application/json`
4. Body (raw JSON):
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
5. Click **Send**
6. ¡Deberías recibir la predicción de fraude!

---

## COMANDOS AWS CLI (Alternativa automatizada)

Si prefieres usar CLI, ejecuta en orden:

```bash
# 1. Crear API
aws apigateway create-rest-api \
  --name fraudes-api \
  --description "API Gateway proxy para SageMaker" \
  --region us-east-1

# Copiar el "id" del resultado

# 2. Obtener root resource ID
aws apigateway get-resources \
  --rest-api-id <API_ID> \
  --region us-east-1

# 3. Crear recurso /fraude
aws apigateway create-resource \
  --rest-api-id <API_ID> \
  --parent-id <ROOT_ID> \
  --path-part fraude \
  --region us-east-1

# Copiar el "id" del resultado

# 4. Crear método POST
aws apigateway put-method \
  --rest-api-id <API_ID> \
  --resource-id <RESOURCE_ID> \
  --http-method POST \
  --authorization-type NONE \
  --region us-east-1

# 5. Configurar integración con SageMaker
aws apigateway put-integration \
  --rest-api-id <API_ID> \
  --resource-id <RESOURCE_ID> \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:sagemaker:action/InvokeEndpoint" \
  --credentials "arn:aws:iam::822626720556:role/apigateway-sagemaker-proxy" \
  --region us-east-1

# 6. Desplegar
aws apigateway create-deployment \
  --rest-api-id <API_ID> \
  --stage-name prod \
  --region us-east-1

# Tu URL será:
# https://<API_ID>.execute-api.us-east-1.amazonaws.com/prod/fraude
```

---

**¿Necesitas ayuda con alguno de estos pasos?**
