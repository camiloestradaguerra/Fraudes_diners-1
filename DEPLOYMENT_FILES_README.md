# 📦 AWS Deployment - Archivos Generados

**Resumen de archivos creados para desplegar tu API Fraud Detection a AWS**

---

## 📂 Estructura Creada

```
Proyecto_Fraudes/
├── 📄 Dockerfile                        # Receta Docker (containerizar app)
├── 📄 .dockerignore                     # Archivos a NO incluir en imagen
├── 📄 AWS_DEPLOYMENT_GUIDE.md          # 📖 GUÍA PRINCIPAL - LEE PRIMERO
├── 📄 MANUAL_DEPLOYMENT.md             # Pasos manuales sin CI/CD
├── 📄 QUICKSTART.md                    # 4 pasos rápidos
├── 📄 OPTIONS_COMPARISON.md            # Por qué ECS Fargate es mejor
├── 📂 terraform/                       # 🏗️ Infraestructura AWS
│   ├── main.tf                         # VPC, ECS, ALB, API Gateway
│   ├── variables.tf                    # Variables configurables
│   ├── outputs.tf                      # URLs resultantes
│   └── terraform.tfvars                # Tus valores específicos
├── 📂 .github/workflows/               # 🤖 CI/CD Automation
│   └── deploy.yml                      # GitHub Actions workflow
└── 📂 scripts/                         # 🔧 Scripts auxiliares
    └── install_prerequisites.sh        # Instalar tools necesarios
```

---

## 📖 Guía de Lectura (Orden Recomendado)

1. **COMIENZA AQUÍ** → [AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)
   - Entender conceptos
   - Ver arquitectura completa
   - Saber qué es cada componente

2. **ENTIENDE OPCIONES** → [OPTIONS_COMPARISON.md](OPTIONS_COMPARISON.md)
   - Por qué ECS Fargate vs EC2 vs Lambda
   - Matriz de decisión
   - Casos de uso

3. **QUICK START** → [QUICKSTART.md](QUICKSTART.md)
   - 4 pasos principales
   - Resumen ejecutivo
   - Checklist

4. **DEPLOYMENT MANUAL** → [MANUAL_DEPLOYMENT.md](MANUAL_DEPLOYMENT.md)
   - Paso a paso detallado
   - Sin GitHub Actions
   - Troubleshooting

---

## 🚀 Quick Deployment (3 Comandos)

```bash
# 1. Build Docker image
docker build -t fraud-api:latest .

# 2. Deploy infraestructura
cd terraform && terraform apply

# 3. (Opcional) Deploy automático con GitHub Actions
# - Configura secretos en GitHub
# - git push origin main
# - Automáticamente se deploya en 3 min
```

---

## 📋 Archivos por Componente

### **1️⃣ Docker (Containerización)**
| Archivo | Propósito |
|---------|-----------|
| `Dockerfile` | Receta para construir imagen |
| `.dockerignore` | Archivos a excluir de la imagen |

**Propósito:** Empaquetar tu FastAPI en un contenedor reproducible

---

### **2️⃣ Terraform (Infraestructura)**
| Archivo | Propósito |
|---------|-----------|
| `terraform/main.tf` | Definen ECS, ALB, API Gateway, VPC |
| `terraform/variables.tf` | Variables reutilizables (CPU, memoria, etc.) |
| `terraform/outputs.tf` | URLs importantes después de deployar |
| `terraform/terraform.tfvars` | Tus valores específicos (editar antes de deploy) |

**Propósito:** Infraestructura como código (IaC)

**Comandos:**
```bash
cd terraform
terraform init      # Descargar providers
terraform plan      # Ver qué va a crear
terraform apply     # CREAR infraestructura
terraform destroy   # Destruir (elimina TODO)
```

---

### **3️⃣ GitHub Actions (CI/CD)**
| Archivo | Propósito |
|---------|-----------|
| `.github/workflows/deploy.yml` | Workflow: test, build, push, deploy |

**Propósito:** Automatización: cada `git push` → deployment automático

**Setup:**
```bash
# En GitHub Repo Settings → Secrets:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID
AWS_REGION
DOCKERHUB_USERNAME
DOCKERHUB_PASSWORD
```

---

### **4️⃣ Scripts (Helpers)**
| Archivo | Propósito |
|---------|-----------|
| `scripts/install_prerequisites.sh` | Instala AWS CLI, Docker, Terraform |

**Uso:**
```bash
bash scripts/install_prerequisites.sh
```

---

