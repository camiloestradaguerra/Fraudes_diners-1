# Comandos útiles de uv para fraudes_diners

# Activar el ambiente virtual
source .venv/bin/activate

# O usar sin activar:
export PATH="$HOME/.local/bin:$PATH"

# Agregar dependencias comunes para ML
uv add xgboost lightgbm catboost  # Gradient boosting
uv add imbalanced-learn           # Para datos desbalanceados
uv add mlflow                      # Tracking de experimentos
uv add optuna                      # Optimización de hiperparámetros
uv add shap                        # Interpretabilidad
uv add fastapi uvicorn             # API
uv add python-dotenv               # Variables de entorno

# Ejecutar notebooks
uv run jupyter lab

# Ejecutar scripts individuales
uv run python src/pipelines/0-cleaning_data/main.py

# Ver dependencias instaladas
uv pip list

# Sincronizar (instalar/actualizar según pyproject.toml)
uv sync

# Crear requirements.txt (si es necesario)
uv pip freeze > requirements.txt
