#!/bin/bash

# 🔍 Terraform Setup Validator
# Verifica que todo esté listo antes de terraform init

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
PASSED=0
FAILED=0
WARNINGS=0

# Función para logs
log_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔍 Terraform Setup Validator${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 1. Verificar archivos de configuración
echo -e "${BLUE}1️⃣  Verificando archivos de configuración...${NC}\n"

files=(
    "provider.tf"
    "variables.tf"
    "locals.tf"
    "terraform.tfvars"
    "backend.tf"
    "ecr.tf"
    "iam.tf"
    "sagemaker.tf"
    "api_gateway.tf"
    "outputs.tf"
)

for file in "${files[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        lines=$(wc -l < "$SCRIPT_DIR/$file")
        log_pass "Archivo $file encontrado ($lines líneas)"
    else
        log_fail "Archivo $file NO encontrado"
    fi
done
echo ""

# 2. Verificar herramientas requeridas
echo -e "${BLUE}2️⃣  Verificando herramientas requeridas...${NC}\n"

# Terraform
if command -v terraform &> /dev/null; then
    tf_version=$(terraform version | head -n1)
    log_pass "Terraform instalado: $tf_version"
else
    log_fail "Terraform NO está instalado"
fi

# AWS CLI
if command -v aws &> /dev/null; then
    aws_version=$(aws --version)
    log_pass "AWS CLI instalado: $aws_version"
else
    log_fail "AWS CLI NO está instalado"
fi

# Docker
if command -v docker &> /dev/null; then
    docker_version=$(docker --version)
    log_pass "Docker instalado: $docker_version"
else
    log_fail "Docker NO está instalado"
fi

# JQ (para parsing JSON)
if command -v jq &> /dev/null; then
    log_pass "JQ instalado"
else
    log_warn "JQ no instalado (opcional pero útil)"
fi
echo ""

# 3. Verificar AWS Credentials
echo -e "${BLUE}3️⃣  Verificando AWS Credentials...${NC}\n"

if [ -n "$AWS_ACCESS_KEY_ID" ]; then
    account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "ERROR")
    if [ "$account_id" != "ERROR" ]; then
        log_pass "AWS Credentials válidas (Account: $account_id)"
    else
        log_fail "AWS Credentials no válidas"
    fi
elif [ -f "$HOME/.aws/credentials" ]; then
    log_pass "AWS Credentials file encontrado (~/.aws/credentials)"
else
    log_fail "AWS Credentials NO configuradas"
fi

if [ -f "$HOME/.aws/config" ]; then
    log_pass "AWS Config file encontrado (~/.aws/config)"
fi
echo ""

# 4. Validar terraform.tfvars
echo -e "${BLUE}4️⃣  Validando terraform.tfvars...${NC}\n"

if [ -f "$SCRIPT_DIR/terraform.tfvars" ]; then
    log_pass "terraform.tfvars encontrado"
    
    # Extraer account_id
    account_id=$(grep "^aws_account_id" "$SCRIPT_DIR/terraform.tfvars" | grep -oE '[0-9]{12}' || echo "")
    if [ -n "$account_id" ]; then
        log_pass "aws_account_id configurado: $account_id"
    else
        log_fail "aws_account_id NO está configurado en terraform.tfvars"
    fi
    
    # Extraer region
    region=$(grep "^aws_region" "$SCRIPT_DIR/terraform.tfvars" | grep -oE '"[^"]+"' | tr -d '"' || echo "")
    if [ -n "$region" ]; then
        log_pass "aws_region configurado: $region"
    else
        log_warn "aws_region no explícitamente configurado (usará default)"
    fi
    
    # Extraer environment
    environment=$(grep "^environment" "$SCRIPT_DIR/terraform.tfvars" | grep -oE '"[^"]+"' | tr -d '"' || echo "")
    if [ -n "$environment" ]; then
        log_pass "environment configurado: $environment"
    else
        log_fail "environment NO está configurado"
    fi
else
    log_fail "terraform.tfvars NO encontrado"
fi
echo ""

# 5. Validar sintaxis de Terraform
echo -e "${BLUE}5️⃣  Validando sintaxis de Terraform...${NC}\n"

cd "$SCRIPT_DIR"

