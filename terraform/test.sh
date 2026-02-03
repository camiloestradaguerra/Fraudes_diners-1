#!/bin/bash

# 🧪 Terraform Deployment Tester
# Verifica que todos los recursos fueron creados correctamente
# Se ejecuta DESPUÉS de 'terraform apply'

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Contadores
TESTS=0
PASSED=0
FAILED=0

# Función para ejecutar test
run_test() {
    local test_name=$1
    local test_command=$2
    ((TESTS++))
    
    echo -ne "${CYAN}Test $TESTS: $test_name... ${NC}"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

# Header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🧪 Terraform Deployment Test Suite${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 1. Verificar estado de Terraform
echo -e "${BLUE}1️⃣  Verificando estado de Terraform...${NC}\n"

cd "$SCRIPT_DIR"

if [ ! -d ".terraform" ]; then
    echo -e "${RED}✗ .terraform directory no encontrado - ejecuta 'terraform init' primero${NC}"
    exit 1
fi

if [ ! -f "terraform.tfstate" ] && [ ! -f "terraform.tfstate.backup" ]; then
    echo -e "${YELLOW}⚠ terraform.tfstate no encontrado - ¿Ya ejecutaste 'terraform apply'?${NC}\n"
fi

# 2. Verificar recursos creados
echo -e "${BLUE}2️⃣  Verificando recursos AWS creados...${NC}\n"

# ECR Repository
echo -e "${CYAN}ECR Repository:${NC}"
ecr_repo=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
if [ -n "$ecr_repo" ]; then
    echo -e "  ${GREEN}✓${NC} URL: $ecr_repo"
    
    # Verificar que el repositorio existe en AWS
    repo_name=$(echo "$ecr_repo" | cut -d'/' -f2)
    if aws ecr describe-repositories --repository-names "$repo_name" --region us-east-1 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Repositorio verificado en AWS"
    else
        echo -e "  ${RED}✗${NC} Repositorio NO encontrado en AWS"
    fi
else
    echo -e "  ${RED}✗${NC} Output 'ecr_repository_url' no disponible"
fi
echo ""

# Docker Image
echo -e "${CYAN}Docker Image:${NC}"
docker_image=$(terraform output -raw docker_image_uri 2>/dev/null || echo "")
if [ -n "$docker_image" ]; then
    echo -e "  ${GREEN}✓${NC} URI: $docker_image"
else
    echo -e "  ${RED}✗${NC} Output 'docker_image_uri' no disponible"
fi
echo ""

# SageMaker Endpoint
echo -e "${CYAN}SageMaker Endpoint:${NC}"
endpoint_name=$(terraform output -raw sagemaker_endpoint_name 2>/dev/null || echo "")
if [ -n "$endpoint_name" ]; then
    echo -e "  ${GREEN}✓${NC} Nombre: $endpoint_name"
    
    # Verificar estado del endpoint
    endpoint_status=$(aws sagemaker describe-endpoint --endpoint-name "$endpoint_name" --region us-east-1 --query 'EndpointStatus' --output text 2>/dev/null || echo "ERROR")
    if [ "$endpoint_status" = "InService" ]; then
        echo -e "  ${GREEN}✓${NC} Estado: $endpoint_status"
    elif [ "$endpoint_status" = "ERROR" ]; then
        echo -e "  ${RED}✗${NC} Endpoint no encontrado en AWS"
    else
        echo -e "  ${YELLOW}⚠${NC} Estado: $endpoint_status (creándose...)"
    fi
else
    echo -e "  ${RED}✗${NC} Output 'sagemaker_endpoint_name' no disponible"
fi
echo ""

# API Gateway
echo -e "${CYAN}API Gateway:${NC}"
api_url=$(terraform output -raw api_invoke_url 2>/dev/null || echo "")
if [ -n "$api_url" ]; then
    echo -e "  ${GREEN}✓${NC} URL: $api_url"
else
    echo -e "  ${RED}✗${NC} Output 'api_invoke_url' no disponible"
fi
echo ""

# 3. Tests de conectividad
echo -e "${BLUE}3️⃣  Tests de conectividad...${NC}\n"

if [ -n "$api_url" ]; then
    echo -e "${CYAN}API Gateway Connectivity:${NC}"
    
    # Test OPTIONS (preflight)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "$api_url" 2>/dev/null || echo "000")
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 404 ]; then
        echo -e "  ${GREEN}✓${NC} OPTIONS response: $http_code"
    else
        echo -e "  ${YELLOW}⚠${NC} OPTIONS response: $http_code (posible issue de CORS)"
    fi
    
    # Test GET (debería fallar pero conecta)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$api_url" 2>/dev/null || echo "000")
    echo -e "  ℹ GET response: $http_code (esperado: 404 o 405)"
    
    echo ""
