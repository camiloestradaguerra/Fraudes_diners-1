# Documentación Técnica - Fraud Detection API
## Infraestructura de Detección de Fraudes con Terraform en AWS

**Versión:** 1.0  
**Fecha:** 3 de Febrero de 2026  
**Región:** us-east-1  
**Cuenta AWS:** 761951921633

---

## Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura General](#arquitectura-general)
3. [Componentes de AWS](#componentes-de-aws)
4. [Configuración de Terraform](#configuración-de-terraform)
5. [Flujo de Solicitudes](#flujo-de-solicitudes)
6. [Especificaciones Técnicas](#especificaciones-técnicas)
7. [Guía de Despliegue](#guía-de-despliegue)
8. [Monitoreo y Observabilidad](#monitoreo-y-observabilidad)
9. [Solución de Problemas](#solución-de-problemas)

---

## Resumen Ejecutivo

Este documento describe la infraestructura en la nube para una **API de Detección de Fraudes** construida con AWS SageMaker y API Gateway. La solución utiliza **Terraform** como herramienta Infrastructure-as-Code (IaC) para provisionar, gestionar y mantener todos los recursos en AWS.

### Objetivos

- Desplegar un endpoint de aprendizaje automático (SageMaker) que detecta fraudes en transacciones
- Exponer el modelo a través de una API REST pública
- Automatizar el despliegue completo con Terraform
- Asegurar escalabilidad, disponibilidad y seguridad

### Resultados Logrados

✅ **API Endpoint**: `https://v35gizdlll.execute-api.us-east-1.amazonaws.com/prod/fraude`  
✅ **Latencia Promedio**: ~30-40ms por predicción  
✅ **Disponibilidad**: 99.9% (SLA de AWS)  
✅ **Escalado Automático**: SageMaker managed  

---

## Arquitectura General

```
┌─────────────────────────────────────────────────────────────────┐
│                         Cliente/Usuario                          │
│                      (Postman, Aplicación)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                        HTTP/JSON
                             │
                             ▼
         ┌───────────────────────────────────────┐
         │       API Gateway (REST API)           │
         │  fraud-detection-api-prod              │
         │  - Resource: /fraude                   │
         │  - Method: POST                        │
         │  - Authorization: NONE                 │
         └────────────────┬──────────────────────┘
                          │
                    AWS Integration
                  (Type: AWS, Direct)
                          │
                          ▼
         ┌───────────────────────────────────────┐
         │  SageMaker Runtime Service             │
         │  endpoint-fraudes-v5                  │
         │  - Instance: ml.m5.large              │
         │  - Variant: Primary                   │
         │  - Status: InService                  │
         └────────────────┬──────────────────────┘
                          │
                          ▼
         ┌───────────────────────────────────────┐
         │    SageMaker Model                     │
         │    fraud-detection-model-prod         │
         │    - Framework: Python/scikit-learn   │
         │    - Versión: 2024.11                 │
         │    - Provider: ExternalVendor         │
         └───────────────────────────────────────┘
```

### Flujo de Datos

1. **Entrada**: JSON con datos de transacción
2. **Validación**: API Gateway valida el formato
3. **Integración**: SageMaker Runtime invoca el modelo
4. **Procesamiento**: Modelo calcula score de fraude
5. **Salida**: JSON con predicción y metadatos

---

## Componentes de AWS

### 1. API Gateway (REST API)

**Recurso**: `aws_api_gateway_rest_api`  
**Nombre**: `fraud-detection-api-prod`  
**ID**: `v35gizdlll`

#### Características

- Type: REST API (not WebSocket, not HTTP)
- Endpoint Type: Regional
- Binary Media Types: `application/json`, `application/vnd.amazon.eventstream`
- Logging: CloudWatch Logs disponibles

#### Recursos

- **Resource**: `/fraude`
  - Path: `/fraude`
  - Parent: Root resource
  - Methods: POST

#### Método POST

```
HTTP POST /fraude
Content-Type: application/json
```

**Request Body Schema**:
```json
{
  "transaction_id": "string (requerido)",
  "monto": "number (requerido)",
  "edad": "integer (requerido)",
  "ciudad": "string (requerido)",
  "establecimiento": "string (requerido)",
  "especialidad": "string (requerido)"
}
```

**Response Schema** (HTTP 200):
```json
{
  "schema_version": "1.0",
  "request_id": "string",
  "ml_score_0_999": "number (0-1000)",
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": "number"
}
```

### 2. SageMaker Endpoint

**Recurso**: `aws_sagemaker_endpoint`  
**Nombre**: `endpoint-fraudes-v5`  
**Estado**: InService

#### Configuración

```
Instancia Type: ml.m5.large
Initial Instance Count: 1
Variant Name: Primary
Initial Variant Weight: 1.0
Production Variants: 1
```

#### Modelo Asociado

**Nombre**: `fraud-detection-model-prod`  
**Container Image**: `761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest`  
**Version**: 2024.11

#### Health Monitoring

```
Health Check Interval: 5 segundos
Health Check Path: /ping
Expected Status: 200
Auto-recovery: Habilitado
```

### 3. IAM Roles y Políticas

#### Role: API Gateway → SageMaker

**Nombre**: `apigateway-sagemaker-fraud-detection-prod`

**Policy**: `apigateway-sagemaker-fraud-detection-prod-invoke`
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sagemaker:InvokeEndpoint",
      "Resource": "arn:aws:sagemaker:us-east-1:761951921633:endpoint/endpoint-fraudes-v5"
    }
  ]
}
```

#### Role: SageMaker Execution

**Nombre**: `sagemaker-execution-fraud-detection-prod`

**Políticas Adjuntas**:
- `AmazonSageMakerFullAccess` (managed policy)
- Política custom para acceso a ECR

**Trust Relationship**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "sagemaker.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### 4. ECR (Elastic Container Registry)

**Nombre**: `fraud-detection-api`  
**URI**: `761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api`  
**Imagen**: `fraud-detection-api:latest`

#### Configuración

```
Encryption: AWS managed keys
Scan on Push: Habilitado
Image Tag Mutability: MUTABLE
Lifecycle Policy: Retener últimas 5 imágenes
```

---

## Configuración de Terraform

### Estructura de Archivos

```
terraform/
├── main.tf                 # Configuración principal
├── variables.tf            # Variables de entrada
├── locals.tf              # Variables locales
├── outputs.tf             # Salidas
├── api_gateway.tf         # Recursos de API Gateway
├── iam.tf                 # Roles y políticas IAM
├── sagemaker.tf           # Recursos de SageMaker
├── ecr.tf                 # Repositorio ECR
├── docker.tf              # Build de Docker
└── terraform.tfvars       # Valores de variables
```

### Variables Principales

```hcl
# terraform/variables.tf

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_account_id" {
  type = string
}

variable "environment" {
  default = "prod"
}

variable "project_name" {
  default = "fraud-detection"
}

variable "api_gateway_stage" {
  default = "prod"
}

variable "sagemaker_instance_type" {
  default = "ml.m5.large"
}

variable "sagemaker_initial_instance_count" {
  default = 1
}
```

### Locales (Variables Calculadas)

```hcl
# terraform/locals.tf

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    CreatedBy   = "Terraform"
    ManagedBy   = "Infrastructure-as-Code"
  }
  
  api_gateway_name          = "${var.project_name}-api-${var.environment}"
  sagemaker_endpoint_name   = "endpoint-fraudes-v5"
  sagemaker_model_name      = "${var.project_name}-model-${var.environment}"
  ecr_repository_name       = var.project_name
  iam_role_apigateway_name  = "apigateway-sagemaker-${var.project_name}-${var.environment}"
}
```

### Outputs

```hcl
# terraform/outputs.tf

output "api_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.fraud_detection.id}.execute-api.${var.aws_region}.amazonaws.com/${var.api_gateway_stage}/fraude"
}

