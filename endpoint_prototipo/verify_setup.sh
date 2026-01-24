#!/bin/bash

# Script de verificación - Fraud Detection API

echo "════════════════════════════════════════════════════════════════"
echo "✓ Verificación de Instalación - Fraud Detection API"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar Python
echo "1. Verificando Python..."
if command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}')
    echo "   ✓ Python $PYTHON_VERSION encontrado"
else
    echo "   ✗ Python NO encontrado"
    exit 1
fi
echo ""

# Verificar FastAPI
echo "2. Verificando FastAPI..."
if python -c "import fastapi" 2>/dev/null; then
    echo "   ✓ FastAPI instalado"
else
    echo "   ✗ FastAPI NO instalado"
    echo "   Ejecuta: pip install -r requirements.txt"
    exit 1
fi
echo ""

# Verificar Pydantic
echo "3. Verificando Pydantic..."
if python -c "import pydantic" 2>/dev/null; then
    echo "   ✓ Pydantic instalado"
else
    echo "   ✗ Pydantic NO instalado"
    echo "   Ejecuta: pip install -r requirements.txt"
    exit 1
fi
echo ""

# Verificar Uvicorn
echo "4. Verificando Uvicorn..."
if python -c "import uvicorn" 2>/dev/null; then
    echo "   ✓ Uvicorn instalado"
else
    echo "   ✗ Uvicorn NO instalado"
    echo "   Ejecuta: pip install -r requirements.txt"
    exit 1
fi
echo ""

# Verificar estructura de archivos
echo "5. Verificando estructura de archivos..."
FILES=(
    "main.py"
    "schemas.py"
    "routers/fraud_prediction.py"
    "routers/health.py"
)

ALL_EXIST=true
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✓ $file"
    else
        echo "   ✗ $file FALTA"
        ALL_EXIST=false
    fi
done
echo ""

# Verificar documentación
echo "6. Verificando documentación..."
DOCS=(
    "QUICKSTART.md"
    "FRAUD_API_README.md"
    "CAMBIOS_REALIZADOS.md"
    "API_EXAMPLES.json"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "   ✓ $doc"
    else
        echo "   ✗ $doc FALTA"
    fi
done
echo ""

# Resumen
echo "════════════════════════════════════════════════════════════════"
if [ "$ALL_EXIST" = true ]; then
    echo "✓ VERIFICACIÓN COMPLETADA - Todo está listo"
    echo ""
    echo "Próximos pasos:"
    echo "1. Ejecuta: python main.py"
    echo "2. Abre: http://localhost:8000/docs"
    echo "3. ¡Prueba los endpoints!"
else
    echo "✗ VERIFICACIÓN FALLIDA - Faltan archivos"
    exit 1
fi
echo "════════════════════════════════════════════════════════════════"