## 🎯 Flujo Típico

```
┌─ Local ─────────────────────────────────────────────────┐
│                                                         │
│  1. Editar código                                       │
│  2. docker build -t fraud-api:local .                   │
│  3. docker run ... (test)                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─ GitHub ────────────────────────────────────────────────┐
│                                                         │
│  git push origin main                                   │
│                                                         │
│  ↓ (Automáticamente ejecuta .github/workflows/deploy.yml)
│                                                         │
│  1. Tests                                               │
│  2. Build Docker image                                  │
│  3. Push a ECR                                          │
│  4. Deploy a ECS                                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─ AWS Production ────────────────────────────────────────┐
│                                                         │
│  API Gateway → Load Balancer → ECS Fargate             │
│  (Auto-scaling, Logging, Monitoring)                  │
│                                                         │
│  ✅ ~3 minutos: API en producción                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 💰 Costos Estimados

```
┌─────────────────────────────────────────┐
│ Desglose Mensual (aprox.)               │
├─────────────────────────────────────────┤
│ ECS Fargate (2 replicas, 1vCPU, 2GB)   │
│   - 730 horas × $0.032/h = $23         │
│   - 1460 GB/h × $0.0034/h = $5         │
│   Subtotal: $28                         │
│                                         │
│ Application Load Balancer               │
│   - $16.20 por mes                      │
│                                         │
│ API Gateway                             │
│   - 100k requests × $0.0035/request     │
│   - Subtotal: $3.50                     │
│                                         │
│ CloudWatch Logs                         │
│   - ~$5 por mes                         │
│                                         │
│ Data Transfer Out                       │
│   - ~$0.10 por GB                       │
│                                         │
├─────────────────────────────────────────┤
│ TOTAL: ~$85 por mes                     │
│                                         │
│ (Escala automáticamente con tráfico)   │
└─────────────────────────────────────────┘
```

---

## ✅ Pre-Deployment Checklist

- [ ] AWS Account con permisos (IAM user)
- [ ] AWS CLI instalado y configurado (`aws configure`)
- [ ] Docker instalado (`docker --version`)
- [ ] Terraform instalado (`terraform --version`)
- [ ] Git configurado (`git --version`)
- [ ] `terraform/terraform.tfvars` editado con tus valores
- [ ] `Dockerfile` testeado localmente
- [ ] GitHub repo creado (si usas CI/CD)
- [ ] GitHub Secrets configurados (si usas CI/CD)

---

## 🎓 Recursos de Aprendizaje

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## 🆘 Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| Terraform error: "AccessDenied" | `aws sts get-caller-identity` (verifica credentials) |
| Docker build lento | Usa BuildKit: `DOCKER_BUILDKIT=1 docker build ...` |
| ECS tasks no inician | `aws logs tail /ecs/fraud-api --follow` (ver logs) |
| API Gateway 502 | Espera 3-5 min, verifica health checks |
| Costo más alto de lo esperado | Aumenta `log_retention_days` a 7 (reduce costo logs) |

---

## 📞 Preguntas Comunes

**P: ¿Necesito descargar todo esto?**
R: Sí. Copia todos los archivos al root de tu proyecto.

**P: ¿Puedo cambiar regiones AWS?**
R: Sí. En `terraform.tfvars`: `aws_region = "eu-west-1"`

**P: ¿Cómo agregó dominio personalizado?**
R: AWS Route53 + CloudFront (documentado en AWS_DEPLOYMENT_GUIDE.md)

**P: ¿Puedo deployar desde local sin GitHub?**
R: Sí. Sigue `MANUAL_DEPLOYMENT.md`

**P: ¿Cómo rollback si algo falla?**
R: `git revert <commit-hash>` + `git push` (redeploya anterior versión)

---

## 📌 Importante

**NO comitees estos archivos sin editar:**
- `terraform/terraform.tfvars` - Agrega valores específicos
- `.github/workflows/deploy.yml` - Agrega tu AWS Account ID

**Mantén seguro:**
- AWS credentials (nunca en git)
- API keys (usar GitHub Secrets)

---

## 🚀 Siguientes Pasos

1. Copia archivos a tu proyecto
2. Lee `AWS_DEPLOYMENT_GUIDE.md`
3. Edita `terraform/terraform.tfvars`
4. Ejecuta `terraform apply`
5. Verifica que API funciona
6. Configura GitHub Actions (opcional pero recomendado)

---

**Estado:** ✅ Listo para producción
**Última actualización:** 2026-01-30
**Versión:** 1.0