output "sagemaker_endpoint_name" {
  value = aws_sagemaker_endpoint.fraud_detection.endpoint_name
}

output "docker_image_uri" {
  value = "${aws_ecr_repository.fraud_detection.repository_url}:latest"
}

output "deployment_info" {
  value = {
    account_id              = data.aws_caller_identity.current.account_id
    region                  = var.aws_region
    api_invoke_url          = "https://${aws_api_gateway_rest_api.fraud_detection.id}.execute-api.${var.aws_region}.amazonaws.com/${var.api_gateway_stage}${aws_api_gateway_resource.fraude.path_part}"
    sagemaker_endpoint_name = aws_sagemaker_endpoint.fraud_detection.endpoint_name
    ...
  }
}
```

### Integración API Gateway → SageMaker

```hcl
# terraform/api_gateway.tf - CONFIGURACIÓN CRÍTICA

resource "aws_api_gateway_integration" "fraude_sagemaker" {
  rest_api_id             = aws_api_gateway_rest_api.fraud_detection.id
  resource_id             = aws_api_gateway_resource.fraude.id
  http_method             = aws_api_gateway_method.fraude_post.http_method
  
  # Configuración de integración AWS directa
  type                    = "AWS"                                    # Tipo: AWS (no AWS_PROXY)
  integration_http_method = "POST"                                  # Método HTTP de integración
  
  # URI que apunta al SageMaker Runtime
  uri = "arn:aws:apigateway:${var.aws_region}:runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations"
  
  # Credenciales IAM para autenticación
  credentials = aws_iam_role.apigateway_sagemaker.arn
}

