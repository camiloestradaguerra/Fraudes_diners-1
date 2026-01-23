#!/usr/bin/env python3
"""
Script de verificación para comprobar acceso al archivo en S3
"""

import s3fs
import pandas as pd

# Configuración
AWS_REGION = 'us-east-1'
BUCKET = 'dcelip-dev-brz-fraud-s3'
FILE_PATH = 'modelo_fraude/input/raw/df_fraudes.parquet'
S3_PATH = f's3://{BUCKET}/{FILE_PATH}'

print("🔍 Verificando acceso a S3...")
print(f"📍 Bucket: {BUCKET}")
print(f"📂 Archivo: {FILE_PATH}")
print(f"🔗 Ruta completa: {S3_PATH}")
print()

try:
    # Inicializar S3FileSystem
    fs = s3fs.S3FileSystem(client_kwargs={'region_name': AWS_REGION})
    
    # Verificar si el archivo existe
    print("⏳ Verificando existencia del archivo...")
    file_path_clean = S3_PATH.replace('s3://', '')
    
    if fs.exists(file_path_clean):
        print("✅ Archivo encontrado en S3!")
        
        # Obtener información del archivo
        file_info = fs.info(file_path_clean)
        file_size_mb = file_info['Size'] / (1024 * 1024)
        print(f"📊 Tamaño: {file_size_mb:.2f} MB")
        print()
        
        # Intentar leer las primeras filas
        print("⏳ Leyendo primeras filas del archivo...")
        df = pd.read_parquet(S3_PATH, storage_options={'use_ssl': True})
        
        print(f"✅ Archivo cargado exitosamente!")
        print(f"📊 Forma del dataset: {df.shape}")
        print(f"   - Filas: {df.shape[0]:,}")
        print(f"   - Columnas: {df.shape[1]}")
        print()
        print("📋 Columnas disponibles:")
        for i, col in enumerate(df.columns, 1):
            print(f"   {i}. {col}")
        print()
        print("✅ TODO FUNCIONA CORRECTAMENTE! Puedes usar el notebook eda.ipynb")
        
    else:
        print("❌ Archivo NO encontrado en S3")
        print()
        print("Posibles causas:")
        print("1. La ruta del archivo es incorrecta")
        print("2. No tienes permisos de lectura en el bucket")
        print("3. El archivo aún no ha sido creado")
        print()
        print("Intentando listar contenido del bucket...")
        try:
            files = fs.ls(f"{BUCKET}/source=teradata/modelo_fraude/input/raw/")
            print(f"\nArchivos encontrados en la carpeta:")
            for f in files:
                print(f"  - {f}")
        except Exception as e:
            print(f"Error listando bucket: {e}")
            
except Exception as e:
    print(f"❌ Error: {e}")
    print()
    print("Verifica:")
    print("1. Credenciales AWS configuradas: aws sts get-caller-identity")
    print("2. Permisos de acceso al bucket")
    print("3. La región configurada es correcta (us-east-1)")
