# 🔴 PROBLEMA: Error 403 Forbidden en API Gateway

## ANÁLISIS DEL PROBLEMA

El error 403 (Forbidden) indica que:

1. **La API Gateway existe** ✅ (ID: `tooahxop09`)
2. **El endpoint responde** ✅ (pero rechaza la solicitud)
3. **PERO rechaza el acceso** ❌ 

### Causas Posibles:

| Causa | Síntomas |
|-------|----------|
| **Rol IAM sin permisos** | 403 Forbidden (más común) |
| **CORS no configurado** | Error en navegador (menos probable desde Postman) |
| **Integración AWS_PROXY incorrecta** | 403 o 502 |
| **Credenciales insuficientes del usuario** | AccessDenied |

---

## ✅ SOLUCIÓN: Cambiar a Integración Más Simple

El problema es que usamos `AWS_PROXY` que requiere transformación de requests. 

**Vamos a usar una integración HTTP más simple** que apunta directamente al endpoint de SageMaker.

### Pasos para Arreglarlo:

**OPCIÓN 1: Via AWS Console (Manual)**
1. Ve a: https://console.aws.amazon.com/apigateway
2. Selecciona: `fraudes-api`
3. Selecciona el recurso: `/fraude`
4. Click en el método: `POST`
5. Ve a: **Integration Request**
6. Cambia:
   - Integration type: `HTTP` (en lugar de AWS_PROXY)
   - HTTP method: `POST`
   - Endpoint URL: `https://runtime.sagemaker.us-east-1.amazonaws.com/endpoints/endpoint-fraudes-v5/invoke`

7. Ve a: **HTTP Request Headers**
   - Add header: `Authorization: aws4` (para AWS Signature)

8. Guarda y redeploya

**OPCIÓN 2: Via AWS CLI (Automático)**
Ejecuta este script:

```bash
# Asumir rol
ASSUME=$(aws sts assume-role --role-arn "arn:aws:iam::822626720556:role/ElasticBeanstalkRole" --role-session-name "fix-api" --external-id "fraudes-diners-eb" --output json)

export AWS_ACCESS_KEY_ID=$(echo $ASSUME | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $ASSUME | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $ASSUME | jq -r '.Credentials.SessionToken')

API_ID="tooahxop09"
RESOURCE_ID="<obtener-de-api>"

# Eliminar integración anterior
aws apigateway delete-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --region us-east-1

# Crear nueva integración HTTP
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method POST \
  --type HTTP \
  --integration-http-method POST \
  --uri "https://runtime.sagemaker.us-east-1.amazonaws.com/endpoints/endpoint-fraudes-v5/invoke" \
  --region us-east-1
```

---

## 🔧 ALTERNATIVA: Usar Lambda como intermediario

Si API Gateway sigue sin funcionar, podemos usar **AWS Lambda** como intermediario:

```
Postman → API Gateway → Lambda → SageMaker Endpoint
```

Lambda está mejor soportado para transformar requests a SageMaker.

---

## 📊 ESTADO ACTUAL

| Componente | Estado | Problema |
|---|---|---|
| API Gateway | ✅ Creada | 403 Forbidden |
| SageMaker Endpoint | ✅ Activo | Acceso denegado |
| Rol IAM | ✅ Existe | Podría faltar `sts:AssumeRole` para API Gateway |
| Integración | ❌ Falla | Tipo `AWS_PROXY` no funciona |

---

## 🎯 SIGUIENTE ACCIÓN

¿Prefieres:

**A) Arreglarlo via AWS Console** (manual, 5 minutos)
**B) Usar Lambda como intermediario** (más robusto)
**C) Verificar permisos del usuario** (diagnóstico completo)

---

**Nota:** El error 403 generalmente significa que:
- El rol `apigateway-sagemaker-proxy` no tiene permisos completos
- O la integración está mal configurada

Recomendación: Vamos a intentar la **Opción A (AWS Console)** porque es más rápida de diagnosticar.
