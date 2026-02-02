# GitHub + CodeBuild + ECS/Fargate Deployment

## Requisitos

1. **Código en GitHub**: ✅ Ya está en `https://github.com/camiloestradaguerra/Fraudes_diners-1.git`
2. **AWS CLI configurado**: ✅ Ya tienes credenciales
3. **Dockerfile**: ✅ Ya existe en el repo
4. **buildspec.yml**: ✅ Ya existe en el repo

## Pasos de Deployment

### PASO 1: Crear Rol IAM para CodeBuild

Ejecuta esto **una sola vez** (o en AWS Console):

```bash
# Crear rol
aws iam create-role --role-name codebuild-fraudes-diners-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "codebuild.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach ECR + Logs policy
aws iam put-role-policy --role-name codebuild-fraudes-diners-role \
  --policy-name codebuild-policy --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["ecr:*", "logs:*"],
      "Resource": "*"
    }]
  }'
```

### PASO 2: Setup CodeBuild (vinculado a GitHub)

```powershell
.\setup_github_codebuild.ps1
```

Esto crea un proyecto CodeBuild que:
- Lee el código desde GitHub
- Ejecuta `buildspec.yml`
- Construye la imagen Docker
- La pushea a ECR

### PASO 3: Trigger el Build

```bash
aws codebuild start-build --project-name fraudes-diners-build --region us-east-1
```

Monitorea con:
```bash
aws logs tail /aws/codebuild/fraudes-diners --follow
```

### PASO 4: Deploy a ECS/Fargate

```powershell
.\deploy_to_ecs.ps1
```

Esto crea:
- Cluster ECS
- Task Definition
- Service con Fargate
- VPC y Security Groups

## Resultado Final

Tu aplicación FastAPI estará corriendo en **ECS/Fargate** accesible desde internet.

## Monitoreo

```bash
# Ver servicio
aws ecs describe-services --cluster fraudes-diners-cluster --services fraudes-diners-service --region us-east-1

# Ver logs
aws logs tail /ecs/fraudes-diners --follow --region us-east-1

# Obtener URL pública
aws ecs describe-tasks --cluster fraudes-diners-cluster --tasks <task-arn> --region us-east-1 --query 'tasks[0].attachments[*].[name,value]' --output table
```

