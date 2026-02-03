# 🔧 Terraform Troubleshooting Guide

## Problemas Comunes y Soluciones

### 1. `terraform init` Fallos

#### Error: "Error installing provider..."
```bash
Error: Failed to download module
```

**Causa:** Conexión a internet o credenciales de AWS incorrectas

**Solución:**
```bash
# Limpiar caché de Terraform
rm -rf .terraform
rm -rf .terraform.lock.hcl

# Intentar de nuevo con backend deshabilitado primero
terraform init -backend=false

# Si funciona, habilitar backend
terraform init
```

---

#### Error: "Invalid provider configuration"
```bash
Error: Invalid provider configuration
```

**Causa:** terraform.tfvars tiene valores inválidos

**Solución:**
```bash
# Validar archivo
terraform validate

# Si hay errores, revisar terraform.tfvars:
cat terraform.tfvars
```

---

### 2. `terraform plan` Fallos

#### Error: "InvalidUserID.NotFound"
```bash
Error: creating SageMaker Model: ValidationException: 
Could not validate IAM role ARN
```

**Causa:** AWS Account ID incorrecto o rol no existe

**Solución:**
```bash
# Verificar account ID actual
aws sts get-caller-identity --query Account --output text

# Actualizar terraform.tfvars con ID correcto
sed -i 's/aws_account_id = ".*"/aws_account_id = "YOUR_ID"/' terraform.tfvars

# O simplemente editar manualmente
vi terraform.tfvars
```

---

#### Error: "AccessDenied"
```bash
Error: error reading ECR Repository: AccessDenied
```

**Causa:** AWS credentials no tienen permisos

**Solución:**
```bash
# Verificar credentials actuales
aws sts get-caller-identity

# Si la identidad es incorrecta, reconfigura
aws configure

# O usa variables de entorno
export AWS_PROFILE=tu-perfil
terraform plan
```

---

#### Error: "Docker image not found"
```bash
Error: data "aws_ecr_image": Image not found
```

**Causa:** Docker build falló o Dockerfile tiene problemas

**Solución:**
```bash
# Verificar Dockerfile manualmente
docker build -t fraud-detection-api:latest ..

# Si build falla, revisar errores
docker build -t fraud-detection-api:latest .. --progress=plain

# Actualizar requirements.txt si es necesario
vi ../requirements.txt

# Hacer build de nuevo
docker build -t fraud-detection-api:latest --no-cache ..

# Luego intentar Terraform de nuevo
terraform plan
```

---

### 3. `terraform apply` Fallos

#### Error: "TimeoutException"
```bash
Error: waiting for SageMaker Endpoint update
```

**Causa:** Endpoint tardando más de lo esperado (normal puede tardar 5-10 min)

**Solución:**
```bash
# Esperar más tiempo y chequear estado manualmente
aws sagemaker describe-endpoint --endpoint-name endpoint-fraudes-prod --region us-east-1

# Ver logs detallados
TF_LOG=DEBUG terraform apply tfplan

# Si sigue fallando, destruye y reintenta
terraform destroy -auto-approve
terraform apply
```

---

#### Error: "Your transaction has expired"
```bash
Error: RequestId: xxx InvalidSignatureException: Signature is too old
```

**Causa:** Reloj del sistema desfasado

**Solución:**
```bash
# En Windows PowerShell (como admin)
Set-Date (Get-Date).AddMinutes(-5)  # Si estás adelantado

# O sincronizar hora de Windows
w32tm /resync

# En Mac
sudo ntpdate -s time.nist.gov

# En Linux
sudo systemctl restart systemd-timesyncd
```

---

#### Error: "ECR Push Failure"
```bash
Error: pushing image to ECR
```

**Causa:** Autenticación con ECR falló

**Solución:**
```bash
# Limpiar Docker login
docker logout

# Login a ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 761951921633.dkr.ecr.us-east-1.amazonaws.com

# Verificar que puedes ver el repositorio
aws ecr describe-repositories --region us-east-1

# Reintentar Terraform
terraform apply
```

---

### 4. API Gateway Fallos

#### Error: "Could not find method"
```bash
Error: describing API Gateway method
```

**Causa:** Cambios en API Gateway no se aplicaron correctamente

**Solución:**
```bash
# Destruir API Gateway
terraform destroy -target aws_api_gateway_deployment.fraud_detection

# Aplicar de nuevo
terraform apply

# O simplemente
terraform taint aws_api_gateway_deployment.fraud_detection
terraform apply
```

---

#### Error: "Invalid integration type"
```bash
Error: invalid integration type for API Gateway
```

**Causa:** Cambio en SageMaker ARN no está sincronizado

**Solución:**
```bash
# Rerefresh todo
terraform refresh

# Ver cambios
terraform plan

# Aplicar
terraform apply
```

---

### 5. SageMaker Fallos

#### Error: "Could not download model artifacts"
```bash
Error: SageMaker could not download image from ECR
```

**Causa:** Docker image URI incorrecta o imagen no existe

**Solución:**
```bash
# Verificar imagen existe
aws ecr describe-images --repository-name fraud-detection-api --region us-east-1

# Si no está, hacer push manual
docker tag fraud-detection-api:latest 761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest
docker push 761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest

# Refresca Terraform
terraform refresh
terraform plan
```

---

#### Error: "Insufficient capacity"
```bash
Error: Could not instantiate SageMaker Endpoint with ml.m5.large
```

**Causa:** Tipo de instancia no disponible en la región

