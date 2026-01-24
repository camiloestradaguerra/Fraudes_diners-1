"""Pydantic schemas for API request/response validation."""

from pydantic import BaseModel, Field


class FraudPredictionRequest(BaseModel):
    """Request schema for fraud prediction."""
    
    transaction_id: str = Field(..., description="Transaction ID")
    monto: float = Field(..., gt=0, description="Transaction amount")
    edad: int = Field(..., ge=18, le=120, description="Customer age")
    ciudad: str = Field(..., description="City where transaction occurred")
    establecimiento: str = Field(..., description="Merchant/Establishment")
    especialidad: str = Field(default="GENERAL", description="Specialty type")
    
    class Config:
        json_schema_extra = {
            "example": {
                "transaction_id": "TRX123456",
                "monto": 150.50,
                "edad": 35,
                "ciudad": "Quito",
                "establecimiento": "RestaurantXYZ",
                "especialidad": "RESTAURANTES"
            }
        }


class ModelMeta(BaseModel):
    """Model metadata."""
    
    name: str = Field(..., description="Model name")
    version: str = Field(..., description="Model version")
    provider: str = Field(..., description="Model provider")


class FraudPredictionResponse(BaseModel):
    """Response schema for fraud prediction."""
    
    schema_version: str = Field(..., description="API schema version")
    request_id: str = Field(..., description="Request identifier")
    ml_score_0_999: float = Field(..., ge=0, le=999, description="Fraud risk score (0-999)")
    model_meta: ModelMeta = Field(..., description="Model metadata")
    latency_ms: float = Field(..., ge=0, description="Inference latency in milliseconds")


class HealthResponse(BaseModel):
    """Health check response."""
    
    status: str
    model_loaded: bool
    version: str
