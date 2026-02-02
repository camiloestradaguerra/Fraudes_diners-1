"""Fraud prediction router."""

import time
import uuid
from datetime import datetime
from contextlib import asynccontextmanager
from fastapi import APIRouter, HTTPException

from endpoint_prototipo.schemas import FraudPredictionRequest, FraudPredictionResponse, ModelMeta

# Global variables for model (loaded once at startup)
MODEL = None
DEVICE = None


def load_model():
    """Load fraud detection model at startup."""
    global MODEL, DEVICE
    
    # TODO: Implement actual model loading
    # This is a placeholder for the fraud detection model
    # You can load your trained model here using joblib, torch, or other frameworks
    MODEL = "fraud_model_loaded"  # Placeholder
    print("[FRAUD_PREDICTION] Model loaded successfully")


@asynccontextmanager
async def lifespan(app):
    """Application lifespan context manager."""
    # Startup
    load_model()
    yield
    # Shutdown
    print("[FRAUD_PREDICTION] Application shutting down")


router = APIRouter(prefix="/fraud", tags=["fraud"])


@router.post("/predict", response_model=FraudPredictionResponse)
async def predict_fraud(request: FraudPredictionRequest):
    """
    Predict fraud probability for a transaction.
    
    Args:
        request: FraudPredictionRequest containing transaction details
        
    Returns:
        FraudPredictionResponse with fraud prediction score (0-999)
    """
    
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    # Start timing inference
    start_time = time.perf_counter()
    
    # Generate unique request ID
    request_id = f"REQ-{str(uuid.uuid4())[:5].upper()}"
    
    try:
        # TODO: Replace this with actual model inference
        # Example: score = MODEL.predict(prepare_features(request))
        
        # Placeholder: simple mock prediction based on transaction amount
        # In production, this would call your actual fraud detection model
        base_score = min(999, max(0, request.monto * 2))  # Mock calculation
        
        # Add random variation based on other features
        if request.edad < 25 or request.edad > 70:
            base_score *= 1.1
        
        # Normalize to 0-999 range
        fraud_score = min(999, max(0, base_score))
        
        # Calculate inference time
        end_time = time.perf_counter()
        latency_ms = (end_time - start_time) * 1000
        
        # Build response with the requested JSON structure
        return FraudPredictionResponse(
            schema_version="1.0",
            request_id=request_id,
            ml_score_0_999=fraud_score,
            model_meta=ModelMeta(
                name="fraud_model_prod",
                version="2024.11",
                provider="ExternalVendor"
            ),
            latency_ms=latency_ms
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")


@router.post("/batch-predict")
async def batch_predict_fraud(requests: list[FraudPredictionRequest]):
    """
    Predict fraud probability for multiple transactions (batch).
    
    Args:
        requests: List of FraudPredictionRequest objects
        
    Returns:
        List of FraudPredictionResponse objects
    """
    
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    predictions = []
    for request in requests:
        prediction = await predict_fraud(request)
        predictions.append(prediction)
    
    return predictions
