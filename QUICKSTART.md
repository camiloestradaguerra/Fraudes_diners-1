# 🚀 QUICK START: Deploy a AWS en 4 Pasos

**Resumen ejecutivo para deployar rápido tu API a producción profesional**

---

## ⏱️ Tiempo Total: ~20 minutos

---

## 1️⃣ DOCKERFILE: "Empaquetar tu app"

**¿Qué es?** Una "receta" que describe cómo correr tu FastAPI en cualquier servidor.

**¿Para qué sirve?**
- Garantiza que funciona igual en tu PC, AWS, o cualquier lugar
- Versiona exactamente qué dependencias usas
- Elimina problemas de "en mi máquina funciona"

**Ventajas:** ✅ Reproducibilidad, ✅ Fácil de testear, ✅ Isolamiento
**Desventajas:** ❌ Aprende Docker, ❌ Imagen pesada (~2GB)

**Archivo:** `Dockerfile` (raíz)

**Quick Command:**
```bash
# Test localmente
docker build -t fraud-api:local .
docker run -p 8000:8000 fraud-api:local
curl http://localhost:8000/health
```

---

## 2️⃣ GITHUB ACTIONS: "Automatizar deployment"

**¿Qué es?** CI/CD: cada vez que pusheas código a GitHub, automáticamente:
1. Corre tests
2. Construye Docker image
3. Pushea a ECR (registro de Docker)
4. Actualiza ECS (AWS redeploya)

**¿Para qué sirve?**
- 0 pasos manuales: solo `git push` → API en producción en 3 min
- Rollback fácil: revert commit = revert deployment
- Historial: git log = deployment log

**Ventajas:** ✅ Automatización 1-click, ✅ Rollback fácil, ✅ Historial
**Desventajas:** ❌ Debugging en nube es difícil, ❌ Secretos a gestionar

**Archivo:** `.github/workflows/deploy.yml`

**Quick Setup:**
```bash
# En GitHub Repo Settings → Secrets and variables:
Agregar:
  AWS_ROLE_ARN (u AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY)
  DOCKERHUB_USERNAME
  DOCKERHUB_PASSWORD
  AWS_ACCOUNT_ID
  AWS_REGION
```

**Resultado:** Cada `git push main` → deployment automático

---

## 3️⃣ DOCUMENTACIÓN: "Entender y mantener"

**¿Qué es?** Este archivo que estás leyendo + AWS_DEPLOYMENT_GUIDE.md + MANUAL_DEPLOYMENT.md

**¿Para qué sirve?**
- Onboarding del equipo
- Reference cuando algo falla
- Decisiones arquitectónicas explicadas

**Ventajas:** ✅ Facilita onboarding, ✅ Troubleshooting rápido
**Desventajas:** ❌ Requiere mantenimiento

**Archivos:**
- `AWS_DEPLOYMENT_GUIDE.md` - Guía completa (este que leíste)
- `MANUAL_DEPLOYMENT.md` - Pasos manuales sin GitHub Actions
- `QUICKSTART.md` - Este archivo

---

## 🎯 Pasos a Seguir (Orden Correcto)

### **DÍA 1: Preparación**
```bash
# 1. Instalar tools (5 min)
# - AWS CLI, Docker

# 2. Configurar AWS
aws configure
# Ingresa: Access Key, Secret Key, región

# 3. Testear Docker localmente (5 min)
docker build -t fraud-api:local .
docker run -p 8000:8000 fraud-api:local
curl http://localhost:8000/docs
```

### **DÍA 2: Deploy Infraestructura con CloudFormation**
```bash
# 1. Configurar AWS CLI con tus credenciales
aws configure

# 2. Deploy CloudFormation stack (10-15 min)
cd cloudformation
aws cloudformation create-stack \
  --stack-name fraud-detection-stack \
  --template-body file://infra.yaml \
  --capabilities CAPABILITY_NAMED_IAM

# 3. Ver el estado del deploy
aws cloudformation describe-stacks \
  --stack-name fraud-detection-stack

# 4. Obtener URLs resultantes
aws cloudformation describe-stacks \
  --stack-name fraud-detection-stack \
  --query 'Stacks[0].Outputs'
```

