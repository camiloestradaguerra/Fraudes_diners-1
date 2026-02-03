# 📖 EXPLICACIÓN DETALLADA LÍNEA POR LÍNEA - ARCHIVOS TERRAFORM

**Guía completa para entender cada archivo .tf del proyecto**

---

## 🎯 Índice de Archivos

1. [provider.tf](#provider-configuracion-de-proveedores)
2. [variables.tf](#variables-definicion-de-inputs)
3. [locals.tf](#locals-valores-calculados-y-dinamicos)
4. [sagemaker.tf](#sagemaker-modelo-y-endpoint)
5. [api_gateway.tf](#api_gateway-api-rest-integration)
6. [iam.tf](#iam-roles-y-permisos)
7. [ecr.tf](#ecr-registro-docker)
8. [outputs.tf](#outputs-valores-de-salida)
9. [backend.tf](#backend-almacenamiento-de-estado)
10. [terraform.tfvars](#terraformtfvars-valores-actuales)

---

## provider.tf - Configuración de Proveedores

**Propósito**: Define qué proveedores (AWS, Docker, etc.) usará Terraform y sus versiones.

```terraform
terraform {
  required_version = ">= 1.0"
```
- `terraform {}`: Bloque de configuración global de Terraform
- `required_version`: Especifica la versión MÍNIMA de Terraform que se puede usar (1.0 o superior)
- `">= 1.0"`: Operador "mayor o igual a" - acepta cualquier versión 1.0+

```terraform
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
```
- `required_providers {}`: Define qué proveedores (plugins) necesita
- `aws = { ... }`: Proveedor AWS
- `source = "hashicorp/aws"`: Ubicación oficial del proveedor AWS
- `version = "~> 5.0"`: Versión compatible (5.x, pero no 6.0+)
  - `~>` significa: permite cambios en versiones menores (5.1, 5.2, etc.) pero no mayor (6.0)

```terraform
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
```
- `docker {}`: Proveedor para construir/empujar imágenes Docker
- Permite que Terraform ejecute comandos `docker build` y `docker push`

```terraform
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
```
- `null {}`: Proveedor especial para recursos que no crean nada en AWS
- Se usa para ejecutar comandos locales sin crear recursos AWS

```terraform
}

provider "aws" {
  region = var.aws_region
```
- `provider "aws" {}`: Configuración del proveedor AWS
- `region = var.aws_region`: USA la región definida en variables.tf (us-east-1)

```terraform
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
```
- `default_tags {}`: Etiquetas que se APLICAN AUTOMÁTICAMENTE a todos los recursos AWS
- Cada recurso tendrá estas etiquetas sin necesidad de especificarlas
- Útil para rastrear costos y administración

```terraform
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
```
- `provider "docker"`: Configuración de Docker
- `host = "unix:///var/run/docker.sock"`: Ubicación del socket de Docker (Linux/Mac)

---

## variables.tf - Definición de Inputs

**Propósito**: Define QUÉ se puede configurar en terraform.tfvars con tipos y valores por defecto.

```terraform
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```
- `variable "aws_region"`: Define variable que se puede cambiar
- `description`: Explicación de qué es esta variable
- `type = string`: Tipo de dato (texto)
- `default = "us-east-1"`: Si no se proporciona, usa este valor

```terraform
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}
```
- **SIN `default`**: Esta variable es OBLIGATORIA, debe estar en terraform.tfvars
- El usuario DEBE proporcionar el account ID (761951921633)

```terraform
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "fraudes"
}
```
- Nombre del proyecto que se usa en todas partes
- Valor por defecto: "fraudes"
- Se usa en nombres dinámicos (ej: Fraudes-Diners-Prod-Endpoint)

```terraform
variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "prod"
}
```
- Ambiente: prod, staging, dev
- Determina parte del nombre del endpoint
- Valor por defecto: "prod"

```terraform
variable "docker_image_name" {
  description = "Nombre de la imagen Docker"
  type        = string
  default     = "fraud-detection-api"
}
```
- Nombre de la imagen Docker en ECR
- Se usa para construir la imagen y subirla a AWS

```terraform
variable "docker_image_tag" {
  description = "Tag de la imagen Docker"
  type        = string
  default     = "latest"
}
```
- Tag de la imagen Docker (latest, v1.0, etc.)
- Permite versionar imágenes

```terraform
variable "sagemaker_instance_type" {
  description = "SageMaker endpoint instance type"
  type        = string
  default     = "ml.m5.large"
}
```
- Tipo de instancia EC2 que usará SageMaker
- `ml.m5.large`: Máquina de propósito general, buena relación costo-rendimiento
- Otros tipos: `ml.m5.xlarge` (más cara, más potencia), `ml.t3.medium` (más barata)

```terraform
variable "sagemaker_initial_instance_count" {
  description = "Número inicial de instancias"
  type        = number
  default     = 1
}
```
- `type = number`: Tipo numérico (no texto)
- Cuántas máquinas inicialmente (1 = una sola)
- Puede auto-escalar según demanda

```terraform
variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default = {
    Terraform   = "true"
    CostCenter  = "MLOps"
  }
}
```
- `type = map(string)`: Diccionario de pares clave-valor
- Etiquetas para rastreo de costos y administración

```terraform
variable "endpoint_name_suffix" {
  description = "Sufijo para el nombre del endpoint SageMaker (ej: Diners)"
  type        = string
  default     = "Diners"
}
```
- **Variable clave para nombrado dinámico**
- "Diners" es parte de: `Fraudes-Diners-Prod-Endpoint`
- Si cambias a "Testing", obtendrías: `Fraudes-Testing-Prod-Endpoint`

```terraform
variable "api_gateway_name_suffix" {
  description = "Sufijo para el nombre de API Gateway"
  type        = string
  default     = "API"
}
```
- Sufijo para API Gateway
- Crea nombres como: `fraudes-API-prod`

---

## locals.tf - Valores Calculados y Dinámicos

**Propósito**: Calcula valores que se usan en múltiples lugares combinando variables.

```terraform
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )
```
- `locals {}`: Define valores calculados (no inputs)
- `common_tags`: Etiquetas que se aplican a TODOS los recursos
- `merge()`: Combina dos mapas (diccionarios)
  - Toma `var.tags` (del usuario)
  - Agrega Environment, Project, ManagedBy automáticamente
- **Resultado**: Un diccionario unificado de etiquetas

```terraform
  ecr_repository_url = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
```
- **Construcción de URL dinámica**
- Formato: `ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com`
- Ejemplo: `761951921633.dkr.ecr.us-east-1.amazonaws.com`
- `${}`: Sintaxis para incrustar variables en strings

```terraform
  docker_image_uri = "${local.ecr_repository_url}/${var.docker_image_name}:${var.docker_image_tag}"
```
- **URI completa de la imagen Docker**
- Ejemplo: `761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest`
- Se construye usando ECR URL + nombre + tag

```terraform
  sagemaker_model_name = "${var.project_name}-model-${var.environment}"
```
- **Nombre dinámico del modelo**
- Ejemplo: `fraudes-model-prod`
- Patrón: `{proyecto}-model-{ambiente}`

```terraform
  sagemaker_endpoint_config = "${var.project_name}-config-${var.environment}"
```
- **Nombre dinámico de configuración del endpoint**
- Ejemplo: `fraudes-config-prod`
- SageMaker requiere una "configuración" antes de crear el endpoint

```terraform
  sagemaker_endpoint_name = "${title(var.project_name)}-${var.endpoint_name_suffix}-${title(var.environment)}-Endpoint"
```
- **LA FÓRMULA PRINCIPAL - NOMBRE DEL ENDPOINT**
- `title()`: Convierte primera letra a mayúscula
  - `"fraudes"` → `"Fraudes"`
  - `"prod"` → `"Prod"`
- Ejemplo completo: `Fraudes-Diners-Prod-Endpoint`
- **Esto es LO QUE VES en AWS Console**

```terraform
  api_gateway_name = "${var.project_name}-${var.api_gateway_name_suffix}-${var.environment}"
```
- **Nombre dinámico de API Gateway**
- Ejemplo: `fraudes-API-prod`
- Accesible en: `https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/fraude`

```terraform
  iam_role_sagemaker_name = "sagemaker-execution-${var.project_name}-${var.environment}"
  iam_role_apigateway_name = "apigateway-sagemaker-${var.project_name}-${var.environment}"
```
- **Nombres dinámicos de roles IAM**
- Ejemplos:
  - `sagemaker-execution-fraudes-prod`
  - `apigateway-sagemaker-fraudes-prod`
- Cada rol tiene responsabilidades específicas

```terraform
  stack_name = "${var.project_name}-${var.environment}"
}
```
- **Nombre del "stack" (grupo de recursos)**
- Usado para agrupar recursos relacionados

---

## sagemaker.tf - Modelo y Endpoint

**Propósito**: Define el modelo ML y el endpoint que Diners usará para predicciones.

```terraform
# ============================================================
# SageMaker Model
# ============================================================

resource "aws_sagemaker_model" "fraud_detection" {
```
- `resource "aws_sagemaker_model"`: Crea un modelo en SageMaker
- `"fraud_detection"`: Nombre interno de Terraform (no el nombre en AWS)
- El nombre real en AWS será: `fraudes-model-prod`

```terraform
  depends_on = [null_resource.docker_push]
```
- **Dependencia**: No crear el modelo HASTA que se haya subido la imagen Docker
- Evita errores por imagen no disponible

```terraform
  name = local.sagemaker_model_name
```
- Nombre del modelo: `fraudes-model-prod`

```terraform
  execution_role_arn = aws_iam_role.sagemaker_execution.arn
```
- ARN del rol IAM que ejecutará el modelo
- SageMaker usará este rol para acceder a ECR y otros recursos

```terraform
  primary_container {
    image = local.docker_image_uri
```
- **Container principal**: dónde está la imagen Docker
- URI: `761951921633.dkr.ecr.us-east-1.amazonaws.com/fraud-detection-api:latest`

```terraform
    model_data_url = null
```
- **SIN datos de modelo separados**
- El modelo está DENTRO de la imagen Docker (en main.py)
- Si tuvieras un archivo .tar.gz de modelo, irría aquí

```terraform
    environment = {
      SAGEMAKER_PROGRAM = "main.py"
      SAGEMAKER_SUBMIT_DIRECTORY = "/opt/ml/code"
    }
```
- **Variables de ambiente para el container**
- `SAGEMAKER_PROGRAM`: Archivo principal a ejecutar (main.py - FastAPI)
- `SAGEMAKER_SUBMIT_DIRECTORY`: Dónde buscar el código

```terraform
  }

  tags = merge(
    local.common_tags,
    { Name = local.sagemaker_model_name }
  )
}
```
- Aplica etiquetas comunes + nombre específico

```terraform
# ============================================================
# SageMaker Endpoint Configuration
# ============================================================

resource "aws_sagemaker_endpoint_configuration" "fraud_detection" {
  name = local.sagemaker_endpoint_config
```
- **Configuración del endpoint** (paso previo)
- Nombre: `fraudes-config-prod`
- SageMaker requiere: Modelo → Config → Endpoint

```terraform
  production_variants {
    model_name = aws_sagemaker_model.fraud_detection.name
```
- Qué modelo usar (fraudes-model-prod)

```terraform
    variant_name = "Primary"
```
- Nombre de esta variante (para A/B testing)
- Ahora solo hay una ("Primary")

```terraform
    initial_instance_count = var.sagemaker_initial_instance_count
    instance_type = var.sagemaker_instance_type
```
- Cuántas máquinas: 1
- Tipo de máquina: ml.m5.large

```terraform
    initial_variant_weight = 1.0
```
- Peso del tráfico: 1.0 = 100%
- Si tuvieras 2 variantes: 0.5 y 0.5

```terraform
  }
}

# ============================================================
# SageMaker Endpoint
# ============================================================

resource "aws_sagemaker_endpoint" "fraud_detection" {
  name = local.sagemaker_endpoint_name
```
- **EL ENDPOINT FINAL**
- Nombre: `Fraudes-Diners-Prod-Endpoint`
- **Esto es lo que invoca la API**

```terraform
  endpoint_config_name = aws_sagemaker_endpoint_configuration.fraud_detection.name
```
- Usa la configuración creada arriba

```terraform
  tags = merge(
    local.common_tags,
    { Name = local.sagemaker_endpoint_name }
  )

  lifecycle {
    create_before_destroy = true
  }
```
- `lifecycle {}`: Cómo destruir y recrear
- `create_before_destroy = true`: Crea el nuevo ANTES de eliminar el viejo
- **Evita downtime** cuando cambias configuración

---

## api_gateway.tf - API REST Integration

**Propósito**: Define la API que Diners usará para hacer predicciones.

```terraform
# ============================================================
# API Gateway REST API
# ============================================================
resource "aws_api_gateway_rest_api" "fraud_detection" {
  name = local.api_gateway_name
```
- **API Gateway principal**
- Nombre: `fraudes-API-prod`
- Esta es la "puerta de entrada" HTTP

```terraform
  binary_media_types = ["application/json", "application/vnd.amazon.eventstream"]
```
- Tipos MIME que puede manejar
- `application/json`: Para datos JSON normales

```terraform
  tags = local.common_tags
}

# ============================================================
# Recursos y Métodos
# ============================================================
resource "aws_api_gateway_resource" "fraude" {
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id
  parent_id = aws_api_gateway_rest_api.fraud_detection.root_resource_id
  path_part = "fraude"
}
```
- **Recurso**: `/fraude` (el endpoint)
- `parent_id = root_resource_id`: Se cuelga de la raíz `/`
- `path_part = "fraude"`: El segmento del path
- **Resultado URL**: `.../fraude`

```terraform
resource "aws_api_gateway_method" "fraude_post" {
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id
  resource_id = aws_api_gateway_resource.fraude.id
  http_method = "POST"
```
- **Método HTTP**: POST en el recurso `/fraude`
- Usuarios hacen: `POST /fraude`

```terraform
  authorization = "NONE"
  api_key_required = false
}
```
- **SIN autenticación** (abierto)
- En producción podrías agregar API keys o autenticación

```terraform
# ============================================================
# Integración con SageMaker
# ============================================================
resource "aws_api_gateway_integration" "fraude_sagemaker" {
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id
  resource_id = aws_api_gateway_resource.fraude.id
  http_method = aws_api_gateway_method.fraude_post.http_method
```
- **Integración**: Conecta el método POST al backend
- Qué sucede cuando alguien hace POST /fraude

```terraform
  type = "AWS"
  integration_http_method = "POST"
```
- `type = "AWS"`: Integración nativa con servicio AWS
- Envía request como HTTP POST

```terraform
  uri = "arn:aws:apigateway:${var.aws_region}:runtime.sagemaker:path/endpoints/${aws_sagemaker_endpoint.fraud_detection.name}/invocations"
```
- **URI del endpoint SageMaker**
- `arn:aws:apigateway:`: Formato ARN de API Gateway
- `runtime.sagemaker`: Servicio SageMaker
- `path/endpoints/`: Ruta de endpoints
- `${aws_sagemaker_endpoint.fraud_detection.name}`: **DINÁMICO** - Nombre real del endpoint
- `/invocations`: Invoca el modelo
- **Ejemplo completo**: `arn:aws:apigateway:us-east-1:runtime.sagemaker:path/endpoints/Fraudes-Diners-Prod-Endpoint/invocations`

```terraform
  credentials = aws_iam_role.apigateway_sagemaker.arn
```
- **Credenciales**: Qué rol IAM usar para esta invocación
- API Gateway asume este rol para invocar SageMaker

```terraform
}

# ============================================================
# Respuestas de Integración
# ============================================================
resource "aws_api_gateway_integration_response" "fraude_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id
  resource_id = aws_api_gateway_resource.fraude.id
  http_method = aws_api_gateway_method.fraude_post.http_method
  status_code = "200"
```
- **Respuesta exitosa**: status 200 OK
- Si SageMaker devuelve datos, envía 200 al cliente

```terraform
  depends_on = [aws_api_gateway_integration.fraude_sagemaker]
}

resource "aws_api_gateway_method_response" "fraude_200" {
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id
  resource_id = aws_api_gateway_resource.fraude.id
  http_method = aws_api_gateway_method.fraude_post.http_method
  status_code = "200"
  response_models = { "application/json" = "Empty" }
}
```
- **Modelo de respuesta**: JSON vacío
- Define qué estructura devuelve la respuesta

```terraform
# ============================================================
# Despliegue y Stage
# ============================================================
resource "aws_api_gateway_deployment" "fraud_detection" {
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id
```
- **Despliegue**: Empaqueta toda la API para publicar

```terraform
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.fraude.id,
      aws_api_gateway_method.fraude_post.id,
      aws_api_gateway_integration.fraude_sagemaker.id,
      aws_api_gateway_integration_response.fraude_integration_response.id,
      aws_iam_role_policy.apigateway_invoke_endpoint.policy
    ]))
  }
```
- **Triggers**: Cuándo redeplegar
- Si cambias cualquiera de estos recursos, redeploya automáticamente
- `sha1()`: Hash para detectar cambios

```terraform
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.fraud_detection.id
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id
  stage_name = var.api_gateway_stage
}
```
- **Stage**: "Ambiente" de la API
- `stage_name = "prod"`: Etapa "prod"
- **Resultado URL**: `.../prod/fraude`

---

## iam.tf - Roles y Permisos

**Propósito**: Define quién puede hacer qué (seguridad de least privilege).

```terraform
# ============================================================
# IAM Role: SageMaker Execution
# ============================================================

resource "aws_iam_role" "sagemaker_execution" {
  name = local.iam_role_sagemaker_name
```
- **Rol para SageMaker**: `sagemaker-execution-fraudes-prod`
- SageMaker asume este rol cuando ejecuta el modelo

```terraform
  assume_role_policy = data.aws_iam_policy_document.sagemaker_trust.json
  tags = local.common_tags
}

data "aws_iam_policy_document" "sagemaker_trust" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
```
- **Trust Policy**: QUIÉN puede usar este rol
- `principals.type = "Service"`: Un servicio AWS (no un usuario)
- `identifiers = ["sagemaker.amazonaws.com"]`: Específicamente SageMaker
- **Resultado**: Solo SageMaker puede asumir (usar) este rol

```terraform
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role = aws_iam_role.sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}
```
- **Política adjunta**: Permisos SageMaker completos
- `AmazonSageMakerFullAccess`: Política administrada por AWS (completa)

```terraform
resource "aws_iam_role_policy" "sagemaker_ecr" {
  name = "${local.iam_role_sagemaker_name}-ecr"
  role = aws_iam_role.sagemaker_execution.id
  policy = data.aws_iam_policy_document.sagemaker_ecr.json
}

data "aws_iam_policy_document" "sagemaker_ecr" {
  statement {
    sid = "ECRAccess"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories"
    ]
    resources = [aws_ecr_repository.fraud_detection.arn]
  }
```
- **Política personalizada**: Acceso a ECR
- Permisos:
  - `ecr:GetDownloadUrlForLayer`: Descargar capas de imagen
  - `ecr:BatchGetImage`: Obtener imágenes completas
  - `ecr:DescribeImages`: Ver información de imágenes
  - `ecr:DescribeRepositories`: Ver repositorios
- `resources = [aws_ecr_repository.fraud_detection.arn]`: **SOLO** este repositorio

```terraform
  statement {
    sid = "ECRAuthToken"
    effect = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}
```
- **Token de autenticación**: Necesario para acceder a ECR
- `resources = ["*"]`: Permitido en todos lados

```terraform
# ============================================================
# IAM Role: API Gateway -> SageMaker
# ============================================================

resource "aws_iam_role" "apigateway_sagemaker" {
  name = local.iam_role_apigateway_name
```
- **Rol para API Gateway**: `apigateway-sagemaker-fraudes-prod`
- API Gateway asume este rol para invocar SageMaker

```terraform
  assume_role_policy = data.aws_iam_policy_document.apigateway_trust.json
  tags = local.common_tags
}

data "aws_iam_policy_document" "apigateway_trust" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
```
- **Trust Policy**: Solo API Gateway (`apigateway.amazonaws.com`) puede usar este rol

```terraform
resource "aws_iam_role_policy" "apigateway_invoke_endpoint" {
  name = "${local.iam_role_apigateway_name}-invoke"
  role = aws_iam_role.apigateway_sagemaker.id
  policy = data.aws_iam_policy_document.apigateway_invoke.json
}

data "aws_iam_policy_document" "apigateway_invoke" {
  statement {
    sid = "InvokeSageMakerEndpoint"
    effect = "Allow"
    actions = ["sagemaker:InvokeEndpoint"]
    resources = [aws_sagemaker_endpoint.fraud_detection.arn]
  }
```
- **Permisos**: API Gateway puede invocar SageMaker endpoint
- `sagemaker:InvokeEndpoint`: La ÚNICA acción permitida
- `resources = [aws_sagemaker_endpoint.fraud_detection.arn]`: **SOLO** este endpoint específico
- **Seguridad**: Least privilege - solo lo necesario

```terraform
  statement {
    sid = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}
```
- **Logging**: Crear y escribir logs
- API Gateway registra todo para debugging

---

## ecr.tf - Registro Docker

**Propósito**: Crear y mantener el repositorio Docker en AWS.

```terraform
# ============================================================
# ECR Repository
# ============================================================

resource "aws_ecr_repository" "fraud_detection" {
  name = var.docker_image_name
```
- **Repositorio Docker**: `fraud-detection-api`
- Almacena imágenes Docker en AWS

```terraform
  image_tag_mutability = var.ecr_image_tag_mutability
```
- `MUTABLE` (por defecto): Puedes sobrescribir tags
- Ejemplo: `latest` siempre apunta a la versión más reciente

```terraform
  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }
```
- **Escaneo automático**: Busca vulnerabilidades al subir
- Ayuda a mantener seguridad

```terraform
  encryption_configuration {
    encryption_type = "AES256"
  }
```
- **Encriptación**: Imágenes encriptadas en reposo
- AES256: Estándar de encriptación fuerte

```terraform
  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "fraud_detection" {
  repository = aws_ecr_repository.fraud_detection.name
```
- **Política de ciclo de vida**: Gestiona imágenes antiguas

```terraform
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description = "Mantener últimas 5 imágenes"
        selection = {
          tagStatus = "any"
          countType = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
```
- **Regla**: Mantener solo las últimas 5 imágenes
- Si subes más de 5, las antiguas se eliminan automáticamente
- Ahorra costos de almacenamiento

```terraform
# ============================================================
# Data Source: Get AWS Account ID
# ============================================================

data "aws_caller_identity" "current" {}
```
- **Data source**: Obtiene información de tu cuenta AWS
- Necesario para construir URLs de ECR

```terraform
# ============================================================
# Docker Build & Push
# ============================================================

resource "null_resource" "docker_build" {
  count = var.docker_local_build ? 1 : 0
```
- **Construcción local**: Si `docker_local_build = true`, ejecuta `docker build`
- `count = var.docker_local_build ? 1 : 0`: "Si es true, crea 1 recurso; si no, crea 0"

```terraform
  triggers = {
    dockerfile_hash = filemd5("${var.docker_build_context}/Dockerfile")
    requirements_hash = try(
      filemd5("${var.docker_build_context}/endpoint_prototipo/requirements.txt"),
      "none"
    )
  }
```
- **Triggers**: Cuándo reconstruir
- Si cambia Dockerfile o requirements.txt, reconstruye automáticamente
- `filemd5()`: Hash del archivo para detectar cambios

```terraform
  provisioner "local-exec" {
    command = <<-EOT
      echo "[BUILD] Construyendo imagen Docker: ${var.docker_image_name}:${var.docker_image_tag}"
      docker build \
        -t ${var.docker_image_name}:${var.docker_image_tag} \
        -f ${var.docker_build_context}/Dockerfile \
        ${var.docker_build_context}
      echo "[OK] Imagen construida exitosamente"
    EOT
  }
}

resource "null_resource" "docker_push" {
  count = var.enable_docker_push ? 1 : 0

  depends_on = [
    aws_ecr_repository.fraud_detection,
    null_resource.docker_build
  ]
```
- **Push a ECR**: Si `enable_docker_push = true`, sube la imagen
- Depende de que ya exista el repositorio y la imagen construida

---

## terraform.tfvars - Valores Actuales

**Propósito**: Proporciona valores reales para las variables.

```terraform
aws_account_id = "761951921633"
aws_region     = "us-east-1"
```
- Tu cuenta AWS real
- Región donde despliega

```terraform
project_name = "fraudes"
environment  = "prod"
```
- Proyecto: "fraudes"
- Ambiente: "prod"
- Resultarán en: `Fraudes-...-Prod-Endpoint`

```terraform
endpoint_name_suffix = "Diners"
api_gateway_name_suffix = "API"
```
- Sufijos personalizados
- Endpoint: `Fraudes-Diners-Prod-Endpoint`
- API: `fraudes-API-prod`

```terraform
docker_image_name = "fraud-detection-api"
docker_image_tag = "latest"
```
- Imagen Docker a construir/subir

```terraform
sagemaker_instance_type = "ml.m5.large"
sagemaker_initial_instance_count = 1
```
- Máquina para las predicciones
- Una sola instancia

---

## outputs.tf - Valores de Salida

**Propósito**: Muestra información importante después del despliegue.

```terraform
output "sagemaker_endpoint_name" {
  value = aws_sagemaker_endpoint.fraud_detection.name
}
```
- **Output**: Imprime el nombre del endpoint
- Resultado: `Fraudes-Diners-Prod-Endpoint`

```terraform
output "api_invoke_url" {
  value = "${aws_api_gateway_deployment.fraud_detection.invoke_url}${aws_api_gateway_resource.fraude.path_part}"
}
```
- **URL para invocar API**
- Ejemplo: `https://xxxxx.execute-api.us-east-1.amazonaws.com/prod/fraude`

```terraform
output "sagemaker_endpoint_arn" {
  value = aws_sagemaker_endpoint.fraud_detection.arn
}
```
- ARN (Amazon Resource Name) del endpoint
- Identificador único

---

## backend.tf - Almacenamiento de Estado

**Propósito**: Define dónde guarda Terraform el estado de los recursos.

```terraform
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```
- **Local**: Guarda en tu computadora (no en AWS)
- `terraform.tfstate`: Archivo que registra qué recursos existen
- En producción, usarías S3 o Terraform Cloud

---

## 🎯 Resumen: Cómo Funciona Todo Junto

```
terraform.tfvars (TUS VALORES)
         ↓
    provider.tf (CONFIGURA PROVEEDORES)
         ↓
    variables.tf (DEFINE TIPOS)
         ↓
    locals.tf (CALCULA NOMBRES DINÁMICOS)
         ↓
    ├─→ sagemaker.tf (CREA MODELO + ENDPOINT)
    ├─→ api_gateway.tf (CREA API + INTEGRACIÓN)
    ├─→ iam.tf (CREA ROLES + PERMISOS)
    └─→ ecr.tf (CREA REPOSITORIO DOCKER)
         ↓
    outputs.tf (IMPRIME INFORMACIÓN)
         ↓
    backend.tf (GUARDA ESTADO)
```

**Flujo de una solicitud**:
```
Cliente
  ↓ POST JSON
API Gateway (fraudes-API-prod)
  ↓ Asume IAM role
SageMaker Runtime
  ↓ Invoca endpoint
SageMaker Endpoint (Fraudes-Diners-Prod-Endpoint)
  ↓ Ejecuta modelo
Docker Container (fraud-detection-api:latest)
  ↓ main.py (FastAPI)
Predicción
  ↓ JSON response
Cliente
```

---

**¡Ahora entiendes línea por línea cómo funciona la infraestructura!** 🚀
