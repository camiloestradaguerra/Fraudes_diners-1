#!/bin/bash
# Script para registrar el kernel de Jupyter

echo "🔧 Registrando kernel de Jupyter para fraudes-diners..."
echo ""

# Agregar uv al PATH
export PATH="$HOME/.local/bin:$PATH"

# Activar ambiente virtual
source .venv/bin/activate

# Registrar el kernel
python -m ipykernel install --user --name=fraudes-diners --display-name="Python 3.12 (fraudes-diners)"

echo ""
echo "✅ Kernel registrado exitosamente!"
echo ""
echo "📝 Para usar el kernel en VS Code:"
echo "   1. Abre el notebook (eda.ipynb)"
echo "   2. Haz clic en 'Select Kernel' en la esquina superior derecha"
echo "   3. Selecciona 'Python 3.12 (fraudes-diners)'"
echo ""
echo "O busca: 'Jupyter: Select Interpreter to start Jupyter server'"
