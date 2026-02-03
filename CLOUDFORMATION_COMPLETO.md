# CloudFormation Stack Completo - Fraudes Diners

## 📋 Resumen

CloudFormation template **100% reproducible** que crea desde cero:
- ✅ Rol IAM para API Gateway
- ✅ Política IAM con permisos SageMaker
- ✅ API Gateway REST API
- ✅ Recursos y métodos POST
- ✅ Integración con SageMaker Endpoint
- ✅ Deployment en stage `prod`

## 🚀 Despliegue Rápido

```bash
# Desplegar con nombre de stack personalizado
python deploy_cloudformation.py --stack-name mi-stack-fraudes

# Especificar endpoint SageMaker (opcional, default: endpoint-fraudes-v5)
python deploy_cloudformation.py --stack-name mi-stack --endpoint-name mi-endpoint

# Especificar región (opcional, default: us-east-1)
python deploy_cloudformation.py --stack-name mi-stack --region us-west-2
```

## 📦 Recursos Creados

### 1. IAM Role: `apigateway-sagemaker-<STACK_NAME>`
```yaml
Tipo: AWS::IAM::Role
Propósito: Permite que API Gateway invoque SageMaker endpoints
Trust Policy: Acepta principal apigateway.amazonaws.com
```

### 2. IAM Policy: `SageMakerInvoke`
```yaml
Tipo: AWS::IAM::Policy
Permisos: sagemaker:InvokeEndpoint
Resource: arn:aws:sagemaker:REGION:ACCOUNT:endpoint/ENDPOINT_NAME
Adjunta a: APIGatewaySageMakerRole
```

### 3. API Gateway REST API: `fraudes-api-prod`
```yaml
Tipo: AWS::ApiGateway::RestApi
Endpoint: REGIONAL
Descripción: API para detección de fraudes con SageMaker
```

### 4. API Gateway Resource: `/fraude`
```yaml
Tipo: AWS::ApiGateway::Resource
Ruta: /fraude
Integración: Método POST
```

### 5. API Gateway Method: `POST /fraude`
```yaml
Tipo: AWS::ApiGateway::Method
HTTP Method: POST
Autenticación: NONE
Integración: AWS (SageMaker Runtime)
Credenciales: Rol IAM creado
Response Code: 200
```

### 6. API Gateway Deployment: `prod`
```yaml
Tipo: AWS::ApiGateway::Deployment
Stage: prod
```

## 📤 Outputs del Stack

```
ApiId:        ID único de la API Gateway
ApiInvokeUrl: URL pública para llamar la API
RoleArn:      ARN del rol IAM creado
RoleName:     Nombre del rol IAM
EndpointName: Nombre del endpoint SageMaker
```

## 🔒 Seguridad

✅ **Trust Policy**
```json
{
  "Principal": {"Service": "apigateway.amazonaws.com"},
  "Action": "sts:AssumeRole"
}
```

✅ **Permissions Policy**
```json
{
  "Action": "sagemaker:InvokeEndpoint",
  "Resource": "arn:aws:sagemaker:REGION:ACCOUNT:endpoint/ENDPOINT_NAME",
  "Effect": "Allow"
}
```

## 🧪 Testear la API

Después del despliegue, se crea `api-invoke-url.txt`:

```bash
# Con Python
python test_api_gateway.py

# Con curl
curl -X POST $(cat api-invoke-url.txt) \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX-TEST-001",
    "monto": 150.5,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
  }'
```

## 📊 Respuesta Esperada

```json
{
  "schema_version": "1.0",
  "request_id": "REQ-12345",
  "ml_score_0_999": 301.0,
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": 0.039
}
```

## ⚙️ Parámetros Configurables

### EndpointName (string)
- **Default**: `endpoint-fraudes-v5`
- **Descripción**: Nombre del endpoint SageMaker existente que será invocado
- **Pattern**: `^[a-zA-Z0-9\-]{1,63}$`

## 🗂️ Archivos del Stack

```
infra.yaml                  ← Template CloudFormation COMPLETO
deploy_cloudformation.py    ← Script de despliegue
test_api_gateway.py        ← Script de prueba
api-invoke-url.txt         ← URL de la API (se crea después del deploy)
deployment-config.json     ← Configuración guardada
```

## 🔄 Ciclo de Vida

### Crear Stack
```bash
python deploy_cloudformation.py --stack-name fraudes-api-v1
```

### Actualizar Stack
```bash
# Automático - detecta si el stack existe
python deploy_cloudformation.py --stack-name fraudes-api-v1
```

### Eliminar Stack
```bash
aws cloudformation delete-stack --stack-name fraudes-api-v1 --region us-east-1
```

## ✅ Validación Checklist

- [x] Rol IAM creado con nombre correcto
- [x] Trust policy permite apigateway.amazonaws.com
- [x] Política adjunta permite sagemaker:InvokeEndpoint
- [x] API Gateway integración usa credenciales del rol
- [x] API Gateway deployment en stage prod
- [x] URL pública accesible
- [x] SageMaker endpoint recibe requests
- [x] Respuestas válidas (Status 200)

## 🚨 Troubleshooting

### Error: "Resource already exists"
- El rol podría existir de deployments previos
- Solución: Usar diferente nombre de stack o eliminar el rol anterior

### Error: "No such role"
- El rol no fue creado correctamente
- Solución: Verificar permisos IAM de la cuenta

### Error: "Could not invoke endpoint"
- El endpoint SageMaker no existe o no está en servicio
- Solución: Verificar que `EndpointName` es correcto

### API retorna 403
- Faltan permisos en la política IAM
- Solución: Verificar que el rol tiene `sagemaker:InvokeEndpoint` en el resource correcto

## 📚 Documentación Relacionada

- [AWS CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)
- [API Gateway Integration with SageMaker](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html)
- [SageMaker Endpoint Invocation](https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works-hosting.html)

---

**Template Versión**: 1.0  
**Última Actualización**: 2026-02-02  
**Estado**: ✅ Production Ready
