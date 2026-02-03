# Pipeline MLOps Completo Automatizado

## 🎯 Visión General

Este sistema automatiza todo el proceso de MLOps en UNA línea de comandos:

```bash
python deploy-completo.py --stack-name fraudes-api
```

Y hace esto:

```
┌─────────────────┐
│  Dockerfile     │
│  + Código       │
└────────┬────────┘
         │
         ↓ (Paso 1)
    ┌─────────────────┐
    │  Docker Build   │
    │  Imagen local   │
    └────────┬────────┘
             │
             ↓ (Paso 2)
        ┌─────────────────┐
        │  ECR Repository │
        │  (crear si no   │
        │   existe)       │
        └────────┬────────┘
                 │
                 ↓ (Paso 3)
            ┌─────────────────┐
            │  Docker Push    │
            │  a ECR          │
            └────────┬────────┘
                     │
                     ↓ (Paso 4)
                ┌─────────────────┐
                │  IAM Role       │
                │  SageMaker      │
                └────────┬────────┘
                         │
                         ↓ (Paso 5)
                    ┌─────────────────────────────┐
                    │  CloudFormation Deploy      │
                    │  - SageMaker Model          │
                    │  - SageMaker Endpoint       │
                    │  - API Gateway + IAM        │
                    └─────────────────────────────┘
                             │
                             ↓
                    ┌─────────────────────────────┐
                    │  ✅ SISTEMA LISTO           │
                    │  Requests → API → Endpoint  │
                    └─────────────────────────────┘
```

---

## 📋 Pasos Detallados

### **PASO 1: Docker Build**
```
Qué hace: Lee Dockerfile, construye imagen local
Comando equivalente: docker build -t fraudes-diners-v5:latest .
Resultado: Imagen lista para pushear
Duración: ~5 minutos
```

### **PASO 2: ECR Setup**
```
Qué hace: Verifica/crea repositorio ECR
Comando equivalente: aws ecr create-repository --repository-name fraudes-diners-v5
Resultado: Repositorio ECR listo
Duración: ~10 segundos
```

### **PASO 3: Docker Push**
```
Qué hace: Pushea imagen a ECR
Comando equivalente: docker push [ECR_URI]/fraudes-diners-v5:latest
Resultado: Imagen en la nube
Duración: ~2-5 minutos (depende del tamaño)
```

### **PASO 4: IAM Setup**
```
Qué hace: Crea rol IAM para SageMaker
Comando equivalente: aws iam create-role --role-name sagemaker-execution-...
Adjunta: AmazonSageMakerFullAccess + ECR ReadOnly
Resultado: Rol listo con permisos
Duración: ~5 segundos
```

### **PASO 5: CloudFormation Deploy**
```
Qué hace: Lee infra-sagemaker-complete.yaml y crea:
  1. SageMaker Model
  2. SageMaker EndpointConfig
  3. SageMaker Endpoint
  4. IAM Role (API Gateway)
  5. IAM Policy (permisos)
  6. API Gateway REST API
  7. API Gateway Resource (/fraude)
  8. API Gateway Method (POST)
  9. API Gateway Deployment (prod)

Resultado: Sistema completo
Duración: ~15-20 minutos (esperar a que endpoint esté InService)
```

---

## 🚀 Uso

### **Despliegue Básico**
```bash
python deploy-completo.py --stack-name fraudes-api
```

### **Con Tag Personalizado**
```bash
python deploy-completo.py --stack-name fraudes-api --image-tag v2.0
```

### **Omitir Docker Build (usar imagen existente)**
```bash
python deploy-completo.py --stack-name fraudes-api --skip-docker
```

### **Especificar Región**
```bash
python deploy-completo.py --stack-name fraudes-api --region us-west-2
```

---

## 📊 Salida Esperada

```
[*] Cuenta actual: 761951921633
[*] Region: us-east-1
[*] Stack: fraudes-api

[PASO 1] Docker Build - Construir imagen local
========================================
[BUILDANDO] fraudes-diners-v5:latest...
[OK] Imagen construida: fraudes-diners-v5:latest

[PASO 2] ECR Setup - Crear/verificar repositorio
========================================
[OK] Repositorio ya existe: fraudes-diners-v5

[PASO 3] Docker Push - Subir imagen a ECR
========================================
[AUTH] Obteniendo credenciales ECR...
[LOGIN] Docker login a...
[OK] Login exitoso
[PUSH] Pusheando a ECR...
[OK] Imagen subida: 761951921633.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners-v5:latest

[PASO 4] IAM Setup - Crear rol para SageMaker
========================================
[CREANDO] Rol: sagemaker-execution-fraudes-api...
[ADJUNTANDO] Política AmazonSageMakerFullAccess...
[ADJUNTANDO] Política ECR...
[OK] Rol creado: sagemaker-execution-fraudes-api
     ARN: arn:aws:iam::761951921633:role/sagemaker-execution-fraudes-api

[PASO 5] CloudFormation Deploy - Crear infraestructura
========================================
[VALIDANDO] Template CloudFormation...
[OK] Template válido
[CREATE] Creando nuevo stack...
[ESPERANDO] Deployment CREATE...
  [0s] Status: CREATE_IN_PROGRESS
  [20s] Status: CREATE_IN_PROGRESS
  [40s] Status: CREATE_IN_PROGRESS
...
[OK] Stack CREATE completado exitosamente

[OUTPUTS] Extrayendo configuración...

[RESULTADOS]
  EndpointName: endpoint-fraudes-api
  ModelName: fraudes-model-fraudes-api
  ApiInvokeUrl: https://xyz123.execute-api.us-east-1.amazonaws.com/prod/fraude
  ApiId: xyz123
  APIGatewayRoleArn: arn:aws:iam::761951921633:role/apigateway-sagemaker-fraudes-api

======================================================================
✅ PIPELINE COMPLETADO EXITOSAMENTE
======================================================================
```

