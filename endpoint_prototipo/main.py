"""
FastAPI Application for Fraud Detection

This API provides endpoints for:
- Health checks
- Real-time fraud prediction on transactions

The API implements best practices:
- CORS middleware for cross-origin requests
- Structured logging and request tracking
- Pydantic validation
- Router-based organization
- Proper error handling
- Inference latency tracking

Author: Data Science Team
Date: 2025-01-23

AWS SageMaker Deployment:
To deploy on SageMaker Endpoint, create a custom inference handler:

from sagemaker_inference import content_types, decoder, default_inference_handler, encoder
class ModelHandler(default_inference_handler.DefaultInferenceHandler):
    def default_model_fn(self, model_dir):
        # Load fraud detection model from model_dir
        pass
    
    def default_input_fn(self, input_data, content_type):
        # Parse transaction data
        pass
    
    def default_predict_fn(self, data, model):
        # Run fraud prediction inference
        pass
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from endpoint_prototipo.routers import health, fraud_prediction

# Create lifespan context
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan."""
    # Startup: Load model
    fraud_prediction.load_model()
    yield
    # Shutdown
    print("[MAIN] Application shutdown")

# Initialize FastAPI app with lifespan
app = FastAPI(
    title="Fraud Detection API",
    description="Real-time fraud detection model for transaction prediction",
    version="2024.11",
    contact={
        "name": "Data Science Team",
        "email": "contact@example.com"
    },
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router)
app.include_router(fraud_prediction.router)


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "Fraud Detection API",
        "version": "2024.11",
        "docs": "/docs"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
