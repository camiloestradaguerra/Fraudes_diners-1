# Stage 1: Builder
# Este stage construye las dependencias necesarias
FROM public.ecr.aws/docker/library/python:3.11-slim as builder

WORKDIR /build

# Instalar compiladores y dependencias del sistema necesarias para Torch
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY endpoint_prototipo/requirements.txt .

# Pre-compilar wheels (acelera runtime)
RUN pip install --user --no-cache-dir --compile -r requirements.txt

# Stage 2: Runtime
# Imagen final más limpia y pequeña
FROM public.ecr.aws/docker/library/python:3.11-slim

WORKDIR /app

# Instalar solo dependencias de runtime (no compiladores)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copiar dependencias precompiladas del builder
COPY --from=builder /root/.local /root/.local

# Copiar código de la aplicación
COPY . .

# Configurar PATH para usar las dependencias del usuario
ENV PATH=/root/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Verificar que FastAPI/Uvicorn están disponibles
RUN python -c "import fastapi; import uvicorn; print(f'FastAPI: {fastapi.__version__}')" || exit 1

# Copiar script de entrada para SageMaker
COPY serve /usr/local/bin/serve
RUN chmod +x /usr/local/bin/serve

# Exponer puerto (SageMaker usa 8080 por defecto, pero también aceptamos 8000)
EXPOSE 8080

# ENTRYPOINT para SageMaker - ejecuta el script serve
ENTRYPOINT ["serve"]

# Metadata (útil para debugging)
LABEL maintainer="Data Science Team" \
      version="1.0" \
      description="Fraud Detection API using FastAPI and PyTorch"
