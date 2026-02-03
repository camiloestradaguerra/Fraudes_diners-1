#!/bin/bash
# Deploy script para Terraform Fraud Detection API

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${PROJECT_DIR}/terraform"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner
print_banner() {
    echo -e "${BLUE}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "    🚀 Terraform MLOps - Fraud Detection API Deployment"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

# Menu
print_menu() {
    echo -e "${YELLOW}Opciones:${NC}"
    echo "1) terraform init          - Inicializar Terraform"
    echo "2) terraform plan          - Ver cambios"
    echo "3) terraform apply         - Desplegar"
    echo "4) terraform output        - Ver outputs"
    echo "5) terraform destroy       - Destruir recursos"
    echo "6) Full deploy             - Init + Plan + Apply"
    echo "7) Full destroy            - Plan destroy + Destroy"
    echo "0) Salir"
    echo ""
}

# Funciones
do_init() {
    echo -e "${BLUE}[*] Inicializando Terraform...${NC}"
    cd "$TERRAFORM_DIR"
    terraform init
    echo -e "${GREEN}[✓] Inicialización completada${NC}"
}

do_plan() {
    echo -e "${BLUE}[*] Planificando cambios...${NC}"
    cd "$TERRAFORM_DIR"
    terraform plan -out=tfplan
    echo -e "${GREEN}[✓] Plan guardado en tfplan${NC}"
}

do_apply() {
    echo -e "${BLUE}[*] Aplicando cambios...${NC}"
    cd "$TERRAFORM_DIR"
    
    if [ -f tfplan ]; then
        terraform apply tfplan
    else
        terraform apply
    fi
    
    echo -e "${GREEN}[✓] Deployment completado${NC}"
    
    # Mostrar outputs
    echo ""
    echo -e "${YELLOW}Outputs principales:${NC}"
    terraform output -json | jq '.api_invoke_url.value' 2>/dev/null || terraform output api_invoke_url
}

do_output() {
    echo -e "${YELLOW}Outputs de Terraform:${NC}"
    cd "$TERRAFORM_DIR"
    terraform output
}

do_destroy() {
    echo -e "${RED}[!] ADVERTENCIA: Esto eliminará todos los recursos${NC}"
    read -p "¿Está seguro? (yes/no): " -r REPLY
    if [[ "$REPLY" =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${BLUE}[*] Destruyendo recursos...${NC}"
        cd "$TERRAFORM_DIR"
        terraform destroy
        echo -e "${GREEN}[✓] Recursos eliminados${NC}"
    else
        echo "Cancelado"
    fi
}

do_full_deploy() {
    echo -e "${BLUE}[*] Iniciando full deploy...${NC}"
    do_init
    echo ""
    do_plan
    echo ""
    read -p "¿Continuar con apply? (yes/no): " -r REPLY
    if [[ "$REPLY" =~ ^[Yy][Ee][Ss]$ ]]; then
        do_apply
    else
        echo "Cancelado"
    fi
}

do_full_destroy() {
    echo -e "${BLUE}[*] Plan de destrucción...${NC}"
    cd "$TERRAFORM_DIR"
    terraform plan -destroy
    
    echo ""
    read -p "¿Continuar con destroy? (yes/no): " -r REPLY
    if [[ "$REPLY" =~ ^[Yy][Ee][Ss]$ ]]; then
        do_destroy
    else
        echo "Cancelado"
    fi
}

# Main loop
print_banner

if [ $# -eq 0 ]; then
    while true; do
        print_menu
        read -p "Seleccione opción: " -r OPTION
        
        case $OPTION in
            1) do_init ;;
            2) do_plan ;;
            3) do_apply ;;
            4) do_output ;;
            5) do_destroy ;;
            6) do_full_deploy ;;
            7) do_full_destroy ;;
            0) echo "Saliendo..."; exit 0 ;;
            *) echo -e "${RED}Opción inválida${NC}" ;;
        esac
        
        echo ""
        read -p "Presione Enter para continuar..."
    done
else
    # Ejecutar comando pasado como argumento
    case "$1" in
        init) do_init ;;
        plan) do_plan ;;
        apply) do_apply ;;
        output) do_output ;;
        destroy) do_destroy ;;
        full-deploy) do_full_deploy ;;
        full-destroy) do_full_destroy ;;
        *) echo "Opción desconocida: $1"; exit 1 ;;
    esac
fi
