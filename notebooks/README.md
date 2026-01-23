# Notebooks - Análisis de Fraudes

## 📓 eda.ipynb

Notebook para análisis exploratorio de datos (EDA) y limpieza de datos del dataset de fraudes almacenado en S3.

### Prerequisitos

1. **Configurar credenciales AWS:**

```bash
aws configure
```

Ingresa:
- AWS Access Key ID
- AWS Secret Access Key
- Default region name: `us-east-1`
- Default output format: `json`

2. **Activar el ambiente virtual:**

```bash
source ../.venv/bin/activate
```

### Ejecutar el notebook

**Opción 1: Con ambiente activado**
```bash
source ../.venv/bin/activate
jupyter lab
```

**Opción 2: Usando uv (sin activar ambiente)**
```bash
cd ..  # Regresar al root del proyecto
uv run jupyter lab
```

### ¿Qué hace el notebook?

✅ Carga el archivo `df_fraudes.parquet` desde S3 usando credenciales AWS  
✅ Realiza análisis exploratorio completo:
- Información básica del dataset
- Estadísticas descriptivas
- Análisis de valores faltantes
- Detección de duplicados
- Análisis de la variable objetivo (fraude)
- Visualizaciones

✅ Guarda dataset limpio en S3 (opcional)

### Ubicación del archivo en S3

```
Bucket: dcelip-dev-brz-fraud-s3
Path: modelo_fraude/input/raw/df_fraudes.parquet
```

### Notas importantes

- El notebook usa las credenciales configuradas con `aws configure`
- No se usan variables de entorno
- Las credenciales se cargan automáticamente desde `~/.aws/credentials`
- Asegúrate de tener permisos de lectura en el bucket S3