# Response mapping
resource "aws_api_gateway_integration_response" "fraude_integration_response" {
  rest_api_id       = aws_api_gateway_rest_api.fraud_detection.id
  resource_id       = aws_api_gateway_resource.fraude.id
  http_method       = aws_api_gateway_method.fraude_post.http_method
  status_code       = "200"
  
  # Sin transformación de template - deja pasar el JSON directamente
  depends_on = [aws_api_gateway_integration.fraude_sagemaker]
}
```

#### Punto Crítico de Configuración

**El problema original**: Cuando se usaban `request_templates` complejos, API Gateway transformaba el request de forma incorrecta. **La solución**: Remover todos los templates y dejar que API Gateway pase el request directamente.

**URI Correcta vs Incorrecta**:
```
❌ INCORRECTO: ${aws_sagemaker_endpoint.fraud_detection.name}
✅ CORRECTO:  endpoint-fraudes-v5  (nombre hardcoded)
```

**Razón**: La variable de Terraform devolvía un nombre diferente al que SageMaker realmente estaba usando.

---

## Flujo de Solicitudes

### 1. Cliente Envía POST Request

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

### 2. API Gateway Procesa Request

```
Componentes:
1. Method: POST /fraude
2. Authorization: NONE (sin autenticación)
3. Body Validation: Application JSON
4. Routing: Basado en ruta /fraude
```

### 3. API Gateway Invoca SageMaker

```
URL: https://runtime.sagemaker.us-east-1.amazonaws.com/endpoints/endpoint-fraudes-v5/invocations
Headers:
  - Authorization: AWS4-HMAC-SHA256 (firmado con IAM role)
  - Content-Type: application/json
  - X-Amzn-Date: 20260203T173303Z
  - X-Amz-Security-Token: [token]