### **DÍA 3: Configura CI/CD (opcional pero recomendado)**
```bash
# 1. Push código a GitHub (con Dockerfile, cloudformation/**, .github/**)

# 2. En GitHub → Settings → Secrets:
# Agrega AWS credenciales

# 3. Haz commit test
git commit -m "Setup CI/CD"
git push origin main

# Ve a GitHub → Actions
# Verás tu workflow corriendo
# ~3 min después: API en producción
```

### **DÍA 4: Migra usuarios de ngrok**
```bash
# 1. Obtén URL de API Gateway
aws cloudformation describe-stacks \
  --stack-name fraud-detection-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text

# 2. Reemplaza en clientes:
# De: https://xxx.ngrok.io/fraud/predict
# A:  https://yyy.execute-api.us-east-1.amazonaws.com/prod/fraud/predict

# 3. Verifica que funciona
curl -X POST https://yyy.execute-api.../fraud/predict \
  -H "Content-Type: application/json" \
  -d '{"transaction_id":"TRX1", "monto":100, "edad":35, ...}'
```

---

## 💰 Costos Reales

```
ECS Fargate (2 replicas, 24h):    $60/mes
API Gateway (100k requests):      $3-10/mes
Load Balancer (ALB):              $16/mes
Networking (data out):            $0-5/mes
CloudWatch Logs:                  $5-10/mes
---
TOTAL:                            $85-100/mes

vs ngrok: $5-15/mes (pero limitado, temporal)
vs EC2: $100-200/mes (pero mantenimiento)
```

---

## 🔄 Workflow Después de Setup

### Desarrollo Local
```bash
# 1. Hacer cambios
vim endpoint_prototipo/main.py

# 2. Test localmente
docker build -t fraud-api:test .
docker run -p 8000:8000 fraud-api:test

# 3. Commit y push
git add .
git commit -m "Feature: nuevo endpoint"
git push origin main

# 4. Automáticamente:
# ✓ Tests corren
# ✓ Docker image se construye
# ✓ Pushea a ECR
# ✓ ECS se actualiza
# ✓ ~3 minutos: en producción ✨
```

### Monitoreo
```bash
# Ver logs en tiempo real
aws logs tail /ecs/fraud-api --follow

# Ver métricas (CPU, memoria)
AWS Console → ECS → Clusters → fraud-api-cluster

# Alertas
AWS Console → CloudWatch → Alarms
(Configura: si CPU > 80%, notifica)
```

### Escalar
```bash
# Más tráfico? Actualiza CloudFormation:
# Edita cloudformation/infra.yaml:
DesiredCount: 10  # en lugar de 5

# Aplica:
aws cloudformation update-stack \
  --stack-name fraud-detection-stack \
  --template-body file://infra.yaml \
  --capabilities CAPABILITY_NAMED_IAM

# Auto-scaling hará el resto
```

---

## 🆘 Si Algo Falla

| Error | Solución |
|-------|----------|
| "Connection refused" | ¿ECS tasks están corriendo? `aws ecs describe-services ...` |
| "502 Bad Gateway" | Load Balancer no tiene targets. Espera 2-3 min o verifica health checks |
| "Docker push fails" | ¿Credenciales ECR? `aws ecr get-login-password \| docker login ...` |
| "CloudFormation error" | ¿AWS credentials correctas? `aws sts get-caller-identity` |
| "Containers exit" | Ver logs: `aws logs tail /ecs/fraud-api` |

---

## 📚 Archivos Importantes

```
Proyecto/
├── Dockerfile                      ← Receta Docker
├── .dockerignore                   ← Archivos a NO incluir
├── cloudformation/
│   ├── infra.yaml                  ← Infraestructura principal
│   ├── infra-complete-codebuild.yaml  ← CodeBuild config
│   └── infra-sagemaker-complete.yaml  ← SageMaker config
├── .github/workflows/
│   └── deploy.yml                  ← CI/CD automation
├── AWS_DEPLOYMENT_GUIDE.md         ← Guía completa (TU PRINCIPAL REFERENCIA)
├── MANUAL_DEPLOYMENT.md            ← Pasos sin CI/CD
└── QUICKSTART.md                   ← Este archivo
```

---

## ✅ Checklist Deployment

