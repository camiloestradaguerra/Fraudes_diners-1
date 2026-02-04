"""
Fraud Detection API - Main Application Module.

FastAPI-based REST API server for real-time fraud detection predictions.
Handles multiple endpoints including health checks and SageMaker integration.
"""

from contextlib import asynccontextmanager
import base64
import json
import logging
from typing import Any, Dict

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from endpoint_prototipo.routers import health, fraud_prediction
from endpoint_prototipo.schemas import FraudPredictionRequest

logging.basicConfig(level=logging.INFO)
logger: logging.Logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> Any:
    """
    Application lifespan context manager.
    
    Handles startup and shutdown events for the FastAPI application.
    Loads the fraud detection model on startup.
    
    Args:
        app: FastAPI application instance
        
    Yields:
        None during application runtime
    """
    fraud_prediction.load_model()
    yield
    logger.info("[MAIN] Application shutdown")

app: FastAPI = FastAPI(
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

app.include_router(health.router, tags=["health"])
app.include_router(fraud_prediction.router, tags=["fraud_detection"])

@app.get("/", tags=["root"])
async def root() -> Dict[str, str]:
    """Get API information."""
    return {"message": "Fraud Detection API", "version": "2024.11"}


@app.get("/ping", tags=["health"])
async def sagemaker_ping() -> Dict[str, str]:
    """SageMaker health check endpoint."""
    return {"status": "ok"}


@app.post("/invocations", tags=["sagemaker"])
async def sagemaker_invocations(request: Request) -> Dict[str, Any]:
    """
    SageMaker invocations endpoint.
    
    Handles requests from SageMaker Runtime. SageMaker may send the request body
    as plain JSON or as base64-encoded JSON depending on the Content-Type header.
    This endpoint handles both formats transparently.
    
    Args:
        request: FastAPI request object containing the transaction data
        
    Returns:
        dict: Fraud prediction response with score and metadata
    """
    try:
        body_bytes: bytes = await request.body()
        body_str: str = body_bytes.decode('utf-8') if isinstance(body_bytes, bytes) else body_bytes
        
        logger.info(f"[INVOCATIONS] Raw body length: {len(body_str)}")
        
        data: Dict[str, Any]
        try:
            data = json.loads(body_str)
            logger.info("[INVOCATIONS] Parsed as JSON directly")
        except json.JSONDecodeError:
            try:
                decoded_bytes: bytes = base64.b64decode(body_str)
                body_str = decoded_bytes.decode('utf-8')
                data = json.loads(body_str)
                logger.info("[INVOCATIONS] Parsed from base64")
            except Exception as decode_error:
                logger.error(f"[INVOCATIONS] Decoding failed: {str(decode_error)}")
                return {"error": f"Invalid request format: {str(decode_error)}"}
        
        prediction_request: FraudPredictionRequest = FraudPredictionRequest(**data)
        result: Dict[str, Any] = await fraud_prediction.predict_fraud(prediction_request)
        
        logger.info(f"[INVOCATIONS] Prediction completed: score={result.get('ml_score_0_999')}")
        return result
        
    except Exception as e:
        logger.error(f"[INVOCATIONS] Exception: {str(e)}")
        return {"error": str(e)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)