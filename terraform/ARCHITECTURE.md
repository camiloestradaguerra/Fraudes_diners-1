# Arquitectura Terraform - Fraud Detection MLOps

## 📐 Diagrama Completo

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLIENTE (Usuario)                           │
│                  Hace predicción de fraude                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    POST /fraude (JSON)
                             │
                             ▼
            ┌────────────────────────────────┐
            │    API Gateway (REST API)      │
            │  fraudes-api-prod              │
            └───────────┬────────────────────┘
                        │
              Integration: SageMaker Runtime
                        │
                        ▼
          ┌─────────────────────────────────┐
          │   SageMaker Endpoint            │
          │   endpoint-fraudes-prod         │
          │   Instance: ml.m5.large         │
          │   Status: InService             │
          └──────────┬──────────────────────┘
                     │
                     ▼
          ┌─────────────────────────────────┐
          │   Docker Container (en SageMaker)
          │   fraud-detection-api:latest    │
          │   (Modelo ML + FastAPI)         │
          └──────────┬──────────────────────┘
                     │
         Imagen almacenada en ECR
                     │
                     ▼
          ┌─────────────────────────────────┐
          │   AWS ECR Repository            │
          │   fraud-detection-api:latest    │
          │   (Private registry)            │
          └─────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│              SEGURIDAD: IAM Roles & Policies                   │
├────────────────────────────────────────────────────────────────┤
│  • sagemaker-execution-fraud-detection-prod                    │
│    → sts:AssumeRole (SageMaker)                                │
│    → AmazonSageMakerFullAccess                                 │
│    → ECR Access (GetImage, GetAuthToken)                       │
│                                                                │
│  • apigateway-sagemaker-fraud-detection-prod                  │
│    → sts:AssumeRole (API Gateway)                              │
│    → sagemaker:InvokeEndpoint                                  │
└────────────────────────────────────────────────────────────────┘
```

## 🔄 Flujo de Terraform

```
1. terraform init
   ├─ Descargar providers (AWS, Docker, null)
   ├─ Configurar backend
   └─ Crear .terraform/

2. terraform plan
   ├─ Validar sintaxis
   ├─ Resolver interpolaciones
   ├─ Comparar con estado actual
   ├─ Docker build (local-exec)
   └─ Mostrar cambios (tfplan)

3. terraform apply tfplan
   ├─ Docker build (si cambió Dockerfile)
   │  └─ docker build -t fraud-detection-api:latest .
   │
   ├─ Docker push a ECR (si cambió imagen)
   │  ├─ aws ecr get-login-password
   │  ├─ docker login
   │  ├─ docker tag
   │  └─ docker push
   │
   ├─ Crear ECR Repository
   │  ├─ aws_ecr_repository.fraud_detection
   │  └─ aws_ecr_lifecycle_policy
   │
   ├─ Crear IAM Roles
   │  ├─ aws_iam_role.sagemaker_execution
   │  ├─ aws_iam_role.apigateway_sagemaker
   │  ├─ Attach policies
   │  └─ aws_iam_role_policy (custom policies)
   │
   ├─ Crear SageMaker
   │  ├─ aws_sagemaker_model
   │  ├─ aws_sagemaker_endpoint_configuration
   │  └─ aws_sagemaker_endpoint
   │
   └─ Crear API Gateway
      ├─ aws_api_gateway_rest_api
      ├─ aws_api_gateway_resource (/fraude)
      ├─ aws_api_gateway_method (POST)
      ├─ aws_api_gateway_integration (SageMaker)
      └─ aws_api_gateway_deployment
```

## 📦 Dependencias de Recursos

```
terraform.tfvars
    ↓
provider.tf (AWS, Docker, null)
    ↓
┌───────────────────────────────────────┐
│  variables.tf (validaciones)          │
│  locals.tf (cálculos)                 │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│  ecr.tf (Docker build + ECR)          │ ← Provisioner local-exec
│    ├─ aws_ecr_repository              │
│    ├─ null_resource.docker_build      │
│    └─ null_resource.docker_push       │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│  iam.tf (Roles + Policies)            │
│    ├─ aws_iam_role (SageMaker)         │
│    ├─ aws_iam_role (API Gateway)      │
│    └─ aws_iam_role_policy             │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│  sagemaker.tf (Model + Endpoint)      │
│    ├─ Depende de: ECR push, IAM roles │
│    ├─ aws_sagemaker_model             │
│    ├─ aws_sagemaker_endpoint_config   │
│    └─ aws_sagemaker_endpoint          │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│  api_gateway.tf (REST API)            │
│    ├─ Depende de: SageMaker endpoint  │
│    ├─ aws_api_gateway_rest_api        │
│    ├─ aws_api_gateway_integration     │
│    └─ aws_api_gateway_deployment      │
└───────────────────────────────────────┘
    ↓
outputs.tf (Exportar valores)
```

## 🔐 Variables Sensibles

**NUNCA** comitear:
- `terraform.tfstate` (contiene secretos)
- `terraform.tfvars` (contiene credenciales)

**Mejores prácticas:**
```bash
# Usar variables de entorno
export TF_VAR_aws_account_id="761951921633"

# O usar archivo separado
terraform apply -var-file="prod.tfvars"

# O usar backend remoto encriptado (recomendado)
# S3 + DynamoDB + KMS
```

## 🚀 Ventajas de Terraform vs CloudFormation

| Característica | Terraform | CloudFormation |
|---|---|---|
| Docker Build | ✅ Nativo (provisioners) | ❌ Requiere CodeBuild |
| Docker Push | ✅ Nativo (provisioners) | ❌ Requiere CodeBuild |
| ECR Integration | ✅ Directa | ✅ Directa |
| Lenguaje | ✅ HCL2 (declarativo) | ✅ YAML/JSON (complejo) |
| Multi-cloud | ✅ AWS, GCP, Azure | ❌ Solo AWS |
| Estado | ✅ Inteligente | ⚠️ Básico |
| Rollback | ✅ Automático | ⚠️ Manual |
| Módulos | ✅ Reutilizables | ⚠️ Nested stacks |
| Validación | ✅ Fuerte | ⚠️ Débil |

## 📊 Ciclo de Vida Completo

```
Desarrollo:
  1. Editar terraform/
  2. terraform init
  3. terraform plan
  4. Revisar plan
  5. terraform apply

Cambios:
  1. Editar terraform.tfvars
  2. terraform plan
  3. terraform apply

Scaling:
  1. Cambiar sagemaker_instance_type
  2. terraform apply

Destruir:
  1. terraform destroy
  2. Confirmar
  3. Todos los recursos eliminados
```

## 🔍 Monitoreo Terraform

```bash
# Ver estado actual
terraform state list
terraform state show aws_sagemaker_endpoint.fraud_detection

# Detectar cambios en AWS (drift)
terraform plan

# Ver outputs en tiempo real
terraform output -json

# Debug
TF_LOG=DEBUG terraform apply
```

---

**Conclusión:** Terraform es ideal para MLOps porque:
- ✅ Maneja el stack completo
- ✅ Docker build/push automático
- ✅ Estado reproducible
- ✅ Fácil de versionar
- ✅ CICD-friendly