Body: [JSON enviado por cliente]
```

### 4. SageMaker Procesa en el Endpoint

```
Instancia: ml.m5.large
Modelo: fraud-detection-model-prod (versión 2024.11)
Procesamiento: ~0.04ms
Salida: JSON con predicción
```

### 5. SageMaker Retorna Respuesta

```json
{
  "schema_version": "1.0",
  "request_id": "REQ-71CCD",
  "ml_score_0_999": 301.0,
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": 0.036141999771643896
}
```

### 6. API Gateway Retorna al Cliente

```
HTTP Status: 200 OK
Content-Type: application/json
Body: [Respuesta de SageMaker sin transformación]
Tiempo Total: ~30-40ms
```

---

## Especificaciones Técnicas

### Límites y Quotas

| Componente | Límite | Descripción |
|-----------|--------|-------------|
| **API Gateway** | 10,000 req/seg | Por defecto en us-east-1 |
| **SageMaker Endpoint** | No limit | Gestión automática de carga |
| **Request Timeout** | 29 segundos | Máximo de API Gateway |
| **Payload Size** | 10 MB | Máximo de API Gateway |
| **Concurrencia** | Auto-scaling | Basado en instancias |

### Métricas de Performance

```
Latencia por Componente:
- API Gateway Routing: ~1-2ms
- Autenticación IAM: ~2-3ms
- Invocación SageMaker: ~30-40ms
- Respuesta SageMaker: ~0.04ms
- Serialización JSON: ~1-2ms
─────────────────────────
TOTAL: ~34-47ms
```

### Seguridad

#### Autenticación
- **Tipo**: AWS IAM (Signature Version 4)
- **Autorización**: Role-based Access Control (RBAC)
- **Certificados**: AWS managed (TLS 1.2+)

#### Autorización
- **API Gateway**: Sin autenticación (NONE)
- **SageMaker**: IAM Role autenticado
- **ECR**: IAM access control

#### Cifrado

| Componente | Cifrado | Método |
|-----------|--------|--------|
| **Datos en Tránsito** | ✅ | TLS 1.2+ (HTTPS) |
| **Datos en Reposo** | ✅ | AWS managed keys |
| **ECR Images** | ✅ | AWS managed encryption |

### Escalabilidad

**SageMaker Endpoint**:
- Escalado manual: Cambiar `initial_instance_count` en Terraform
- Escalado automático: Configurable con Target Tracking
- Máximo recomendado: 5-10 instancias para carga balanceada

**API Gateway**:
- Escalado automático: Manejado por AWS
- Máximo de endpoints: 500 por región (límite blando)
- Máximo de recursos: Ilimitado

### Disponibilidad

```
SLA Componentes:
- API Gateway: 99.95% mensual
- SageMaker: 99.9% mensual
- ECR: 99.99% mensual
─────────────────────
TOTAL ESTIMADO: >99.5% mensual
```

---

## Guía de Despliegue

### Requisitos Previos

```
✓ AWS CLI v2.13.0+
✓ Terraform v1.5.0+
✓ Python 3.11+
✓ Docker (para construir imagen)
✓ Credenciales AWS configuradas (aws configure)
```

### Pasos de Despliegue

#### 1. Preparar Variables

```bash
cd terraform

# Crear terraform.tfvars
cat > terraform.tfvars << EOF
aws_account_id = "761951921633"
aws_region     = "us-east-1"
environment    = "prod"
project_name   = "fraud-detection"
EOF
```

#### 2. Inicializar Terraform

```bash
terraform init

# Output esperado:
# Terraform has been successfully configured!
# Terraform v1.x.x has been initialized in this working directory
```

#### 3. Validar Configuración

```bash
terraform validate

# Output esperado:
# Success! The configuration is valid.
```

#### 4. Revisar Plan

```bash
terraform plan -out=tfplan

# Mostrará:
# Plan: XX to add, 0 to change, 0 to destroy
```

#### 5. Aplicar Cambios

```bash
terraform apply tfplan

# Output mostrará:
# Apply complete! Resources: XX added, 0 changed, 0 destroyed
```

#### 6. Obtener Outputs

```bash
terraform output

# Mostrará información importante:
# api_invoke_url = "https://v35gizdlll.execute-api.us-east-1.amazonaws.com/prod/fraude"
# sagemaker_endpoint_name = "endpoint-fraudes-v5"
# docker_image_uri = "761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest"
```

### Verificación Post-Despliegue

#### Test 1: Verificar API Gateway

```bash
aws apigateway get-rest-apis \
  --region us-east-1 \
  --query "items[?name=='fraud-detection-api-prod']"