- [ ] AWS CLI configurado (`aws sts get-caller-identity` funciona)
- [ ] Docker instalado (`docker --version`)
- [ ] `Dockerfile` creado y testeado localmente
- [ ] `cloudformation/` templates listos (infra.yaml, etc)
- [ ] CloudFormation stack creado exitosamente
- [ ] `aws cloudformation describe-stacks` muestra URLs
- [ ] API responde en `${API_URL}/health`
- [ ] GitHub Actions configurado (opcional)
- [ ] Usuarios migrados de ngrok a nueva URL

---

## 🎓 Siguientes Pasos

1. **Ahora:** Lee `AWS_DEPLOYMENT_GUIDE.md` completo
2. **Luego:** Ejecuta Pasos 1-2 de "Pasos a Seguir" arriba
3. **Después:** Configura GitHub Actions (Paso 3)
4. **Finalmente:** Establece monitoreo + alertas

---

## 📞 Preguntas Frecuentes

**P: ¿Cuándo pierdo los datos si elimino el stack de CloudFormation?**
R: No hay base de datos. Pero sí pierdes logs en CloudWatch.

**P: ¿Puedo parar sin destruir?**
R: Sí, reduce `DesiredCount` a 0 sin eliminar el stack.

**P: ¿Cómo rollback si salió mal?**
R: `git revert <commit>` + `git push` → redeploya automáticamente.

**P: ¿Cómo agregar dominio custom (fraud-api.miempresa.com)?**
R: Route53 + Certificate Manager (documentado en AWS_DEPLOYMENT_GUIDE.md).

**P: ¿Y si necesito base de datos?**
R: Agrega RDS a CloudFormation (MySQL/PostgreSQL en infra.yaml).

---

**Última actualización:** 2026-01-30
**Autor:** Data Science Team
**Status:** ✅ Listo para producción
- `Ffraud`, `TipoFraude`, `Decision`
- `Valor`, `Pais`, `Entidad`, `Marca`
- Y 16 columnas más...

## 🏃 Cómo ejecutar el notebook

### Opción 1: Jupyter Lab (Recomendado)

```bash
# Desde el root del proyecto
uv run jupyter lab
```

Luego abre: `notebooks/eda.ipynb`

### Opción 2: Activar ambiente y ejecutar

```bash
source .venv/bin/activate
jupyter lab
```

### Opción 3: VS Code

1. Abre `notebooks/eda.ipynb`
2. Selecciona el kernel: Python 3.12.1 (.venv)
3. Ejecuta las celdas

## 📝 ¿Qué hace el notebook?

1. **Carga datos desde S3** usando credenciales AWS configuradas
2. **Análisis exploratorio completo:**
   - Vista previa de datos
   - Estadísticas descriptivas
   - Tipos de datos
   - Valores faltantes con visualizaciones
   - Duplicados
   - Análisis de la variable objetivo (fraude)
   - Distribución de clases
3. **Limpieza de datos** (customizable)
4. **Guarda dataset procesado** en S3 (opcional)

## 🔑 Autenticación

El notebook usa las credenciales configuradas con AWS CLI:
- **No requiere variables de entorno**
- **No requiere hardcodear credenciales**
- Lee automáticamente desde `~/.aws/credentials`

## 🧪 Verificar acceso

Para probar que todo funciona antes de usar el notebook:

```bash
python test_s3_access.py
```

Deberías ver:
```
✅ TODO FUNCIONA CORRECTAMENTE! Puedes usar el notebook eda.ipynb
```

## 📚 Próximos pasos

1. **Ejecuta el notebook** `eda.ipynb`
2. **Realiza el análisis exploratorio** y cleaning
3. **Guarda el dataset limpio** en S3 si es necesario
4. **Continúa con los pipelines:**
   - `1-data_sampling/`
   - `2-feature_engineering/`
   - `3-training/`
   - `4-evaluation/`
   - `5-model_registry/`

## 🆘 Troubleshooting

### Error de credenciales
```bash
aws sts get-caller-identity
```

### Error de permisos en S3
```bash
aws s3 ls s3://dcelip-dev-brz-fraud-s3/modelo_fraude/input/raw/
```

### Reinstalar dependencias
```bash
uv sync
```

## 💡 Tips

- El notebook tiene celdas comentadas para guardar datos procesados
- Puedes agregar más análisis según necesites
- Las visualizaciones son automáticas
- Detecta automáticamente la variable objetivo (fraude)

---

**¿Listo para empezar?**

```bash
uv run jupyter lab
```

Abre `notebooks/eda.ipynb` y ejecuta las celdas! 🚀
