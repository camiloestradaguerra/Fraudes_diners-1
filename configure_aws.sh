#!/bin/bash
# Script para configurar credenciales AWS

echo "🔐 Configuración de Credenciales AWS"
echo "======================================"
echo ""
echo "Este script te ayudará a configurar tus credenciales AWS."
echo ""
echo "Necesitarás:"
echo "  1. AWS Access Key ID"
echo "  2. AWS Secret Access Key"
echo "  3. Region (default: us-east-1)"
echo ""
echo "Ejecutando aws configure..."
echo ""

aws configure

echo ""
echo "✅ Configuración completada!"
echo ""
echo "Para verificar tu configuración:"
echo "  aws sts get-caller-identity"
echo ""
echo "Para probar el acceso al bucket:"
echo "  aws s3 ls s3://dcelip-dev-brz-fraud-s3/ --region us-east-1"
