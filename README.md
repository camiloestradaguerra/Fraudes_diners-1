# fraudes_diners

Modelos para detección de fraudes

## 🚀 Configuración del Proyecto

Este proyecto utiliza [uv](https://github.com/astral-sh/uv) para la gestión de dependencias y ambientes virtuales, una herramienta moderna y ultra-rápida para Python.

### Instalación de uv

Si aún no tienes `uv` instalado:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Setup Inicial

1. **Configurar el ambiente y instalar dependencias:**

```bash
./setup.sh
```

O manualmente:

```bash
export PATH="$HOME/.local/bin:$PATH"
uv sync
```

2. **Activar el ambiente virtual:**

```bash
source .venv/bin/activate
```

### 📦 Gestión de Dependencias

#### Agregar una nueva dependencia:
```bash
uv add <nombre-paquete>
```

Ejemplos:
```bash
uv add xgboost
uv add lightgbm
uv add mlflow
```

#### Agregar dependencias de desarrollo:
```bash
uv add --dev pytest
uv add --dev black
```

#### Remover una dependencia:
```bash
uv remove <nombre-paquete>
```

#### Actualizar dependencias:
```bash
uv sync --upgrade
```

### 🏃 Ejecutar Scripts

#### Con el ambiente activado:
```bash
source .venv/bin/activate
python src/pipelines/0-cleaning_data/main.py
```

#### Sin activar el ambiente (usando uv run):
```bash
uv run python src/pipelines/0-cleaning_data/main.py
```

### 📓 Jupyter Notebooks

Para usar Jupyter con el ambiente virtual:

**1. Registrar el kernel (solo primera vez):**
```bash
./register_kernel.sh
```

O manualmente:
```bash
source .venv/bin/activate
python -m ipykernel install --user --name=fraudes-diners --display-name="Python 3.12 (fraudes-diners)"
```

**2. Ejecutar Jupyter:**
```bash
uv run jupyter lab
```

O activar el ambiente y luego:

```bash
source .venv/bin/activate
jupyter lab
```

**3. En VS Code:**
- Abre el notebook
- Haz clic en "Select Kernel" (esquina superior derecha)
- Selecciona "Python 3.12 (fraudes-diners)"

Ver [KERNEL_SETUP.md](KERNEL_SETUP.md) para más detalles.

### 📂 Estructura del Proyecto

```
fraudes_diners/
├── src/
│   └── pipelines/
│       ├── 0-cleaning_data/
│       ├── 1-data_sampling/
│       ├── 2-feature_engineering/
│       ├── 3-training/
│       ├── 4-evaluation/
│       └── 5-model_registry/
├── notebooks/
├── pyproject.toml          # Configuración del proyecto y dependencias
├── setup.sh                # Script de configuración rápida
└── README.md
```

### 🛠️ Dependencias Principales

- **pandas**: Manipulación y análisis de datos
- **numpy**: Computación numérica
- **scikit-learn**: Machine learning
- **matplotlib & seaborn**: Visualización
- **jupyter**: Notebooks interactivos
- **boto3 & awscli**: Integración con AWS

### 💡 Ventajas de usar uv

- ⚡ **10-100x más rápido** que pip
- 🔒 Resolución de dependencias determinista
- 🎯 Compatible con pip y requirements.txt
- 📦 Gestión integrada de ambientes virtuales
- 🚀 Sin necesidad de instalar virtualenv o venv

### 📝 Notas

- El archivo `pyproject.toml` define todas las dependencias del proyecto
- El ambiente virtual se crea automáticamente en `.venv/`
- No es necesario commitear `.venv/` al repositorio (está en `.gitignore`)
