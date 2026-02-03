# CloudFormation Deployment Guide - Fraudes Diners

**Actualizado:** Integra completamente SageMaker + API Gateway en un solo comando

---

## 📋 Cambios Realizados

El archivo `infra.yaml` ahora incluye:

✅ **SageMaker Endpoint** (como antes)
✅ **API Gateway con integración a SageMaker** (NUEVO - resuelve el problema de consola)
✅ **Roles IAM correctos** para ambos servicios
✅ **Soporte cross-account** para despliegue en otra cuenta AWS
✅ **Outputs automáticos** con URL de la API

---

## 🚀 Despliegue Rápido (Same-Account)

### Opción 1: Usar CloudFormation Script (Recomendado)

```bash
# Despliegue básico
python deploy_cloudformation.py

# O especificar región y nombre del stack
python deploy_cloudformation.py --region us-east-1 --stack-name mi-fraudes-stack
```

**¿Qué hace?**
1. Valida el template `infra.yaml`
2. Crea o actualiza el stack CloudFormation
3. Espera a que se complete (~10-15 minutos)
4. Extrae y guarda los outputs (API URL, Endpoint Name, etc.)
5. Genera archivos de configuración para referencia

### Opción 2: AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name fraudes-stack \
  --template-body file://infra.yaml \
  --parameters ParameterKey=EndpointName,ParameterValue=endpoint-fraudes-v5 \
              ParameterKey=ImageUri,ParameterValue=822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Monitorear el progreso
aws cloudformation wait stack-create-complete --stack-name fraudes-stack
aws cloudformation describe-stacks --stack-name fraudes-stack --query 'Stacks[0].Outputs'
```

### Opción 3: AWS Console

1. Ve a CloudFormation → Create Stack
2. Sube el archivo `infra.yaml`
3. Rellena los parámetros:
   - **EndpointName:** `endpoint-fraudes-v5`
   - **ImageUri:** `822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest`
   - **InstanceType:** `ml.t2.medium` (default está bien)
4. Habilita "CAPABILITY_NAMED_IAM"
5. Click en "Create Stack"

---

## 🌍 Despliegue Cross-Account (En Otra Cuenta AWS)

Si estás en una **cuenta diferente** a donde está el SageMaker endpoint:

```bash
# Desde la nueva cuenta
python deploy_cloudformation.py \
  --source-account 822626720556 \
  --region us-east-1 \
  --stack-name fraudes-stack

# O con AWS CLI
aws cloudformation create-stack \
  --stack-name fraudes-stack \
  --template-body file://infra.yaml \
  --parameters ParameterKey=SourceAccount,ParameterValue=822626720556 \
  --capabilities CAPABILITY_NAMED_IAM
```

**¿Qué pasa en cross-account?**

El template automáticamente:
1. Crea un rol `ElasticBeanstalkRole` en la nueva cuenta
2. Le permite asumir roles desde la cuenta original (822626720556)
3. Usa `ExternalId: fraudes-diners-eb` como medida de seguridad

---

## 📊 Estructura del Template

### Sección 1: Roles y Políticas

```yaml
SageMakerExecutionRole:
  - Permisos: AmazonSageMakerFullAccess + ECR + CloudWatch
  - Usado por: SageMaker Endpoint

APIGatewaySageMakerRole:
  - Permisos: sagemaker:InvokeEndpoint
  - Usado por: API Gateway para llamar al endpoint

CrossAccountAssumeRole: (solo en cross-account)
  - Permite a cuenta origen asumir permisos
  - Usa ExternalId para seguridad
```

### Sección 2: SageMaker

```yaml
FraudDetectionModel:
  - Referencia la imagen en ECR
  - Usa el rol de ejecución de SageMaker

FraudEndpointConfig:
  - Define hardware (ml.t2.medium)
  - 1 instancia inicial

FraudEndpoint:
  - Crea el endpoint real-time
  - Nombre: endpoint-fraudes-v5
```

### Sección 3: API Gateway

```yaml
FraudesRestApi:
  - Crea la API REST
  - Tipo: REGIONAL

ApiRootResource:
  - Crea el recurso /fraude

PostMethod:
  - Método: POST
  - Integración: AWS → SageMaker Runtime
  - Credentials: APIGatewaySageMakerRole

ApiDeployment:
  - Stage: prod
  - Habilita logging y métricas
