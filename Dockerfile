# ETAPA 1: Construcción
FROM public.ecr.aws/docker/library/python:3.11-slim AS builder

WORKDIR /build

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements y pre-compilar
COPY endpoint_prototipo/requirements.txt .
RUN pip install --user --no-cache-dir --compile -r requirements.txt

# ETAPA 2: Runtime (Imagen Final)
FROM public.ecr.aws/docker/library/python:3.11-slim

WORKDIR /app

# Instalar librerías de ejecución
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copiar dependencias del builder
COPY --from=builder /root/.local /root/.local

# Copiar TODO el código del proyecto
COPY . .

# Configuración de entorno
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Puerto SageMaker
EXPOSE 8080

# --- EL CAMBIO CLAVE ESTÁ AQUÍ ---
# Usamos el modo "Shell" (sin corchetes) para que ignore el argumento 'serve' de SageMaker
ENTRYPOINT uvicorn endpoint_prototipo.main:app --host 0.0.0.0 --port 8080

LABEL maintainer="Data Science Team" version="2.0"