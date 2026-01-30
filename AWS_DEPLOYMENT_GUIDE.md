# 🚀 Guía Completa: Desplegar FastAPI en AWS ECS Fargate + API Gateway

**Documento de referencia para migrar de ngrok a producción profesional**

---

## 📋 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Los 4 Componentes](#los-4-componentes)
3. [Arquitectura](#arquitectura)
4. [Instalación Paso a Paso](#instalación-paso-a-paso)
5. [Costos Estimados](#costos-estimados)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Visión General

Estás migrando desde **ngrok** (túnel local temporal) a **AWS ECS Fargate + API Gateway** (producción profesional).

### ¿Por qué esta arquitectura?

| Aspecto | ngrok | ECS Fargate + API Gateway |
|--------|-------|--------------------------|
| **Escalabilidad** | Manual, limitada | Automática, ilimitada |
| **Disponibilidad** | ~99% | 99.99% SLA |
| **Seguridad** | Básica | Enterprise-grade |
| **Costo** | $5-15/mes | ~$30-100/mes (escalable) |
| **Control** | Cero | Total |
| **Profesionalismo** | Prototipo | Producción |

---

## 🔧 Los 4 Componentes

### **1. DOCKERFILE** ✨

**¿Qué es?**
- Receta que "empaqueta" tu aplicación FastAPI en una caja (contenedor)
- Define qué SO usar, qué dependencias instalar, cómo correr la app

**¿Para qué sirve?**
- Garantiza que tu app corra igual en cualquier lugar (tu PC, AWS, otro servidor)
- Elimina el "en mi máquina funciona pero en producción no"
- Versiona exactamente qué versión de Python, Torch, FastAPI usas

**Ventajas:**
✅ Reproducibilidad (funciona igual en todos lados)
✅ Fácil de testear localmente
✅ Mejor gestión de dependencias
✅ Isolamento de recursos

**Desventajas:**
❌ Requiere ~4GB para imagen (Torch es pesado)
❌ Curva de aprendizaje inicial
❌ Necesita mantenimiento (actualizar dependencias)

**Ubicación:** `Dockerfile` (raíz del proyecto)

---

### **2. TERRAFORM/CLOUDFORMATION** 🏗️

**¿Qué es?**
- "Código" que describe toda tu infraestructura AWS (VPC, ECS, Load Balancer, etc.)
- Infraestructura como Código (IaC)

**¿Para qué sirve?**
- Define: clústeres, contenedores, networking, seguridad, bases de datos
- Repite la infraestructura idéntica (dev, staging, producción)
- Versiona cambios de infraestructura como código
- Destruye/recrea todo con un comando

**Ventajas:**
✅ Repetibilidad (2 clics, infraestructura idéntica)
✅ Control de versiones (git para infraestructura)
✅ Fácil de escalar (3 líneas para duplicar recursos)
✅ Documentación viva (el código es la documentación)
✅ Rollback fácil

**Desventajas:**
❌ Sintaxis nueva (HCL para Terraform)
❌ Debugging complejo si algo falla
❌ Requiere permisos AWS avanzados
❌ Costo de experimenting (AWS cobra por recursos creados)

**Ubicación:** `terraform/` o `cloudformation/`

**Comparativa:**
- **Terraform**: Agnóstico (funciona AWS, Azure, GCP), más popular en DevOps
- **CloudFormation**: Nativo AWS, mejor integración con servicios AWS
- Aquí usaremos **Terraform** (más flexible)

---

### **3. GITHUB ACTIONS** 🤖

**¿Qué es?**
- Automatización que corre en GitHub cada vez que "pusheas" código
- Acciones: build, test, push a Docker Hub, deploy a ECS

**¿Para qué sirve?**
- CI/CD Pipeline automatizado:
  - **CI (Continuous Integration)**: Testa tu código
  - **CD (Continuous Deployment)**: Deploya automáticamente a AWS
- Cada push a `main` = deployment automático
- Elimina pasos manuales

**Ventajas:**
✅ Deployment 1-click (solo push a git)
✅ Pruebas automáticas antes de deploy
✅ Rollback fácil (revert commit)
✅ Historial de deployments (git log)
✅ Equipo sincronizado (todos ven cambios)

**Desventajas:**
❌ Configuración YAML puede ser tediosa
❌ Debugging difícil (errores en la nube)
❌ Secretos sensibles (API keys) a gestionar
❌ Requiere Docker Hub account

**Ubicación:** `.github/workflows/deploy.yml`

**Flujo:**
```
1. Pusheas código a GitHub (git push)
   ↓
2. GitHub Actions detecta cambio
   ↓
3. Ejecuta tests
   ↓
4. Si OK → Build Docker image
   ↓
5. Push a Docker Hub
   ↓
6. Actualiza ECS (AWS) con nueva imagen
   ↓
7. ~2-3 minutos: Tu API en producción ✨
```

---

### **4. DOCUMENTACIÓN (este archivo)** 📖

**¿Qué es?**
- Guía paso-a-paso para entender y ejecutar todo
- Explicación de cada componente
- Troubleshooting

**¿Para qué sirve?**
- Onboarding del equipo
- Referencia cuando algo falla
- Decisiones arquitectónicas documentadas

**Ventajas:**
✅ Facilita onboarding
✅ Referencia cuando necesitas
✅ Decisiones claras

**Desventajas:**
❌ Requiere mantenimiento (cambios = actualizar docs)
❌ Puede quedar desactualizada

---

## 🏛️ Arquitectura Final

```
┌─────────────────────────────────────────────────────────┐
│                     INTERNET (Cliente)                   │
└─────────────────────────────────────────────────────────┘
                              ↓
         ┌────────────────────────────────────────┐
         │    API GATEWAY (AWS)                    │
         │  - Punto de entrada único               │
         │  - Throttling/Rate limiting             │
         │  - Autenticación (API keys)             │
         │  - Logs centralizados                   │
         └────────────────────────────────────────┘
                              ↓
         ┌────────────────────────────────────────┐
         │    LOAD BALANCER (AWS ALB)              │
         │  - Distribuye tráfico                   │
         │  - Health checks                        │
         │  - SSL/TLS termination                  │
         └────────────────────────────────────────┘
                              ↓
         ┌────────────────────────────────────────┐
         │    ECS FARGATE CLUSTER                  │
         │  ┌──────────┐  ┌──────────┐             │
         │  │ Container│  │ Container│  ...       │
         │  │ FastAPI  │  │ FastAPI  │             │
         │  │ Replica1 │  │ Replica2 │             │
         │  └──────────┘  └──────────┘             │
         │                                         │
         │  (Auto-scaling: 1-5 contenedores)       │
         └────────────────────────────────────────┘
                              ↓
         ┌────────────────────────────────────────┐
         │    CloudWatch (Monitoreo)               │
         │  - Logs en tiempo real                  │
         │  - Métricas (CPU, memoria)              │
         │  - Alertas si algo falla                │
         └────────────────────────────────────────┘
```

---

## 📦 Instalación Paso a Paso

### **FASE 0: Prerequisitos**

```bash
# 1. AWS Account (con créditos)
# 2. AWS CLI configurado
aws configure
# Ingresa: Access Key, Secret Key, región (us-east-1)

# 3. Git + GitHub
git clone <tu-repo>

# 4. Docker Desktop instalado
docker --version

# 5. Terraform instalado
terraform --version

# 6. Docker Hub account
# - Ve a https://hub.docker.com
# - Crea cuenta gratis
```

---

### **FASE 1: Containerizar (Dockerfile)**

**Paso 1.1:** Crear `Dockerfile` en raíz del proyecto

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema (Torch necesita esto)
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY endpoint_prototipo/requirements.txt .

# Instalar Python deps
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código
COPY . .

# Exponer puerto
EXPOSE 8000

# Correr app
CMD ["python", "-m", "uvicorn", "endpoint_prototipo.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Paso 1.2:** Testear localmente

```bash
# Build
docker build -t fraud-api:latest .

# Run
docker run -p 8000:8000 fraud-api:latest

# Test
curl http://localhost:8000/docs  # Accede a Swagger UI
```

**Paso 1.3:** Push a Docker Hub

```bash
# Login
docker login

# Tag
docker tag fraud-api:latest <tu-dockerhub-user>/fraud-api:latest

# Push
docker push <tu-dockerhub-user>/fraud-api:latest
```

---

### **FASE 2: Infraestructura (Terraform)**

**Paso 2.1:** Crear estructura

```bash
mkdir -p terraform
cd terraform

# Archivos que necesitas:
# - main.tf       (ECS, ALB, networking)
# - variables.tf  (variables)
# - outputs.tf    (qué imprime al final)
# - terraform.tfvars (valores específicos)
```

**Paso 2.2:** Deploy infraestructura

```bash
cd terraform

# Inicializar
terraform init

# Ver qué va a crear
terraform plan

# Aplicar (tarda ~5 min)
terraform apply
  # Confirma con "yes"

# Guarda outputs (URLs importantes)
terraform output
```

**Paso 2.3:** Resultado

```
Outputs:
api_gateway_endpoint = "https://xxx.execute-api.us-east-1.amazonaws.com/prod"
load_balancer_dns = "fraud-api-lb-xxx.us-east-1.elb.amazonaws.com"
```

---

### **FASE 3: CI/CD (GitHub Actions)**

**Paso 3.1:** Crear workflow

```bash
mkdir -p .github/workflows
# Archivo: .github/workflows/deploy.yml
# (contenido en archivo separado)
```

**Paso 3.2:** Configurar secretos en GitHub

```
GitHub Repo → Settings → Secrets and variables → Actions
Agregar:
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  - DOCKERHUB_USERNAME
  - DOCKERHUB_PASSWORD
  - AWS_ACCOUNT_ID
  - AWS_REGION
```

**Paso 3.3:** Test deployment

```bash
# Simplemente haz:
git add .
git commit -m "Deploy: Initial production setup"
git push origin main

# Ve a GitHub → Actions
# Verás tu workflow corriendo
# ~3 minutos después: API en producción ✨
```

---

### **FASE 4: Validación**

```bash
# Obtén URLs de Terraform outputs
API_URL="https://xxx.execute-api.us-east-1.amazonaws.com/prod"

# Test health
curl ${API_URL}/health

# Test fraud prediction
curl -X POST ${API_URL}/fraud/predict \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX123",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
  }'

# Ver logs en AWS CloudWatch
aws logs tail /ecs/fraud-api --follow
```

---

## 💰 Costos Estimados

### Desglose mensual (aprox.):

| Servicio | Uso | Costo |
|----------|-----|-------|
| **ECS Fargate** | 2 vCPU, 4GB RAM, 24h | $25-35 |
| **API Gateway** | ~100k requests | $3-10 |
| **Load Balancer** | 1 ALB | $16 |
| **Data Transfer** | 1GB salida | $0.10 |
| **CloudWatch** | Logs | $5-10 |
| **Docker Hub** | Privado (opcional) | $0-7 |
| **TOTAL** | | **$50-80/mes** |

**Optimización:**
- Usa auto-scaling: 1 contenedor en off-peak, 3 en peak
- Reduce a $30-50/mes
- Más barato que servidor dedicado ($100+)

---

## 🐛 Troubleshooting

### **Problema: "Container exits immediately"**

```bash
# Ver logs
aws logs tail /ecs/fraud-api --follow

# Problema común: Torch no instala correctamente
# Solución: Usa imagen base con CUDA pre-instalado
FROM pytorch/pytorch:2.1.0-runtime-ubuntu22.04
```

### **Problema: "Slow response time"**

```bash
# Culpable: modelo Torch carga lentamente
# Soluciones:
# 1. Cache el modelo en memoria (ya haces esto)
# 2. Aumenta memoria ECS: 8GB RAM
# 3. Usa GPU (ECS GPU Compute Optimized)
```

### **Problema: "Deployments fallan en GitHub Actions"**

```bash
# Revisa logs:
GitHub → Actions → Tu workflow → Logs

# Causa común: ECR repository no existe
# Solución: Terraform crea automáticamente, pero verifica:
aws ecr describe-repositories
```

### **Problema: "API muy lenta después de varios requests"**

```
Causa: Memory leak en modelo Torch
Solución: 
- Restartea contenedores cada 6h (ECS tarea)
- O implementa connection pooling
```

### **Problema: "¿Cómo escalo a más tráfico?"**

```bash
# En Terraform, cambia:
desired_count = 5  # En lugar de 2

# Luego:
terraform apply

# Automático: ECS crea 3 contenedores más
```

---

## 🔐 Seguridad Recomendada

```hcl
# En variables.tf:
variable "allowed_ips" {
  description = "IPs permitidas (solo Diners)"
  default     = ["1.2.3.4/32"]  # IP Diners
}

# En security_group.tf:
# - Solo puerto 443 (HTTPS) abierto
# - Solo API Gateway puede llamar ECS
# - No expongas puerto 8000 directamente
```

---

## 📞 Siguientes Pasos

1. **Ahora:** Ejecuta FASE 0 (Prerequisitos)
2. **Mañana:** Ejecuta FASE 1 (Dockerfile local)
3. **Día 3:** Ejecuta FASE 2 (Terraform + AWS)
4. **Día 4:** Ejecuta FASE 3 (GitHub Actions)
5. **Día 5:** Migra usuarios de ngrok a nueva URL

---

## 📚 Recursos Adicionales

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Preguntas?** Revisa el archivo de troubleshooting o pregunta al equipo DevOps.

**Última actualización:** 2026-01-30
