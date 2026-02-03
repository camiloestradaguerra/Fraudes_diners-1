# 🚀 Terraform MLOps - Fraud Detection API

Solución **end-to-end con Terraform** que automatiza TODO:
- Docker build
- Push a ECR
- SageMaker Model + Endpoint
- API Gateway
- IAM Roles y Policies

## 🎯 Requisitos

```bash
# Terraform CLI
terraform version  # v1.0+

# AWS CLI
aws --version      # v2+

# Docker
docker --version   # 20.10+

# Credenciales AWS configuradas
aws sts get-caller-identity
```

## 📋 Inicializar Terraform

```bash
cd terraform

# Descargar plugins
terraform init

# Ver qué se va a crear
terraform plan

# (Opcional) Guardar plan
terraform plan -out=tfplan
```

## 🚀 Desplegar

```bash
# Opción 1: Plan + Apply interactivo
terraform apply

# Opción 2: Aplicar con plan guardado
terraform apply tfplan

# Opción 3: Auto-approve (NO recomendado en prod)
terraform apply -auto-approve
```

**Tiempo estimado:** 5-7 minutos

## 📊 Ver Recursos

```bash
# Listar estado
terraform state list

# Ver detalles
terraform state show aws_sagemaker_endpoint.fraud_detection

# Ver outputs
terraform output

# Ver output específico
terraform output api_invoke_url
```

## 🧪 Testing

```bash
# Obtener URL del API
API_URL=$(terraform output -raw api_invoke_url)

# Hacer llamada
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX-001",
    "monto": 1000.0,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "Store",
    "especialidad": "RETAIL"
  }'
```

## 🛠️ Cambiar Variables

Editar `terraform.tfvars`:

```hcl
# Para cambiar a staging
environment = "staging"

# Para cambiar instancia SageMaker
sagemaker_instance_type = "ml.m5.xlarge"

# Para deshabilitar Docker build (usar imagen existente)
docker_local_build = false
```

Luego:
```bash
terraform apply
```

## 🗑️ Destruir Recursos

```bash
# Ver qué se eliminará
terraform destroy -plan

# Destruir
terraform destroy

# Destruir sin confirmación
terraform destroy -auto-approve
```

## 📁 Estructura

```
terraform/
├── provider.tf          # Configuración de providers
├── variables.tf         # Variables con validaciones
├── locals.tf           # Variables locales calculadas
├── terraform.tfvars    # Valores por defecto
├── backend.tf          # Backend remoto (opcional)
├── ecr.tf             # ECR + Docker build/push
├── iam.tf             # Roles y políticas IAM
├── sagemaker.tf       # Modelo + Endpoint SageMaker
├── api_gateway.tf     # REST API Gateway
├── outputs.tf         # Outputs
└── README.md          # Este archivo
```

## 🔍 Validación

```bash
# Validar sintaxis
terraform validate

# Formatear código
terraform fmt -recursive

# Linting (si tienes tflint)
tflint
```

## 🔐 Mejores Prácticas

✅ Usar `terraform.tfvars` para valores sensibles  
✅ Usar estado remoto (S3 + DynamoDB) para producción  
✅ Usar `terraform_remote_state` para módulos  
✅ Implementar CICD con `terraform plan` + `terraform apply`  
✅ Usar `terraform workspace` para múltiples ambientes  

## 🐛 Troubleshooting

### "Error: error during connect to Docker daemon"
```bash
# Asegurar Docker está corriendo
docker ps
```

### "Error: InvalidInputException in SageMaker"
```bash
# Verificar que la imagen está en ECR
aws ecr describe-images --repository-name fraud-detection-api
```

### "Terraform destroyed resources but API still responds"
```bash
# Puede haber recursos dependientes
# Esperar 5 minutos
# Verificar en AWS Console
```

## 📚 Documentación Adicional

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS SageMaker Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_endpoint)
- [Docker Terraform Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)

---

**Ventaja sobre CloudFormation:**
- ✅ Maneja Docker build/push automáticamente
- ✅ Lenguaje más legible (HCL2)
- ✅ Mejor validación de variables
- ✅ Estado más inteligente
- ✅ Módulos reutilizables

**Estado:** ✅ Production Ready
