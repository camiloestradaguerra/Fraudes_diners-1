#!/usr/bin/env python3
"""
Script para leer y explorar el archivo df_fraudes.parquet
Puede leer desde S3 o desde archivo local
"""

import pandas as pd
import sys
import os

# Configuración - EDITA ESTA RUTA según donde esté tu archivo
# Opción 1: Archivo local en el contenedor
# FILE_PATH = "/workspaces/fraudes_diners/df_fraudes.parquet"

# Opción 2: Desde S3
FILE_PATH = "s3://dcelip-dev-brz-fraud-s3/modelo_fraude/input/raw/df_fraudes.parquet"

# Si es S3, necesitamos storage_options
STORAGE_OPTIONS = {'use_ssl': True} if FILE_PATH.startswith('s3://') else None

# Configurar pandas para mostrar todas las columnas
pd.set_option('display.max_columns', None)
pd.set_option('display.width', None)
pd.set_option('display.max_colwidth', 50)

print("=" * 80)
print("📊 EXPLORACIÓN DE DATOS - df_fraudes.parquet")
print("=" * 80)
print(f"📂 Archivo: {FILE_PATH}")
print()

try:
    # Cargar el archivo
    print("📥 Cargando archivo parquet...")
    if STORAGE_OPTIONS:
        df = pd.read_parquet(FILE_PATH, storage_options=STORAGE_OPTIONS)
    else:
        df = pd.read_parquet(FILE_PATH)
    print("✅ Archivo cargado exitosamente")
    print()
    
    # Información básica
    print("=" * 80)
    print("📋 INFORMACIÓN BÁSICA")
    print("=" * 80)
    print(f"📊 Dimensiones del dataset:")
    print(f"   - Filas: {df.shape[0]:,}")
    print(f"   - Columnas: {df.shape[1]}")
    print()
    
    # Listar todas las columnas
    print("=" * 80)
    print("📝 LISTADO DE COLUMNAS")
    print("=" * 80)
    print(f"Total de columnas: {len(df.columns)}\n")
    
    for i, col in enumerate(df.columns, 1):
        dtype = df[col].dtype
        nulls = df[col].isnull().sum()
        null_pct = (nulls / len(df)) * 100
        print(f"{i:3d}. {col:40s} | Tipo: {str(dtype):12s} | Nulos: {nulls:6d} ({null_pct:5.2f}%)")
    
    print()
    
    # Mostrar las primeras 20 filas
    print("=" * 80)
    print("👀 PRIMERAS 20 FILAS")
    print("=" * 80)
    print()
    print(df.head(20).to_string())
    print()
    
    # Información de tipos de datos
    print("=" * 80)
    print("📊 RESUMEN DE TIPOS DE DATOS")
    print("=" * 80)
    dtype_counts = df.dtypes.value_counts()
    for dtype, count in dtype_counts.items():
        print(f"   - {dtype}: {count} columnas")
    print()
    
    # Estadísticas descriptivas básicas
    print("=" * 80)
    print("📈 ESTADÍSTICAS DESCRIPTIVAS (NUMÉRICAS)")
    print("=" * 80)
    print()
    numeric_cols = df.select_dtypes(include=['int64', 'float64', 'int32', 'float32']).columns
    if len(numeric_cols) > 0:
        print(df[numeric_cols].describe().to_string())
    else:
        print("No hay columnas numéricas en el dataset")
    print()
    
    # Resumen de valores nulos
    print("=" * 80)
    print("⚠️  RESUMEN DE VALORES NULOS")
    print("=" * 80)
    null_counts = df.isnull().sum()
    null_summary = null_counts[null_counts > 0].sort_values(ascending=False)
    
    if len(null_summary) > 0:
        print(f"\nColumnas con valores nulos: {len(null_summary)}\n")
        for col, count in null_summary.items():
            pct = (count / len(df)) * 100
            print(f"   - {col:40s}: {count:6d} ({pct:5.2f}%)")
    else:
        print("\n✅ No hay valores nulos en el dataset")
    
    print()
    print("=" * 80)
    print("✅ Exploración completada")
    print("=" * 80)
    
except FileNotFoundError:
    print(f"❌ Error: No se encontró el archivo en la ruta especificada")
    print(f"   Ruta: {FILE_PATH}")
    print()
    print("Verifica que:")
    print("1. El archivo existe en la carpeta Downloads")
    print("2. El nombre del archivo es exactamente: df_fraudes.parquet")
    sys.exit(1)
    
except Exception as e:
    print(f"❌ Error al leer el archivo: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