# Verificar que terraform init no haya corrido aún
if [ -d ".terraform" ]; then
    log_warn ".terraform directory ya existe (posiblemente ya se ejecutó 'terraform init')"
else
    log_info "Primera ejecución (no hay .terraform directory)"
fi

# Inicializar backend local sin crear recursos
terraform init -backend=false -input=false > /dev/null 2>&1

if [ $? -eq 0 ]; then
    log_pass "terraform init (backend=false) exitoso"
else
    log_fail "terraform init falló - revisar sintaxis"
fi

# Validar sintaxis
if terraform validate > /dev/null 2>&1; then
    log_pass "terraform validate exitoso"
else
    log_fail "terraform validate falló"
    terraform validate
fi
echo ""

# 6. Verificar Dockerfile
echo -e "${BLUE}6️⃣  Verificando Dockerfile...${NC}\n"

if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    lines=$(wc -l < "$PROJECT_ROOT/Dockerfile")
    log_pass "Dockerfile encontrado en raíz del proyecto ($lines líneas)"
else
    log_warn "Dockerfile no encontrado en raíz - Terraform intentará build desde contexto"
fi

if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    deps=$(wc -l < "$PROJECT_ROOT/requirements.txt")
    log_pass "requirements.txt encontrado ($deps líneas)"
else
    log_warn "requirements.txt no encontrado - posible issue en Docker build"
fi
echo ""

# 7. Verificar permisos
echo -e "${BLUE}7️⃣  Verificando permisos...${NC}\n"

if [ -w "$SCRIPT_DIR" ]; then
    log_pass "Permiso de escritura en directorio terraform"
else
    log_fail "SIN permiso de escritura en directorio terraform"
fi

# Verificar permisos en deploy.sh
if [ -f "$SCRIPT_DIR/deploy.sh" ]; then
    if [ -x "$SCRIPT_DIR/deploy.sh" ]; then
        log_pass "deploy.sh es ejecutable"
    else
        log_warn "deploy.sh NO es ejecutable"
    fi
fi
echo ""

# 8. Revisar .gitignore
echo -e "${BLUE}8️⃣  Revisando .gitignore...${NC}\n"

if [ -f "$SCRIPT_DIR/.gitignore" ]; then
    if grep -q "\.terraform" "$SCRIPT_DIR/.gitignore"; then
        log_pass ".gitignore excluye .terraform"
    else
        log_warn ".gitignore no excluye .terraform"
    fi
    
    if grep -q "\.tfstate" "$SCRIPT_DIR/.gitignore"; then
        log_pass ".gitignore excluye .tfstate"
    else
        log_warn ".gitignore no excluye .tfstate"
    fi
else
    log_fail ".gitignore no encontrado"
fi
echo ""

# 9. Mostrar configuration actual
echo -e "${BLUE}9️⃣  Configuración actual...${NC}\n"

if [ -f "$SCRIPT_DIR/terraform.tfvars" ]; then
    log_info "terraform.tfvars:"
    echo ""
    grep -E "^(aws_account_id|aws_region|environment|project_name|docker_image_name|docker_image_tag)" "$SCRIPT_DIR/terraform.tfvars" | sed 's/^/  /'
    echo ""
fi

# 10. Resumen final
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 Resumen de Validación${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${GREEN}Pasaron: $PASSED${NC}"
echo -e "${RED}Fallaron: $FAILED${NC}"
echo -e "${YELLOW}Advertencias: $WARNINGS${NC}\n"

# Determinar resultado final
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Validación exitosa - Listo para 'terraform init'${NC}\n"
    
    echo -e "${BLUE}Próximos pasos:${NC}"
    echo "  1. cd terraform/"
    echo "  2. terraform init"
    echo "  3. terraform plan"
    echo "  4. terraform apply"
    echo ""
    
    exit 0
else
    echo -e "${RED}✗ Hay errores que deben ser corregidos${NC}\n"
    
    echo -e "${YELLOW}Solución rápida:${NC}"
    echo "  1. Instala Terraform: https://www.terraform.io/downloads.html"
    echo "  2. Instala AWS CLI: https://aws.amazon.com/cli/"
    echo "  3. Instala Docker: https://www.docker.com/products/docker-desktop"
    echo "  4. Configura AWS Credentials: aws configure"
    echo "  5. Ejecuta este script nuevamente"
    echo ""
    
    exit 1
fi