**Solución:**
```bash
# Ver instancias disponibles
aws sagemaker list-training-instance-types --region us-east-1

# Cambiar en terraform.tfvars
sed -i 's/sagemaker_instance_type = ".*"/sagemaker_instance_type = "ml.t3.medium"/' terraform.tfvars

# O editar manualmente
vi terraform.tfvars

# Aplicar cambios
terraform plan
terraform apply
```

---

### 6. IAM & Permissions Fallos

#### Error: "User is not authorized"
```bash
Error: User: arn:aws:iam::xxxx is not authorized
```

**Causa:** Usuario IAM no tiene permisos suficientes

**Solución:**
```bash
# Verificar qué usuario está usando
aws sts get-caller-identity

# Asignar permisos necesarios (adjuntar policy a usuario):
# En AWS Console: IAM > Users > [Tu usuario] > Attach policies
# Policies necesarias:
#   - AmazonSageMakerFullAccess
#   - AmazonEC2ContainerRegistryFullAccess
#   - APIGatewayFullAccess
#   - IAMFullAccess

# O usar AWS root (no recomendado pero funciona para testing)
```

---

### 7. Docker Provisioner Fallos

#### Error: "local-exec provisioner failed"
```bash
Error: Error running command 'docker build ...'
```

**Causa:** Docker no está corriendo

**Solución:**
```bash
# Reiniciar Docker
# Windows:
Start-Process "C:\Program Files\Docker\Docker\Docker.exe"

# Mac:
open /Applications/Docker.app

# Linux:
sudo systemctl restart docker

# Verificar que esté corriendo
docker ps

# Reintentar
terraform apply
```

---

#### Error: "permission denied while trying to connect to Docker daemon"
```bash
Error: permission denied while trying to connect to Docker daemon
```

**Causa:** Usuario no tiene permisos de Docker

**Solución:**
```bash
# En Linux, agregar usuario al grupo docker
sudo usermod -aG docker $USER
newgrp docker

# En Windows/Mac, reinstalar Docker y reiniciar
```

---

### 8. Limpieza y Reset

#### Destruir TODO y empezar de cero
```bash
# Destruir recursos de AWS
terraform destroy

# Limpiar archivos locales
rm -rf .terraform
rm -rf .terraform.lock.hcl
rm -f terraform.tfstate*
rm -f tfplan

# Reiniciar
terraform init
```

---

#### Si algo está atascado
```bash
# Ver qué recursos dice Terraform que existen
terraform state list

# Si un recurso está corrupto, eliminarlo del estado
terraform state rm aws_sagemaker_endpoint.fraud_detection

# Esto NO elimina el recurso de AWS, solo del estado de Terraform
# Luego puedes destruirlo manualmente en AWS Console
```

---

### 9. Debugging Avanzado

#### Ver logs detallados
```bash
# Máximo nivel de debug
export TF_LOG=DEBUG
terraform plan
terraform apply

# Guardar logs en archivo
export TF_LOG_PATH=./terraform-debug.log
terraform apply

# Ver logs
tail -f ./terraform-debug.log
```

---

#### Simulación de cambios sin aplicar
```bash
# Ver qué cambios se harían
terraform plan -out=tfplan

# Revisar plan en detalle
cat tfplan  # (formato binario, pero puedes verlo así)

# Convertir a JSON para mejor lectura
terraform plan -json > plan.json
jq . plan.json
```

---

### 10. Verificación de Health Check

#### Script rápido de diagnóstico
```bash
#!/bin/bash

echo "🔍 Terraform Health Check"
echo ""

echo "1. Verificar Terraform:"
terraform version
echo ""

echo "2. Verificar AWS:"
aws sts get-caller-identity
echo ""

echo "3. Verificar Docker:"
docker ps
echo ""

echo "4. Verificar estado:"
terraform state list
echo ""

echo "5. Verificar ECR:"
aws ecr describe-repositories --region us-east-1
echo ""

echo "6. Verificar SageMaker:"
aws sagemaker list-endpoints --region us-east-1
echo ""

echo "7. Verificar API Gateway:"
aws apigateway get-rest-apis --region us-east-1
echo ""
```

---

## 📋 Checklist para Debugging

- [ ] AWS Credentials configuradas correctamente (`aws sts get-caller-identity`)
- [ ] Account ID correcto en terraform.tfvars
- [ ] Reloj del sistema sincronizado
- [ ] Docker está corriendo (`docker ps`)
- [ ] Dockerfile existe en raíz del proyecto
- [ ] Permisos IAM suficientes en usuario AWS
- [ ] terraform.tfstate no está corrupto (`terraform state list`)
- [ ] No hay recursos parcialmente creados en AWS Console
- [ ] terraform.lock.hcl no tiene conflictos de versionamiento

---

## 🚨 Emergencias

### "He roto TODO y no puedo volver atrás"

```bash
# 1. Destruir todos los recursos
terraform destroy -auto-approve

# 2. Esperar 2-3 minutos a que se destruyan
# 3. Verificar que no queden recursos en AWS Console

# 4. Empezar de cero
rm -rf .terraform
rm -f .terraform.lock.hcl
rm -f terraform.tfstate*
rm -f tfplan

# 5. Reiniciar
terraform init
terraform plan
terraform apply
```

---

## 📞 Recursos Adicionales

- **Terraform Docs:** https://www.terraform.io/docs
- **AWS Provider Terraform:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **SageMaker Terraform:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_endpoint
- **API Gateway Terraform:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api

---

**Última actualización:** 2024-01-XX
**Versión Terraform:** 1.0+
**Versión AWS Provider:** 5.0+
