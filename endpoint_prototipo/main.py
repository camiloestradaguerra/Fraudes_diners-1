from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from endpoint_prototipo.routers import health, fraud_prediction
# CORRECCIÓN 1: Importar el esquema necesario para el endpoint de invocaciones
from endpoint_prototipo.schemas import FraudPredictionRequest

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan."""
    fraud_prediction.load_model()
    yield
    print("[MAIN] Application shutdown")

app = FastAPI(
    title="Fraud Detection API",
    description="Real-time fraud detection model for transaction prediction",
    version="2024.11",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(fraud_prediction.router)

@app.get("/")
async def root():
    return {"message": "Fraud Detection API", "version": "2024.11"}

@app.get("/ping")
async def sagemaker_ping():
    return {"status": "ok"}

@app.post("/invocations")
async def sagemaker_invocations(request: FraudPredictionRequest):
    # CORRECCIÓN 2: El nombre correcto de la función en fraud_prediction.py es predict_fraud
    return await fraud_prediction.predict_fraud(request)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)