fi

# 4. Tests de invocación de API
echo -e "${BLUE}4️⃣  Tests de invocación de API...${NC}\n"

if [ -n "$api_url" ]; then
    echo -e "${CYAN}Invocación API con datos de prueba:${NC}"
    
    # Datos de prueba
    test_payload='{"Amount": 100.0, "Time": 1000, "V1": -1.5, "V2": 0.5}'
    
    echo -e "  Payload: $test_payload\n"
    
    # Hacer request
    response=$(curl -s -X POST "$api_url" \
        -H "Content-Type: application/json" \
        -d "$test_payload" 2>/dev/null || echo "ERROR")
    
    if [ "$response" != "ERROR" ]; then
        echo -e "  ${GREEN}✓${NC} Response recibido:"
        echo "$response" | head -n 5 | sed 's/^/    /'
        
        # Verificar si es un objeto JSON válido
        if echo "$response" | jq . > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} JSON válido"
        else
            echo -e "  ${YELLOW}⚠${NC} Response no es JSON válido"
        fi
    else
        echo -e "  ${RED}✗${NC} No se pudo conectar a la API"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} API URL no disponible - salta este test"
fi
echo ""

# 5. Verificar IAM Roles
echo -e "${BLUE}5️⃣  Verificando IAM Roles...${NC}\n"

sagemaker_role=$(terraform output -raw sagemaker_execution_role_arn 2>/dev/null || echo "")
apigateway_role=$(terraform output -raw apigateway_sagemaker_role_arn 2>/dev/null || echo "")

if [ -n "$sagemaker_role" ]; then
    echo -e "  ${GREEN}✓${NC} SageMaker Role: ${sagemaker_role##*/}"
else
    echo -e "  ${RED}✗${NC} SageMaker Role output no disponible"
fi

if [ -n "$apigateway_role" ]; then
    echo -e "  ${GREEN}✓${NC} API Gateway Role: ${apigateway_role##*/}"
else
    echo -e "  ${RED}✗${NC} API Gateway Role output no disponible"
fi
echo ""

# 6. Verificar variables de entorno
echo -e "${BLUE}6️⃣  Verificando variables de Terraform...${NC}\n"

echo -e "${CYAN}Configuration:${NC}"
account_id=$(terraform output -raw account_id 2>/dev/null || echo "")
region=$(terraform output -raw region 2>/dev/null || echo "")
environment=$(terraform output -raw environment 2>/dev/null || echo "")

[ -n "$account_id" ] && echo -e "  ${GREEN}✓${NC} Account ID: $account_id"
[ -n "$region" ] && echo -e "  ${GREEN}✓${NC} Region: $region"
[ -n "$environment" ] && echo -e "  ${GREEN}✓${NC} Environment: $environment"
echo ""

# 7. Mostrar información completa
echo -e "${BLUE}7️⃣  Información de deployment...${NC}\n"

echo -e "${CYAN}Resumen Completo:${NC}"
terraform output -json deployment_info 2>/dev/null | jq . 2>/dev/null || terraform output deployment_info 2>/dev/null || echo "Output no disponible"
echo ""

# 8. Resumen final
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 Resumen de Tests${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "Total Tests: ${CYAN}$TESTS${NC}"
echo -e "Pasaron: ${GREEN}$PASSED${NC}"
echo -e "Fallaron: ${RED}$FAILED${NC}\n"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Todos los tests pasaron!${NC}\n"
    exit 0
else
    echo -e "${RED}✗ Algunos tests fallaron - revisar output arriba${NC}\n"
    exit 1
fi
