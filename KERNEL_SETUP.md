# 🎯 Seleccionar Kernel en VS Code para Jupyter Notebooks

## ✅ Kernel Configurado

Ya está registrado el kernel **"Python 3.12 (fraudes-diners)"** que usa el ambiente virtual de uv.

## 📝 Cómo seleccionar el kernel en VS Code

### Opción 1: Desde el notebook abierto

1. **Abre** el notebook `notebooks/eda.ipynb`
2. Busca en la **esquina superior derecha** el botón que dice "Select Kernel" o muestra el kernel actual
3. **Haz clic** en ese botón
4. Selecciona: **"Python 3.12 (fraudes-diners)"**

### Opción 2: Desde la paleta de comandos

1. Presiona `Ctrl+Shift+P` (o `Cmd+Shift+P` en Mac)
2. Escribe: **"Jupyter: Select Interpreter to start Jupyter server"**
3. Selecciona: **"Python 3.12 (fraudes-diners)"**

### Opción 3: Cerrar y reabrir el notebook

1. **Cierra** el notebook `eda.ipynb`
2. **Reabre** el notebook
3. VS Code debería detectar automáticamente el kernel configurado

## 🔍 Verificar que el kernel está disponible

Ejecuta en el terminal:

```bash
jupyter kernelspec list
```

Deberías ver:

```
Available kernels:
  fraudes-diners    /home/codespace/.local/share/jupyter/kernels/fraudes-diners
  python3           /workspaces/fraudes_diners/.venv/share/jupyter/kernels/python3
```

## 🆘 Si no aparece el kernel

Ejecuta el script de registro:

```bash
./register_kernel.sh
```

O manualmente:

```bash
source .venv/bin/activate
python -m ipykernel install --user --name=fraudes-diners --display-name="Python 3.12 (fraudes-diners)"
```

## ✨ Después de seleccionar el kernel

Una vez seleccionado el kernel, podrás:

✅ Ejecutar las celdas del notebook  
✅ Acceder a todas las librerías instaladas (pandas, s3fs, etc.)  
✅ Conectarte a S3 con las credenciales AWS configuradas  
✅ Realizar el análisis exploratorio de datos  

## 🎯 Verificación rápida

Ejecuta la primera celda del notebook (importaciones). Si no muestra errores, ¡todo está funcionando! 🚀

---

**Nota:** Sí puedes usar notebooks con uv. El ambiente virtual de uv (`.venv/`) funciona perfectamente con Jupyter, solo necesitas registrar el kernel (ya lo hicimos). 👍
