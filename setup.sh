#!/bin/bash
# Script para configurar el ambiente con uv

# Asegurarse de que uv esté en el PATH
export PATH="$HOME/.local/bin:$PATH"

echo "🚀 Configurando ambiente virtual con uv..."

# Crear ambiente virtual y sincronizar dependencias
uv sync

echo "✅ Ambiente configurado exitosamente!"
echo ""
echo "Para activar el ambiente virtual:"
echo "  source .venv/bin/activate"
echo ""
echo "Para agregar nuevas dependencias:"
echo "  uv add <paquete>"
echo ""
echo "Para ejecutar scripts sin activar el ambiente:"
echo "  uv run python script.py"
