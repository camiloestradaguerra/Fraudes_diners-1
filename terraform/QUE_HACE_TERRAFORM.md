# ¿Qué Hace Este Terraform?

Este Terraform automatiza el **despliegue completo de una API de detección de fraudes en AWS**. Crea toda la infraestructura necesaria desde cero sin intervención manual.

## 🎯 Objetivo Final

Desplegar una **API REST en API Gateway** que:
- Recibe solicitudes de predicción de fraude
- Las envía a un **modelo SageMaker** entrenado
- Retorna la predicción (fraude o no fraude)

## 🏗️ Arquitectura que Crea

```
Usuario
   ↓
[API Gateway REST API]  ← Punto de entrada HTTPS
   ↓
[IAM Role API Gateway] ← Autorización
   ↓
[SageMaker Endpoint]    ← Ejecuta el modelo ML
   ↓
[Docker Image (ECR)]    ← Contiene el modelo + código
```

## 📁 Archivos Terraform Principales

### **provider.tf** (Configuración inicial)
- Define que usamos AWS (región us-east-1)
- Especifica versiones de Terraform y plugins necesarios
- Tags globales para todas las recursos

### **variables.tf** (Parámetros configurables)
- `aws_account_id`: Tu cuenta AWS (761951921633)
- `aws_region`: Región (us-east-1)
- `project_name`: "fraudes"
- `environment`: "prod"
- `github_repository_url`: Dónde obtiene el código
- `github_branch`: Rama a usar (terraform_exp)

### **locals.tf** (Variables locales)
- Construye valores complejos a partir de variables
- Ej: `docker_image_uri = "761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest"`

### **ecr.tf** (Repositorio Docker)
Crea:
1. **ECR Repository** - Almacena imágenes Docker
2. **ECR Lifecycle Policy** - Mantiene solo las últimas 5 imágenes (para no llenar)
3. **CodeBuild Project** - Máquina virtual que:
   - Clona el código desde GitHub
   - Ejecuta `buildspec.yml` (instrucciones de compilación)
   - Construye la imagen Docker
   - La sube a ECR

**buildspec.yml** (archivo en raíz del repo) le dice a CodeBuild:
```bash
docker build -t imagen_docker .           # Construye
docker push imagen_a_ecr                  # Sube a ECR
```

### **sagemaker.tf** (Modelo ML)
Crea:
1. **SageMaker Model** - Define el modelo que ejecutará
   - Usa la imagen Docker del ECR
   - Especifica que ejecute `main.py`
   
2. **SageMaker Endpoint Configuration** - Define recursos
   - Tipo de máquina: `ml.m5.large` (CPU)
   - Cantidad de instancias: 1
   
3. **SageMaker Endpoint** - Servidor vivo del modelo
   - Espera en un puerto esperando solicitudes
   - Retorna predicciones

### **api_gateway.tf** (API REST)
Crea:
1. **REST API** en API Gateway
   - Endpoint público HTTPS
   - Ej: `https://o45wq48k1c.execute-api.us-east-1.amazonaws.com/prod/fraude`

2. **Resource "fraude"** - Path `/fraude`

3. **Method POST** - Acepta POST requests

4. **Integration** - Conecta API Gateway → SageMaker
   - Toma el JSON de la solicitud
   - Lo envía al SageMaker Endpoint
   - Retorna la respuesta

### **iam.tf** (Seguridad y Permisos)
Crea **3 roles IAM**:

1. **CodeBuild Role**
   - Puede: subir a ECR, escribir logs, acceder a credenciales
   - Necesario para compilar Docker image

2. **SageMaker Execution Role**
   - Puede: leer del ECR, ejecutar el modelo
   - Necesario para que SageMaker acceda a la imagen

3. **API Gateway Role**
   - Puede: invocar el SageMaker Endpoint
   - Necesario para que API Gateway llame a SageMaker

### **outputs.tf** (Resultados)
Imprime después de crear todo:
```
api_invoke_url = "https://o45wq48k1c.execute-api.us-east-1.amazonaws.com/prod/fraude"
docker_image_uri = "761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest"
sagemaker_endpoint_name = "Fraudes-Diners-Prod-Endpoint"
```

## 🔄 Flujo Completo

### Paso 1: `terraform plan`
```
Analiza la configuración
Determina qué recursos crear
Muestra el plan (16 recursos a crear)
```

