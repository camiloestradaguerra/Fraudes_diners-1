# 📖 Terraform Fraud Detection - Índice de Documentación

## 🚀 Para Empezar Rápido

### Si tienes 5 minutos
→ Lee: [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)

### Si tienes 15 minutos
→ Lee: [README.md](README.md) completo

### Si estás listo para desplegar
```bash
cd terraform
bash validate.sh      # Verifica setup (5 min)
terraform init        # Descarga providers (2 min)
terraform plan        # Preview de cambios (2 min)
terraform apply       # Deploy actual (7-10 min)
bash test.sh          # Verifica todo funciona (2 min)
```

---

## 📚 Guía por Caso de Uso

### "Necesito entender la arquitectura"
1. [ARCHITECTURE.md](ARCHITECTURE.md) - Diagramas completos
2. [README.md](README.md) - Explicación de componentes

### "Quiero desplegar ahora"
1. [README.md](README.md#inicializaci%C3%B3n) - Sección Inicialización
2. [deploy.sh](deploy.sh) - Script interactivo

### "Algo no funciona"
1. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Busca tu error
2. [README.md](README.md#troubleshooting) - Sección Troubleshooting

### "Necesito cambiar configuración"
1. [README.md](README.md#modificaci%C3%B3n-de-variables) - Guía de variables
2. [variables.tf](variables.tf) - Definición de variables con validación

### "Quiero entender el código"
1. [provider.tf](provider.tf) - Providers y versiones
2. [variables.tf](variables.tf) - Input variables
3. [locals.tf](locals.tf) - Valores computados
4. [ecr.tf](ecr.tf) - ECR y Docker automation
5. [iam.tf](iam.tf) - Roles y policies
6. [sagemaker.tf](sagemaker.tf) - SageMaker resources
7. [api_gateway.tf](api_gateway.tf) - API Gateway

### "Necesito testear la solución"
1. [test.sh](test.sh) - Suite de tests automática
2. [README.md](README.md#testing) - Tests manuales

---

## 📁 Estructura de Archivos

```
terraform/
├── 🔧 CONFIGURACIÓN
│   ├── provider.tf              ← Providers AWS, Docker
│   ├── variables.tf             ← Input variables con validación
│   ├── locals.tf                ← Valores computados
│   ├── terraform.tfvars         ← Valores por defecto (prod)
│   └── backend.tf               ← State management
│
├── 🏗️ INFRAESTRUCTURA
│   ├── ecr.tf                   ← ECR + Docker build/push
│   ├── iam.tf                   ← Roles y policies
│   ├── sagemaker.tf             ← Model, Config, Endpoint
│   ├── api_gateway.tf           ← REST API + Integration
│   └── outputs.tf               ← Exportar valores
│
├── 📚 DOCUMENTACIÓN
│   ├── README.md                ← Guía principal (150+ líneas)
│   ├── EXECUTIVE_SUMMARY.md     ← Resumen ejecutivo
│   ├── ARCHITECTURE.md          ← Diagramas y flujos
│   ├── TROUBLESHOOTING.md       ← Guía de problemas
│   └── INDEX.md                 ← Este archivo
│
├── 🛠️ SCRIPTS
│   ├── validate.sh              ← Pre-validación del setup
│   ├── test.sh                  ← Tests post-deployment
│   ├── deploy.sh                ← Menú interactivo
│   └── .gitignore               ← Excluye archivos Terraform
│
└── 📊 OUTPUTS (creados durante terraform apply)
    ├── .terraform/              ← Providers descargados
    ├── .terraform.lock.hcl      ← Versiones bloqueadas
    ├── terraform.tfstate        ← Estado local (IMPORTANTE)
    ├── terraform.tfstate.backup ← Backup automático
    └── tfplan                   ← Plan binario (si se crea)
```

---

## 🎯 Flujo de Documentación Recomendado

```
1. EXECUTIVE_SUMMARY.md
   (¿Qué se va a crear? ¿Cuánto tiempo?)
        ↓
2. ARCHITECTURE.md
   (¿Cómo funciona todo junto? Diagramas)
        ↓
3. README.md (sección Inicialización)
   (¿Cómo empiezo? Paso a paso)
        ↓
4. validate.sh
   (¿Tengo todo lo necesario?)
        ↓
5. terraform plan
   (¿Qué va a cambiar?)
        ↓
6. README.md (sección Testing)
   (¿Funciona todo?)
        ↓
7. TROUBLESHOOTING.md (si hay errores)
   (¿Qué salió mal? ¿Cómo lo arreglo?)
```

---

## 📋 Archivos de Configuración Detallados

### [provider.tf](provider.tf)
**Propósito:** Declarar providers y versiones
**Contiene:**
- AWS Provider v5.0+
- Docker Provider v3.0+
- Null Provider v3.0+
- Default tags configuration

**Cuándo editarlo:** Necesitas cambiar versiones de providers

---

### [variables.tf](variables.tf)
**Propósito:** Definir todas las input variables con validación
**Contiene:**
- `aws_account_id` - Tu AWS Account
- `aws_region` - Región AWS
- `environment` - dev/staging/prod
- `docker_image_name` - Nombre imagen Docker
- `docker_image_tag` - Tag de imagen
- `sagemaker_instance_type` - ml.m5.large, etc
- `sagemaker_initial_instance_count` - Número de instancias
- Y más...

**Cuándo editarlo:** Nunca directamente, usa `terraform.tfvars` en su lugar

---

### [terraform.tfvars](terraform.tfvars)
**Propósito:** Valores de configuración para tu entorno
**Contiene:**
- Account ID: 761951921633
- Región: us-east-1
- Environment: prod
- Tags: CostCenter, Team, Project

**⚠️ IMPORTANTE:**
- ✅ Commitear a git (no tiene secretos)
- ❌ NO guardar credentials aquí
- Para secretos usar AWS Secrets Manager

**Cuándo editarlo:**
- Cambiar account ID
- Cambiar región
- Cambiar tipo de instancia
- Cambiar tags

---

### [ecr.tf](ecr.tf)
**Propósito:** ECR Repository + Docker build/push automation
**Crea:**
- AWS ECR Repository
- Lifecycle policy (mantiene últimas 5 imágenes)
- Null resource para docker build (local-exec)
- Null resource para docker push (local-exec)

**¿Qué hace automáticamente?**
1. Detecta cambios en Dockerfile
2. Hace `docker build`
3. Hace `docker tag`
4. Hace `docker push` a ECR

---

### [iam.tf](iam.tf)
**Propósito:** IAM Roles y Policies
**Crea:**
- SageMaker Execution Role (puede acceder a ECR)
- API Gateway Role (puede invocar SageMaker)
- Policies con permisos específicos (least privilege)

**Permisos Incluidos:**
- SageMaker: GetImage, DescribeEndpoint, CloudWatch logs
- API Gateway: InvokeEndpoint (solo el endpoint específico)

---

### [sagemaker.tf](sagemaker.tf)
**Propósito:** SageMaker Model, Endpoint Config, Endpoint
**Crea:**
- SageMaker Model (usando imagen Docker)
- Endpoint Configuration (ml.m5.large, 1 instancia)
- Endpoint (InService, con lifecycle management)

**Ciclo de Vida:**
- Al crear: espera 5-10 minutos
- Al actualizar: ¿Tiene `create_before_destroy`? Sí, sin downtime

---

### [api_gateway.tf](api_gateway.tf)
**Propósito:** REST API integrada con SageMaker
**Crea:**
- REST API (fraud-detection-api)
- Resource (/fraude)
- Method (POST)
- Integration (AWS service: sagemaker-runtime)
- Deployment (prod stage)

**Resultado:**
```
POST https://api-id.execute-api.us-east-1.amazonaws.com/prod/fraude
```

---

### [outputs.tf](outputs.tf)
**Propósito:** Exportar valores importantes después de create
**Exporta:**
- ECR URL
- Docker Image URI
- SageMaker Endpoint Name
- API Gateway URL
- Role ARNs
- Deployment info completo

**Cómo verlas:**
```bash
terraform output                    # Todas
terraform output api_invoke_url     # Una específica
terraform output -json              # JSON format
```

---

## 🔐 Seguridad & Best Practices

### Variables Sensibles
```bash
# ❌ NUNCA hardcodear en código
password = "mi-password"

# ✅ Usar variables de entorno
export TF_VAR_password="mi-password"

# ✅ O usar AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id ...
```

### State File Protection
```bash
# terraform.tfstate contiene datos sensibles
# ✅ Excluido en .gitignore
# ✅ Nunca commitear a git
# ✅ Para teams, usar S3 backend remoto con encryption
```

### IAM Least Privilege
```bash
# Todos los roles tienen permisos específicos
# ✅ SageMaker: solo necesita GetImage + CloudWatch
# ✅ API Gateway: solo puede InvokeEndpoint específico
# ❌ Nunca usamos FullAccess en production
```

---

## 🧪 Scripts Helper

### [validate.sh](validate.sh)
Ejecuta ANTES de `terraform init`:
```bash
cd terraform
bash validate.sh
```

**Valida:**
- ✅ Terraform instalado
- ✅ AWS CLI instalado
- ✅ Docker instalado
- ✅ AWS Credentials
- ✅ terraform.tfvars correctamente formado
- ✅ Dockerfile existe
- ✅ requirements.txt existe

---

### [test.sh](test.sh)
Ejecuta DESPUÉS de `terraform apply`:
```bash
cd terraform
bash test.sh
```

**Tests:**
- ✅ ECR Repository existe
- ✅ Docker Image está en ECR
- ✅ SageMaker Endpoint existe y está InService
- ✅ API Gateway está disponible
- ✅ Invoca API con datos de prueba
- ✅ Verifica IAM Roles

---

### [deploy.sh](deploy.sh)
Menú interactivo:
```bash
cd terraform
bash deploy.sh

# Opciones:
# 1) terraform init
# 2) terraform plan
# 3) terraform apply
# 4) terraform output
# 5) terraform destroy
# 6) Full Deploy (init → plan → apply)
# 7) Full Destroy
```

---

## 📊 Variables en Detalle

### Account & Region (OBLIGATORIO)
```hcl
aws_account_id = "761951921633"
aws_region     = "us-east-1"
```

### Project Naming
```hcl
project_name = "fraud-detection"
environment  = "prod"
# Resultado: fraud-detection-prod
```

### Docker Configuration
```hcl
docker_image_name    = "fraud-detection-api"
docker_image_tag     = "latest"
docker_build_context = ".."  # Raíz del proyecto
```

### SageMaker Configuration
```hcl
sagemaker_instance_type          = "ml.m5.large"
sagemaker_initial_instance_count = 1
```

Instancia types disponibles:
- `ml.t3.medium` - Desarrollo ($0.05/hr)
- `ml.m5.large` - Producción recomendado ($0.36/hr)
- `ml.m5.xlarge` - Alto volumen ($0.71/hr)
- `ml.c5.2xlarge` - CPU-intensive

### API Gateway
```hcl
api_gateway_stage = "prod"
```

### Automation Flags
```hcl
enable_docker_push = true  # Automáticamente pushear a ECR
docker_local_build = true  # Build locally (no CodeBuild)
```

---

## 🔄 Ciclos de Actualización Comunes

### Cambiar Instance Type
```bash
# 1. Editar terraform.tfvars
sagemaker_instance_type = "ml.m5.xlarge"

# 2. Plan
terraform plan
# → Verá: endpoint recreated

# 3. Apply (con downtime ~10 min)
terraform apply
```

### Cambiar Código del Modelo
```bash
# 1. Editar código (en raíz del proyecto)
vi endpoint_prototipo/main.py

# 2. Plan (detecta cambio en Dockerfile)
terraform plan
# → Verá: Docker image will be rebuilt

# 3. Apply
terraform apply
# → docker build → docker push → SageMaker update
```

### Agregar Ambiente Dev
```bash
# 1. Crear dev.tfvars
cp terraform.tfvars dev.tfvars
sed -i 's/environment = "prod"/environment = "dev"/' dev.tfvars

# 2. Deploy con este archivo
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

---

## ⏱️ Tiempos Esperados

| Operación | Tiempo | Notas |
|-----------|--------|-------|
| `terraform init` | 2-3 min | Primera vez descarga providers |
| `terraform plan` | 2 min | Rápido, no cambia nada |
| `docker build` | 3-5 min | Depende del size de imagen |
| `docker push` | 1-2 min | A ECR |
| `terraform apply` | 8-12 min | Endpoint tarda más |
| **TOTAL** | **15-20 min** | Primera ejecución |
| `terraform apply` (cambios) | 5-10 min | Subsecuentes |

---

## 🎓 Para Aprender Más

### Terraform
- [Terraform Official Docs](https://www.terraform.io/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)
- [Terraform Registry](https://registry.terraform.io/)

### AWS
- [SageMaker Docs](https://docs.aws.amazon.com/sagemaker/)
- [API Gateway Docs](https://docs.aws.amazon.com/apigateway/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

### DevOps
- [Infrastructure as Code](https://en.wikipedia.org/wiki/Infrastructure_as_code)
- [CICD Pipelines](https://en.wikipedia.org/wiki/CI/CD)

---

## 🤝 Soporte

### Errores Comunes
→ Ve a [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Questions sobre Terraform
→ Ve a [README.md](README.md#faq)

### Questions sobre Arquitectura
→ Ve a [ARCHITECTURE.md](ARCHITECTURE.md)

---

## ✅ Checklist Pre-Deploy

- [ ] Leí EXECUTIVE_SUMMARY.md
- [ ] Leí ARCHITECTURE.md
- [ ] Ejecuté `bash validate.sh` y pasó
- [ ] Tengo AWS Credentials configuradas
- [ ] Account ID es correcto (761951921633)
- [ ] Docker está corriendo
- [ ] requirements.txt existe
- [ ] Dockerfile existe
- [ ] terraform.tfvars fue revisado

---

## 🚀 Ready to Deploy?

```bash
cd terraform
bash validate.sh          # Valida setup
terraform init            # Descarga providers
terraform plan            # Preview
terraform apply           # Deploy!
bash test.sh              # Verifica
```

---

**Última actualización:** 2024
**Versión Terraform:** 1.0+
**AWS Provider:** 5.0+

¡Mucho éxito con tu deployment! 🎉
