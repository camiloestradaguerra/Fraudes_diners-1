import sys
import boto3
import pandas as pd
import s3fs
from loguru import logger

# Configuración básica de logger
logger.remove()
logger.add(sys.stderr, format="<green>{time:HH:mm:ss}</green> | <level>{message}</level>", level="INFO")

class FraudDataManager:
    def __init__(self, region: str = 'us-east-1'):
        self.aws_region = region
        self.fs = s3fs.S3FileSystem(client_kwargs={'region_name': self.aws_region})

    def load_all_files(self, bucket: str, prefix: str) -> pd.DataFrame:
        """Carga y concatena TODOS los parquets de la ruta dada."""
        path_s3 = f"{bucket}/{prefix}"
        
        # Listar todos los archivos .parquet
        try:
            files = self.fs.ls(path_s3)
            parquet_files = [f"s3://{f}" for f in files if f.endswith('.parquet')]
            
            logger.info(f"Archivos encontrados: {len(parquet_files)}")
            
            if not parquet_files:
                logger.warning("No se encontraron archivos .parquet.")
                return pd.DataFrame()

            # Cargar TODOS los archivos (sin límite [0:5])
            df_list = []
            for i, file in enumerate(parquet_files):
                logger.info(f"Cargando ({i+1}/{len(parquet_files)}): {file}")
                df = pd.read_parquet(file, storage_options={'use_ssl': True})
                df_list.append(df)

            # Concatenar
            if df_list:
                df_concat = pd.concat(df_list, ignore_index=True)
                logger.success(f"Concatenación completada. Total registros: {df_concat.shape[0]}")
                return df_concat
            else:
                return pd.DataFrame()
                
        except Exception as e:
            logger.error(f"Error leyendo archivos: {e}")
            raise

    def save_exact_file(self, df: pd.DataFrame, bucket: str, path_destino: str, nombre_archivo: str) -> None:
        """Guarda el DF en S3 con el nombre exacto (sin timestamp)."""
        ruta_completa = f"s3://{bucket}/{path_destino}{nombre_archivo}"
        
        try:
            logger.info(f"Guardando archivo en: {ruta_completa} ...")
            with self.fs.open(ruta_completa, 'wb') as f:
                df.to_parquet(f, index=False)
            logger.success(f"Archivo guardado exitosamente: {nombre_archivo}")
        except Exception as e:
            logger.error(f"Error guardando en S3: {e}")
            raise

def main():
    # --- CONFIGURACIÓN ---
    BUCKET = "dcelip-dev-brz-fraud-s3"
    INPUT_PREFIX = "source=teradata/"  # Ruta origen
    OUTPUT_PATH = "modelo_fraude/input/raw/"   # Ruta destino dentro del bucket
    OUTPUT_FILENAME = "df_fraudes.parquet"     # Nombre final solicitado

    manager = FraudDataManager()

    # 1. Cargar y concatenar
    df_fraudes = manager.load_all_files(BUCKET, INPUT_PREFIX)

    # 2. Guardar si hay datos
    if not df_fraudes.empty:
        manager.save_exact_file(df_fraudes, BUCKET, OUTPUT_PATH, OUTPUT_FILENAME)
    else:
        logger.warning("El DataFrame está vacío, no se guardó ningún archivo.")

if __name__ == "__main__":
    main()