### Paso 2: `terraform apply`
```
1. Crea ECR Repository (almacén de imágenes)
2. Crea CodeBuild Project
3. CodeBuild automáticamente:
   - Clona código desde GitHub (rama terraform_exp)
   - Ejecuta buildspec.yml
   - Construye Docker image
   - La sube a ECR con tag "latest"
4. Crea SageMaker Model (referencias la imagen en ECR)
5. Crea SageMaker Endpoint (que ejecuta el modelo)
6. Crea API Gateway REST API
7. Conecta API Gateway → SageMaker
8. Crea IAM roles para todo
```

**Tiempo total:** ~13-15 minutos
- CodeBuild compilando: ~8-10 min
- SageMaker creando endpoint: ~4-5 min

### Paso 3: Usar la API
```bash
curl -X POST https://o45wq48k1c.execute-api.us-east-1.amazonaws.com/prod/fraude \
  -H "Content-Type: application/json" \
  -d '{"monto": 100, "tipo": "credito", ...}'

# Respuesta:
# {"prediccion": "fraude", "confianza": 0.95}
```

### Paso 4: `terraform destroy`
```
Elimina TODO:
- API Gateway REST API
- SageMaker Endpoint
- SageMaker Model
- ECR Repository
- CodeBuild Project
- Todos los IAM Roles
- CloudWatch Logs
```

## 🔑 Conceptos Clave

| Componente | Función |
|------------|---------|
| **ECR** | Almacén de imágenes Docker en AWS |
| **CodeBuild** | Máquina virtual que compila y construye |
| **SageMaker** | Servicio de ML que ejecuta el modelo |
| **API Gateway** | Expone un HTTP endpoint público |
| **IAM Roles** | Define qué servicio puede hacer qué |
| **Docker** | Empaqueta el código + dependencias |

## ⚙️ Configuración en terraform.tfvars

```hcl
aws_account_id           = "761951921633"
aws_region               = "us-east-1"
project_name             = "fraudes"
environment              = "prod"
github_repository_url    = "https://github.com/camiloestradaguerra/Fraudes_diners-1.git"
github_branch            = "terraform_exp"
enable_codebuild         = true              # Compila Docker
docker_local_build       = false             # No compila en local
enable_docker_push       = false             # CodeBuild lo hace
```

## 📊 Recursos que Crea

**Total: 16 recursos**

| Recurso | Cantidad | Propósito |
|---------|----------|-----------|
| ECR Repository | 1 | Almacena imagen Docker |
| CodeBuild Project | 1 | Compila la imagen |
| CloudWatch Log Group | 1 | Logs del build |
| SageMaker Model | 1 | Define el modelo ML |
| SageMaker Endpoint Config | 1 | Configuración del endpoint |
| SageMaker Endpoint | 1 | Ejecuta el modelo |
| API Gateway REST API | 1 | Punto de entrada HTTP |
| API Gateway Resource | 1 | Path `/fraude` |
| API Gateway Method | 1 | Método POST |
| API Gateway Integration | 1 | Conexión a SageMaker |
| IAM Roles | 3 | CodeBuild, SageMaker, API Gateway |
| IAM Policies | 3 | Permisos específicos |
| Otros (attachments, etc) | 2 | - |

## 🎓 Para Entender Mejor

1. El Dockerfile (en raíz) define cómo se construye la imagen
2. El buildspec.yml le dice a CodeBuild cómo ejecutar Docker
3. El endpoint_prototipo/main.py es la aplicación FastAPI
4. Terraform automatiza todo esto sin tocar AWS console

## ❌ Errores Comunes Que Resolvimos

1. **"Requested image not found"**
   - Causa: Imagen Docker nunca se compiló
   - Solución: CodeBuild debe terminar primero

2. **"Bad substitution"**
   - Causa: Syntax bash `${VAR:0:7}` en shell sh
   - Solución: Usar POSIX compatible `cut -c 1-7`

3. **ECR data source errors**
   - Causa: Intentar leer imagen que no existe
   - Solución: Deshabilitar el data source, dejar que el destroy funcione

---

**Resumen:** Terraform automatiza un pipeline CI/CD completo que:
1. Compila código Python
2. Lo empaqueta en Docker
3. Lo almacena en ECR
4. Lo ejecuta en SageMaker
5. Lo expone con API Gateway
