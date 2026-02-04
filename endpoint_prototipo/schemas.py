"""
Pydantic schemas for API request/response validation.

Defines data models for fraud detection API endpoints with type hints
and validation rules for transaction data and predictions.
"""

from pydantic import BaseModel, ConfigDict, Field


class FraudPredictionRequest(BaseModel):
    """
    Request schema for fraud prediction.
    
    Validates incoming transaction data before ML model inference.
    """
    
    model_config: ConfigDict = ConfigDict(
        json_schema_extra={
            "example": {
                "transaction_id": "TRX123456",
                "monto": 150.50,
                "edad": 35,
                "ciudad": "Quito",
                "establecimiento": "RestaurantXYZ",
                "especialidad": "RESTAURANTES"
            }
        }
    )
    
    transaction_id: str = Field(..., description="Unique transaction identifier")
    monto: float = Field(..., gt=0, description="Transaction amount in local currency")
    edad: int = Field(..., ge=18, le=120, description="Customer age (18-120 years)")
    ciudad: str = Field(..., description="City where transaction occurred")
    establecimiento: str = Field(..., description="Merchant or establishment name")
    especialidad: str = Field(default="GENERAL", description="Transaction specialty category")


class ModelMeta(BaseModel):
    """
    Model metadata container.
    
    Tracks model information and version details for audit and debugging.
    """
    
    name: str = Field(..., description="Model name identifier")
    version: str = Field(..., description="Model version string")
    provider: str = Field(..., description="Model provider organization")


class FraudPredictionResponse(BaseModel):
    """
    Response schema for fraud prediction.
    
    Contains fraud detection score, model metadata, and inference metrics.
    """
    
    model_config: ConfigDict = ConfigDict(protected_namespaces=())
    
    schema_version: str = Field(..., description="API schema version")
    request_id: str = Field(..., description="Unique request identifier")
    ml_score_0_999: float = Field(
        ..., 
        ge=0, 
        le=999, 
        description="Fraud risk score from 0 (low risk) to 999 (high risk)"
    )
    model_meta: ModelMeta = Field(..., description="ML model metadata")
    latency_ms: float = Field(..., ge=0, description="Inference latency in milliseconds")


class HealthResponse(BaseModel):
    """
    Health check response.
    
    Indicates API and model availability status.
    """
    
    model_config: ConfigDict = ConfigDict(protected_namespaces=())
    
    status: str = Field(..., description="API status (ok/error)")
    model_loaded: bool = Field(..., description="Whether ML model is loaded in memory")
    version: str = Field(..., description="API version")