---

## 📂 Archivos Generados

```
deployment-config.json     ← Configuración completa (JSON)
api-invoke-url.txt        ← URL de la API
endpoint-name.txt         ← Nombre del endpoint
```

---

## 🔄 Flujo de Request Completo

Cuando un cliente hace una request:

```
1. Cliente llama:
   POST https://xyz123.execute-api.us-east-1.amazonaws.com/prod/fraude
   Body: {"transaction_id": "...", "monto": 150.5, ...}

2. API Gateway recibe:
   - Valida método POST
   - Valida ruta /fraude
   - Sin autenticación requerida ✓

3. API Gateway asume rol IAM:
   - Rol: apigateway-sagemaker-fraudes-api
   - Permiso: sagemaker:InvokeEndpoint

4. API Gateway invoca SageMaker:
   - Endpoint: endpoint-fraudes-api
   - Método: POST (integración AWS nativa)
   - Body: Tu JSON de transacción

5. SageMaker Endpoint recibe:
   - Estado: InService ✓
   - Carga contenedor Docker
   - Ejecuta código en main.py
   - Lógica: Evalúa fraude
   - Retorna: {"score": 301.0, ...}

6. API Gateway retorna:
   - Status: 200 OK
   - Body: JSON con resultado

7. Cliente recibe:
   - {"schema_version": "1.0", "request_id": "REQ-...", "ml_score_0_999": 301.0, ...}
```

---

## 🧪 Testear Después del Deploy

```bash
# La URL se guardó en api-invoke-url.txt
curl -X POST $(cat api-invoke-url.txt) \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX-001",
    "monto": 150.5,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "Restaurant",
    "especialidad": "RESTAURANTES"
  }'

# O con Python
python test_api_gateway.py
```

---

## ❌ Troubleshooting

### Docker Build Falla
```
[ERROR] Docker not installed or not in PATH

Solución: Instalar Docker Desktop
- Windows: https://www.docker.com/products/docker-desktop
- Linux: sudo apt-get install docker.io
```

### ECR Push Falla
```
[ERROR] Docker push falló

Solución: Verificar permisos ECR
- aws iam get-user (verifica usuario)
- Debe tener ecr:GetAuthorizationToken
```

### CloudFormation Falla
```
[ERROR] CloudFormation Status: CREATE_FAILED

Solución: Ver eventos del stack
- aws cloudformation describe-stack-events --stack-name fraudes-api
- Buscar CREATE_FAILED y el ResourceStatusReason
```

### Endpoint No Sale de "Creating"
```
[WARN] Endpoint status: Creating (más de 30 minutos)

Solución: Verificar en SageMaker Console
- aws sagemaker describe-endpoint --endpoint-name endpoint-fraudes-api
- Ver si hay errores en el evento
```

---

## 📚 Archivos Relacionados

- `infra-sagemaker-complete.yaml` - Template CloudFormation COMPLETO
- `Dockerfile` - Definición del contenedor
- `endpoint_prototipo/main.py` - Código que ejecuta el endpoint
- `deploy-completo.py` - ESTE script orquestador

---

## ✅ Checklist Post-Deploy

- [ ] Archivo `deployment-config.json` creado
- [ ] Archivo `api-invoke-url.txt` tiene URL válida
- [ ] Archivo `endpoint-name.txt` tiene nombre del endpoint
- [ ] `aws sagemaker describe-endpoint --endpoint-name ...` retorna `InService`
- [ ] Test API con curl → Status 200 OK
- [ ] Response JSON tiene `ml_score_0_999` y `request_id`

---

## 🔐 Seguridad

- Rol IAM: Solo apigateway.amazonaws.com puede asumir
- Permisos: Solo sagemaker:InvokeEndpoint en endpoint específico
- API Gateway: Sin autenticación (opcional: agregar API Key)
- Imagen Docker: Almacenada en ECR privado
- Credenciales: Nunca hardcodeadas (usa AWS SDK)

---

**Versión**: 1.0  
**Última Actualización**: 2026-02-02  
**Estado**: ✅ Production Ready
