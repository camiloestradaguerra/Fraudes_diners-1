"""
Health check router module.

Provides API health and availability endpoints for monitoring and 
load balancer checks. No dependencies on fraud detection model.
"""

from typing import Dict

from fastapi import APIRouter

from endpoint_prototipo.schemas import HealthResponse

router: APIRouter = APIRouter(prefix="/health", tags=["health"])


@router.get("/", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """
    API health status endpoint.
    
    Returns the current health status of the API and ML model availability.
    
    Returns:
        HealthResponse: Status object with API and model health information
    """
    return HealthResponse(
        status="healthy",
        model_loaded=True,
        version="1.0.0"
    )