```

#### Test 2: Verificar SageMaker

```bash
aws sagemaker describe-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --region us-east-1 \
  --query "EndpointStatus"

# Output: InService
```

#### Test 3: Invocación Directa (Referencia)

```bash
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --body fileb://payload.json \
  --content-type application/json \
  --region us-east-1 response.json

cat response.json
```

#### Test 4: Invocación a través de API

```bash
curl -X POST https://v35gizdlll.execute-api.us-east-1.amazonaws.com/prod/fraude \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TEST001",
    "monto": 100.00,
    "edad": 30,
    "ciudad": "Quito",
    "establecimiento": "TestStore",
    "especialidad": "TIENDAS"
  }' | jq
```

---

## Monitoreo y Observabilidad

### CloudWatch Logs

#### API Gateway Logs

```
Log Group: /aws/apigateway/fraud-detection-api-prod
Log Stream: [deployment-id]/[stage-name]

Información disponible:
- Request ID
- Method
- Resource Path
- Status Code
- Latency
- Error messages
```

#### SageMaker Endpoint Logs

```
Log Group: /aws/sagemaker/Endpoints/endpoint-fraudes-v5
Log Stream: Primary/[instance-id]

Información disponible:
- Health checks (GET /ping)
- Invocaciones exitosas
- Latencia de procesamiento
- Errores de ejecución
```

#### Visualizar Logs

```bash
# API Gateway
aws logs tail /aws/apigateway/fraud-detection-api-prod --follow

# SageMaker
aws logs tail /aws/sagemaker/Endpoints/endpoint-fraudes-v5 --follow
```

### CloudWatch Metrics

#### Métricas de API Gateway

```
Namespace: AWS/ApiGateway

Métricas principales:
- Count: Número de requests
- 4XXError: Errores cliente (400-499)
- 5XXError: Errores servidor (500-599)
- Latency: Tiempo de respuesta
- IntegrationLatency: Tiempo en backend
```

#### Métricas de SageMaker

```
Namespace: AWS/SageMaker

Métricas principales:
- ModelLatency: Latencia del modelo
- ModelInvocations: Número de invocaciones
- CPUUtilization: % uso de CPU
- MemoryUtilization: % uso de memoria
```

#### Crear Dashboard

```bash
# CLI para crear un dashboard básico
aws cloudwatch put-dashboard \
  --dashboard-name FraudDetectionAPI \
  --dashboard-body file://dashboard.json
```

### Alertas Recomendadas

```
Crear SNS Topic:
aws sns create-topic --name fraud-detection-alerts

Alertas a configurar:
1. 5XXError > 5 en 5 minutos → Crítico
2. Latency > 500ms → Advertencia
3. EndpointStatus != InService → Crítico
4. ModelInvocations = 0 en 10 minutos → Advertencia
```

---

## Solución de Problemas

### Error: `<UnknownOperationException/>`

**Síntoma**: API retorna HTTP 200 pero con contenido XML error

**Causas Comunes**:
1. URI de integración incorrecta
2. Request templates malformados
3. Nombre de endpoint incorrecto

**Solución**:
```hcl
# Verificar que URI sea exactamente:
uri = "arn:aws:apigateway:${var.aws_region}:runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations"

# NO usar variables dinámicas para nombre de endpoint
# ❌ INCORRECTO: path/endpoints/${aws_sagemaker_endpoint.fraud_detection.name}/invocations
# ✅ CORRECTO:  path/endpoints/endpoint-fraudes-v5/invocations
```

### Error: IAM Authorization Failed

**Síntoma**: CloudWatch logs muestran error de autenticación

**Causa**: El role de API Gateway no tiene permisos para invocar SageMaker

**Solución**:
```bash
# Verificar permisos
aws iam get-role-policy \
  --role-name apigateway-sagemaker-fraud-detection-prod \
  --policy-name apigateway-sagemaker-fraud-detection-prod-invoke

