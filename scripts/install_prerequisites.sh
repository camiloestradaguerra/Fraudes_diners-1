#!/bin/bash
#
# Script de instalación rápida: Prerequisites para AWS Deployment
# Ejecuta esto ANTES de terraform/github actions
#
# Uso: bash scripts/install_prerequisites.sh

set -e

echo "🔧 Instalando Prerequisites para AWS Deployment"
echo "================================================"

# Detectar SO
OS="$(uname -s)"
case "$OS" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=Mac;;
    MINGW*)     OS_TYPE=Windows;;
    *)          OS_TYPE="UNKNOWN";;
esac

echo "✓ Sistema Operativo: $OS_TYPE"

# 1. Verificar AWS CLI
echo ""
echo "1️⃣  Verificando AWS CLI..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version)
    echo "✓ AWS CLI instalado: $AWS_VERSION"
else
    echo "❌ AWS CLI no encontrado"
    echo "   Descarga desde: https://aws.amazon.com/cli/"
    exit 1
fi

# 2. Verificar AWS Configuration
echo ""
echo "2️⃣  Verificando configuración AWS..."
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo "✓ AWS configurado correctamente"
    echo "  Account ID: $ACCOUNT_ID"
else
    echo "❌ AWS no configurado"
    echo "   Ejecuta: aws configure"
    exit 1
fi

# 3. Verificar Docker
echo ""
echo "3️⃣  Verificando Docker..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "✓ Docker instalado: $DOCKER_VERSION"
else
    echo "❌ Docker no encontrado"
    echo "   Descarga desde: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# 4. Verificar Terraform
echo ""
echo "4️⃣  Verificando Terraform..."
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform --version)
    echo "✓ Terraform instalado: $TF_VERSION"
else
    echo "❌ Terraform no encontrado"
    if [ "$OS_TYPE" = "Mac" ]; then
        echo "   Ejecuta: brew install terraform"
    elif [ "$OS_TYPE" = "Linux" ]; then
        echo "   Ejecuta: sudo apt-get install terraform"
    else
        echo "   Descarga desde: https://www.terraform.io/downloads"
    fi
    exit 1
fi

# 5. Verificar Git
echo ""
echo "5️⃣  Verificando Git..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo "✓ Git instalado: $GIT_VERSION"
else
    echo "❌ Git no encontrado"
    exit 1
fi

# 6. Verificar jq (opcional pero útil)
echo ""
echo "6️⃣  Verificando jq (JSON parser)..."
if command -v jq &> /dev/null; then
    echo "✓ jq instalado"
else
    echo "⚠️  jq no encontrado (opcional)"
    echo "   Recomendado para parsing JSON"
    if [ "$OS_TYPE" = "Mac" ]; then
        echo "   Instala con: brew install jq"
    elif [ "$OS_TYPE" = "Linux" ]; then
        echo "   Instala con: sudo apt-get install jq"
    fi
fi

# 7. Docker Hub Login
echo ""
echo "7️⃣  Verificando Docker Hub..."
if docker info &> /dev/null; then
    echo "✓ Docker daemon corriendo"
else
    echo "❌ Docker daemon no está corriendo"
    echo "   Inicia Docker Desktop"
    exit 1
fi

# 8. Crear estructura de directorios
echo ""
echo "8️⃣  Creando estructura de directorios..."
mkdir -p terraform
mkdir -p .github/workflows
mkdir -p scripts
mkdir -p .aws-deployment
echo "✓ Directorios creados"

# 9. Resumen
echo ""
echo "================================================"
echo "✨ Todos los prerequisites están listos!"
echo "================================================"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Lee: AWS_DEPLOYMENT_GUIDE.md"
echo "   2. Configura: terraform/terraform.tfvars"
echo "   3. Deploy: terraform apply"
echo "   4. Configura GitHub Secrets para CI/CD"
echo ""
echo "🎯 Comandos útiles:"
echo "   - docker build -t fraud-api:latest ."
echo "   - cd terraform && terraform plan"
echo "   - aws ecr get-login-password | docker login --username AWS --password-stdin"
echo ""
