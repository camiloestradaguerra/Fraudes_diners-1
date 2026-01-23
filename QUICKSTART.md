# 🚀 Guía Rápida: Análisis de Fraudes con eda.ipynb

## ✅ Estado Actual

- ✅ AWS CLI instalado y configurado
- ✅ Credenciales AWS funcionando (cuenta: 822626720556)
- ✅ Acceso al bucket S3: `dcelip-dev-brz-fraud-s3`
- ✅ Archivo disponible: `df_fraudes.parquet` (1.35 MB, 63,019 registros, 27 columnas)
- ✅ Ambiente virtual configurado con todas las dependencias

## 📊 Dataset Información

**Ubicación:** `s3://dcelip-dev-brz-fraud-s3/modelo_fraude/input/raw/df_fraudes.parquet`

**Tamaño:** 
- 63,019 registros
- 27 columnas

**Columnas principales:**
- `FRecep`, `Socio`, `ID_TARJETA`, `Aut`
- `Ffraud`, `TipoFraude`, `Decision`
- `Valor`, `Pais`, `Entidad`, `Marca`
- Y 16 columnas más...

## 🏃 Cómo ejecutar el notebook

### Opción 1: Jupyter Lab (Recomendado)

```bash
# Desde el root del proyecto
uv run jupyter lab
```

Luego abre: `notebooks/eda.ipynb`

### Opción 2: Activar ambiente y ejecutar

```bash
source .venv/bin/activate
jupyter lab
```

### Opción 3: VS Code

1. Abre `notebooks/eda.ipynb`
2. Selecciona el kernel: Python 3.12.1 (.venv)
3. Ejecuta las celdas

## 📝 ¿Qué hace el notebook?

1. **Carga datos desde S3** usando credenciales AWS configuradas
2. **Análisis exploratorio completo:**
   - Vista previa de datos
   - Estadísticas descriptivas
   - Tipos de datos
   - Valores faltantes con visualizaciones
   - Duplicados
   - Análisis de la variable objetivo (fraude)
   - Distribución de clases
3. **Limpieza de datos** (customizable)
4. **Guarda dataset procesado** en S3 (opcional)

## 🔑 Autenticación

El notebook usa las credenciales configuradas con AWS CLI:
- **No requiere variables de entorno**
- **No requiere hardcodear credenciales**
- Lee automáticamente desde `~/.aws/credentials`

## 🧪 Verificar acceso

Para probar que todo funciona antes de usar el notebook:

```bash
python test_s3_access.py
```

Deberías ver:
```
✅ TODO FUNCIONA CORRECTAMENTE! Puedes usar el notebook eda.ipynb
```

## 📚 Próximos pasos

1. **Ejecuta el notebook** `eda.ipynb`
2. **Realiza el análisis exploratorio** y cleaning
3. **Guarda el dataset limpio** en S3 si es necesario
4. **Continúa con los pipelines:**
   - `1-data_sampling/`
   - `2-feature_engineering/`
   - `3-training/`
   - `4-evaluation/`
   - `5-model_registry/`

## 🆘 Troubleshooting

### Error de credenciales
```bash
aws sts get-caller-identity
```

### Error de permisos en S3
```bash
aws s3 ls s3://dcelip-dev-brz-fraud-s3/modelo_fraude/input/raw/
```

### Reinstalar dependencias
```bash
uv sync
```

## 💡 Tips

- El notebook tiene celdas comentadas para guardar datos procesados
- Puedes agregar más análisis según necesites
- Las visualizaciones son automáticas
- Detecta automáticamente la variable objetivo (fraude)

---

**¿Listo para empezar?**

```bash
uv run jupyter lab
```

Abre `notebooks/eda.ipynb` y ejecuta las celdas! 🚀