```

---

## 📤 Outputs del Despliegue

Después de completarse, obtendrás:

```json
{
  "EndpointName": "endpoint-fraudes-v5",
  "EndpointArn": "arn:aws:sagemaker:us-east-1:822626720556:endpoint/endpoint-fraudes-v5",
  "ApiId": "abc123def456",
  "ApiInvokeUrl": "https://abc123def456.execute-api.us-east-1.amazonaws.com/prod/fraude",
  "SageMakerRoleArn": "arn:aws:iam::822626720556:role/SageMakerFraudesExecutionRole",
  "APIGatewayRoleArn": "arn:aws:iam::822626720556:role/APIGatewaySageMakerProxyRole",
  "CrossAccountRoleArn": "arn:aws:iam::NUEVA-CUENTA:role/ElasticBeanstalkRole" // solo si cross-account
}
```

Estos se guardan automáticamente en:
- `deployment-config.json` (todos los outputs)
- `api-invoke-url.txt` (URL de la API)
- `api-id.txt` (ID de la API)
- `endpoint-name.txt` (Nombre del endpoint)

---

## 🧪 Probar la API

Una vez desplegado:

### Con Postman

1. POST a: `https://<API_ID>.execute-api.us-east-1.amazonaws.com/prod/fraude`
2. Headers: `Content-Type: application/json`
3. Body:
```json
{
  "transaction_id": "TRX-NEW-001",
  "monto": 500.0,
  "edad": 30,
  "ciudad": "Guayaquil",
  "establecimiento": "Tienda-Diners",
  "especialidad": "RETAIL"
}
```

### Con AWS CLI

```bash
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --body '{"transaction_id":"TRX-NEW","monto":500,"edad":30,"ciudad":"Guayaquil","establecimiento":"Tienda-Diners","especialidad":"RETAIL"}' \
  --content-type application/json \
  response.json
```

### Con cURL

```bash
curl -X POST https://<API_ID>.execute-api.us-east-1.amazonaws.com/prod/fraude \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX-NEW-001",
    "monto": 500.0,
    "edad": 30,
    "ciudad": "Guayaquil",
    "establecimiento": "Tienda-Diners",
    "especialidad": "RETAIL"
  }'
```

---

## 🔧 Actualizar el Stack

Si necesitas hacer cambios (e.g., cambiar el instance type):

```bash
# Con CloudFormation Script
python deploy_cloudformation.py --instance-type ml.t2.large

# O con AWS CLI
aws cloudformation update-stack \
  --stack-name fraudes-stack \
  --template-body file://infra.yaml \
  --parameters ParameterKey=InstanceType,ParameterValue=ml.t2.large \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## 🗑️ Eliminar el Stack

```bash
# Con AWS CLI
aws cloudformation delete-stack --stack-name fraudes-stack

# O desde AWS Console
# CloudFormation → fraudes-stack → Delete
```

⚠️ Esto eliminará:
- SageMaker Endpoint (si no tiene persistencia configurada)
- API Gateway
- Roles IAM creados por el template

---

## 📍 Diferencias: Script Anterior vs CloudFormation

| Aspecto | Script Python | CloudFormation |
|---------|---------------|-----------------|
| **Automatización** | Manual, paso a paso | Totalmente automático |
| **Idempotencia** | No (debe ejecutarse solo una vez) | Sí (puede actualizarse) |
| **Reproducibilidad** | Difícil de repetir | Fácil (solo ejecutar template) |
| **Documentación** | En el código | En el YAML |
| **Cross-Account** | Necesita custom logic | Soportado nativamente |
| **Rollback** | Manual | Automático |
| **Escalabilidad** | No | Fácil (parámetros) |

---

## 🐛 Troubleshooting

### Error: "No updates are to be performed"

✅ Normal - significa que el stack ya está actualizado y no hay cambios.

### Error: "User is not authorized to perform: iam:CreateRole"

❌ Necesitas permisos IAM para crear roles. Agrega a tu política:
```json
{
  "Effect": "Allow",
  "Action": [
    "iam:CreateRole",
    "iam:PutRolePolicy",
    "iam:AttachRolePolicy",
    "iam:PassRole"
  ],
  "Resource": "*"
}
```

### Error: "The image with imageId ami-... does not exist"

❌ La imagen ECR no está en la región. Verifica:
```bash
aws ecr describe-images \
  --repository-name fraudes-diners \
  --region us-east-1
```

### Stack se queda en "CREATE_IN_PROGRESS"

⏳ Espera a que se complete (puede tardar 10-15 minutos). Revisa eventos:
```bash
aws cloudformation describe-stack-events \
  --stack-name fraudes-stack \
  --query 'StackEvents[0:5]' \
  --output table
```

---

## 📚 Archivos Relacionados

- **infra.yaml** - Template CloudFormation (actualizado)
- **deploy_cloudformation.py** - Script de despliegue automático (NUEVO)
- **create_api_with_assumed_role.py** - Script antiguo (mantener para referencia)
- **test_api_gateway.py** - Test del API Gateway
- **POSTMAN_GUIDE.md** - Guía de Postman

---

## ✅ Checklist Post-Despliegue

- [ ] Stack creado exitosamente (estado: CREATE_COMPLETE)
- [ ] API Gateway URL generada y guardada
- [ ] SageMaker Endpoint en estado "InService"
- [ ] Prueba POST exitosa a la API
- [ ] deployment-config.json creado con outputs
- [ ] Roles IAM creados con permisos correctos
- [ ] CloudWatch logs habilitados

---

**Última actualización:** 2026-02-02  
**Status:** ✅ Producción