# Debe incluir: "sagemaker:InvokeEndpoint"
```

### Error: Endpoint InService pero No Responde

**Síntoma**: SageMaker endpoint está InService pero no procesa requests

**Causa**: Instancia tardó en inicializar o modelo no está listo

**Solución**:
```bash
# Esperar 2-5 minutos después del despliegue
# Luego verificar:
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --body '{}' \
  --content-type application/json \
  output.json

# Si error, revisar logs:
aws logs tail /aws/sagemaker/Endpoints/endpoint-fraudes-v5
```

### Error: Request Timeout

**Síntoma**: HTTP 504 Gateway Timeout

**Causa**: Modelo tardó >29 segundos en responder

**Solución**:
1. Verificar que instancia tiene suficientes recursos
2. Escalizar endpoint a instancia más grande
3. Optimizar modelo

```hcl
# Cambiar tamaño de instancia
variable "sagemaker_instance_type" {
  default = "ml.m5.xlarge"  # Cambiar de ml.m5.large
}
```

### Error: ECR Image Not Found

**Síntoma**: Terraform falla al crear endpoint, dice image no existe

**Causa**: Imagen Docker no fue pusheada a ECR

**Solución**:
```bash
# Verificar que imagen existe
aws ecr describe-images \
  --repository-name fraud-detection-api \
  --region us-east-1

# Si no existe, construir y pushear:
docker build -t fraud-detection-api:latest .
aws ecr get-login-password | docker login --username AWS --password-stdin 761951921633.dkr.ecr.us-east-1.amazonaws.com
docker tag fraud-detection-api:latest 761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest
docker push 761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest
```

### Terraform State Out of Sync

**Síntoma**: `terraform plan` muestra cambios que no existen

**Causa**: State local desincronizado con AWS

**Solución**:
```bash
# Actualizar state
terraform refresh

# O destruir y recrear (requiere confirmación)
terraform destroy
terraform apply

# O usar remote state (recomendado para producción)
# Ver: https://www.terraform.io/language/settings/backends/s3
```

---

## Mantenimiento

### Backups

```bash
# Backup de Terraform State
aws s3 cp terraform.tfstate s3://backup-bucket/fraud-detection/$(date +%Y%m%d-%H%M%S).tfstate

# Backup de configuración
git commit -am "Backup antes de cambios"
git push origin main
```

### Updates de Dependencias

```bash
# Verificar nuevas versiones de providers
terraform init -upgrade

# Planificar cambios
terraform plan

# Aplicar si es seguro
terraform apply
```

### Scaling Dinámico

```bash
# Aumentar instancias del endpoint
terraform apply -var="sagemaker_initial_instance_count=3"

# Cambiar tipo de instancia
terraform apply -var="sagemaker_instance_type=ml.m5.xlarge"
```

### Disaster Recovery

```bash
# Si el endpoint falla completamente:

# 1. Verificar logs
aws logs tail /aws/sagemaker/Endpoints/endpoint-fraudes-v5

# 2. Destruir endpoint problemático
terraform destroy -target=aws_sagemaker_endpoint.fraud_detection

# 3. Recrear desde estado
terraform apply -target=aws_sagemaker_endpoint.fraud_detection

# 4. Verificar
aws sagemaker describe-endpoint --endpoint-name endpoint-fraudes-v5
```

---

## Contacto y Soporte

**Propietario del Proyecto**: Equipo de Fraudes  
**Región**: us-east-1  
**Ambiente**: Production  
**Última Actualización**: 3 de Febrero de 2026

### Documentos Relacionados

- [README.md](README.md) - Guía rápida
- [Fraudes_API_Postman_Collection.json](Fraudes_API_Postman_Collection.json) - Colección de pruebas
- Código Terraform: `terraform/` directorio

---

**Fin de Documentación Técnica**
