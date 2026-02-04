# Fraud Detection API - Technical Architecture

**Version:** 2024.11  
**Date:** February 4, 2026  
**Status:** Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Components](#components)
4. [Deployment Infrastructure](#deployment-infrastructure)
5. [API Endpoints](#api-endpoints)
6. [Integration with SageMaker](#integration-with-sagemaker)
7. [Data Flow](#data-flow)
8. [Configuration](#configuration)
9. [Monitoring and Logging](#monitoring-and-logging)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The Fraud Detection API is a production-grade machine learning inference service deployed on AWS infrastructure. It provides real-time fraud detection predictions for Diners Club transactions using a trained ML model hosted on AWS SageMaker.

**Key Characteristics:**
- Real-time transaction fraud scoring (0-999 scale)
- RESTful API with comprehensive error handling
- Containerized deployment via Docker and ECR
- Fully automated infrastructure as code (Terraform)
- SageMaker integration for scalable model inference
- API Gateway for public endpoint exposure
- CloudWatch logging for observability

**Technology Stack:**
- **Runtime:** Python 3.11+
- **Framework:** FastAPI
- **Containerization:** Docker
- **Infrastructure:** Terraform
- **ML Platform:** AWS SageMaker
- **API Gateway:** AWS API Gateway
- **Container Registry:** AWS ECR
- **CI/CD:** AWS CodeBuild
- **Region:** us-east-1

---

## System Architecture

```
┌─────────────────┐
│  Client Request │
└────────┬────────┘
         │
         v
┌─────────────────────────────────────────┐
│  AWS API Gateway (REST API)             │
│  - https://we9wpnfvqa.execute-api...    │
│  - POST /predict                        │
│  - Request Template: $input.body        │
└────────┬────────────────────────────────┘
         │
         v
┌─────────────────────────────────────────┐
│  AWS SageMaker Endpoint                 │
│  - Fraudes-Diners-Prod-Endpoint         │
│  - Instance: ml.m5.large                │
│  - Status: InService                    │
└────────┬────────────────────────────────┘
         │
         v
┌─────────────────────────────────────────┐
│  Docker Container (ECR Image)           │
│  - fraud-detection-api:latest           │
│  - FastAPI Application                  │
│  - Port: 8000                           │
└────────┬────────────────────────────────┘
         │
         v
┌─────────────────────────────────────────┐
│  Python Application                     │
│  - Main: main.py                        │
│  - Schemas: schemas.py                  │
│  - Routers: fraud_prediction.py         │
│  - Health: health.py                    │
└─────────────────────────────────────────┘
```

---

## Components

### 1. API Application (FastAPI)

**Location:** `endpoint_prototipo/main.py`

Core application providing three main endpoints:
- `GET /` - API information
- `GET /ping` - Health check (SageMaker compatible)
- `POST /invocations` - Transaction fraud prediction (SageMaker entry point)
- `GET /health/` - Detailed health status

**Features:**
- CORS middleware enabled for cross-origin requests
- Request body handling for both JSON and base64-encoded formats
- Comprehensive error logging
- Application lifespan management

### 2. Data Schemas (Pydantic)

**Location:** `endpoint_prototipo/schemas.py`

Type-safe data validation:

```python
FraudPredictionRequest
├── transaction_id: str
├── monto: float (amount > 0)
├── edad: int (age 18-120)
├── ciudad: str
├── establecimiento: str
└── especialidad: str (default: "GENERAL")

FraudPredictionResponse
├── schema_version: str
├── request_id: str
├── ml_score_0_999: float (0-999 scale)
├── model_meta: ModelMeta
│   ├── name: str
│   ├── version: str
│   └── provider: str
└── latency_ms: float
```

### 3. Fraud Prediction Router

**Location:** `endpoint_prototipo/routers/fraud_prediction.py`

Handles ML inference requests:

**Endpoints:**
- `POST /fraud/predict` - Single transaction prediction
- `POST /fraud/batch-predict` - Batch predictions

**Processing:**
1. Model availability check
2. Request timing start
3. Unique request ID generation
4. ML model inference (placeholder/production)
5. Fraud score calculation (0-999)
6. Response composition with metadata

### 4. Health Check Router

**Location:** `endpoint_prototipo/routers/health.py`

Monitoring endpoint:
- `GET /health/` - Returns health status with model loaded state

---

## Deployment Infrastructure

### AWS Components

#### 1. ECR Repository (Elastic Container Registry)

**Resource:** `aws_ecr_repository.fraud_api`

- **Name:** fraud-detection-api
- **Purpose:** Docker image storage
- **Lifecycle:** `force_delete = true` enables clean removal
- **Image Tags:** 
  - `latest` (current production)
  - Commit hash (version tracking)

#### 2. CodeBuild Project

**Resource:** `aws_codebuild_project.fraud_builder`

- **Name:** fraudes-docker-build-prod
- **Buildspec:** `buildspec.yml`
- **Trigger:** Automatic via Terraform null_resource
- **Process:**
  1. Build Docker image from Dockerfile
  2. Tag with `latest` and commit hash
  3. Push to ECR repository

#### 3. SageMaker Model

**Resource:** `aws_sagemaker_model.fraudes`

- **Name:** fraudes-model-prod-2026-02-04
- **Container Image:** ECR image URI (fraud-detection-api:latest)
- **Framework:** Generic container model
- **Entry Point:** `/invocations` endpoint in application
- **Environment:** Production

#### 4. SageMaker Endpoint

**Resource:** `aws_sagemaker_endpoint.fraudes`

- **Name:** Fraudes-Diners-Prod-Endpoint
- **Model:** fraudes-model-prod-2026-02-04
- **Instance Type:** ml.m5.large
- **Initial Instances:** 1
- **Status:** InService
- **Inference:** Real-time predictions

#### 5. API Gateway REST API

**Resource:** `aws_api_gateway_rest_api.fraud_api`

- **API ID:** we9wpnfvqa
- **Endpoint URL:** https://we9wpnfvqa.execute-api.us-east-1.amazonaws.com/prod/predict
- **Stage:** prod
- **Method:** POST /predict

**Integration:**
- Type: AWS Service (SageMaker Runtime)
- Integration URI: `arn:aws:apigateway:us-east-1:runtime.sagemaker:path/endpoints/Fraudes-Diners-Prod-Endpoint/invocations`
- Request Template: `$input.body` (sends JSON body directly)
- Response Template: `$input.json('$')` (passes response as-is)

#### 6. IAM Roles and Policies

**SageMaker Execution Role:** `fraudes-sagemaker-role-prod`
- ECR pull permissions
- S3 access for artifacts
- CloudWatch logging

**API Gateway Service Role:** `apigateway-sagemaker-fraudes-prod-prod`
- SageMaker Runtime invoke permissions
- CloudWatch logging

**CodeBuild Role:** `fraudes-codebuild-role-prod`
- ECR push/pull permissions
- CloudWatch logs write

#### 7. S3 Bucket

**Bucket:** fraudes-sagemaker-761951921633-us-east-1
- SageMaker artifacts storage
- Model artifacts
- CloudWatch logs

---

## API Endpoints

### 1. Root Endpoint

```http
GET /
```

**Response:**
```json
{
  "message": "Fraud Detection API",
  "version": "2024.11"
}
```

### 2. Ping (Health Check)

```http
GET /ping
```

**Response:**
```json
{
  "status": "ok"
}
```

**Purpose:** SageMaker container health verification

### 3. Health Status

```http
GET /health/
```

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "version": "1.0.0"
}
```

### 4. Fraud Prediction (Single)

```http
POST /fraud/predict
Content-Type: application/json

{
  "transaction_id": "TRX123456",
  "monto": 150.50,
  "edad": 35,
  "ciudad": "Quito",
  "establecimiento": "RestaurantXYZ",
  "especialidad": "RESTAURANTES"
}
```

**Response (200 OK):**
```json
{
  "schema_version": "1.0",
  "request_id": "REQ-1CC3E",
  "ml_score_0_999": 3.0,
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": 32.22
}
```

### 5. Fraud Prediction (Batch)

```http
POST /fraud/batch-predict
Content-Type: application/json

[
  { "transaction_id": "TRX001", ... },
  { "transaction_id": "TRX002", ... }
]
```

**Response:** Array of FraudPredictionResponse objects

### 6. SageMaker Invocations

```http
POST /invocations
```

**Purpose:** Internal SageMaker Runtime endpoint  
**Input:** JSON or base64-encoded JSON from SageMaker Runtime  
**Output:** Fraud prediction response

---

## Integration with SageMaker

### Request Flow

1. **API Gateway receives POST request**
   - Endpoint: `/predict`
   - Body contains JSON transaction data

2. **API Gateway invokes SageMaker Endpoint**
   - Integration: Direct AWS integration
   - Template: `$input.body` (passes JSON body)
   - Target: SageMaker Runtime InvokeEndpoint API

3. **SageMaker Runtime forwards to endpoint**
   - Container: ECR image running in SageMaker
   - Endpoint: `/invocations` (hardcoded by SageMaker)

4. **Application processes request**
   - Receives raw body (may be base64 or JSON)
   - Decodes and validates request
   - Creates FraudPredictionRequest object
   - Calls fraud_prediction.predict_fraud()

5. **Response returned to API Gateway**
   - Template: `$input.json('$')`
   - Status: 200 OK
   - Body: Fraud prediction response

### Key Considerations

**Base64 Encoding:** SageMaker Runtime may wrap request bodies in base64 depending on Content-Type headers. The application handles both formats transparently in the `/invocations` endpoint.

**Request Format Handling:**
```python
@app.post("/invocations")
async def sagemaker_invocations(request: Request):
    body_str = await request.body()
    
    # Try direct JSON parsing first
    try:
        data = json.loads(body_str)
    except json.JSONDecodeError:
        # Fall back to base64 decoding
        decoded_bytes = base64.b64decode(body_str)
        data = json.loads(decoded_bytes.decode('utf-8'))
    
    # Process prediction...
```

---

## Data Flow

### Transaction Fraud Detection Flow

```
┌──────────────────────────────────────────────────────────────┐
│ 1. Client sends transaction data                             │
│    POST /predict                                             │
│    {transaction_id, monto, edad, ciudad, ...}               │
└──────────────┬───────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────┐
│ 2. API Gateway receives request                              │
│    - Validates HTTP method and path                          │
│    - Applies request template: $input.body                   │
│    - Passes JSON body to SageMaker                           │
└──────────────┬───────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────┐
│ 3. SageMaker endpoint receives invocation                     │
│    - Routes to container /invocations                        │
│    - May wrap in base64 encoding                             │
└──────────────┬───────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────┐
│ 4. Application processes request                             │
│    - Decodes request body (JSON or base64)                   │
│    - Validates with Pydantic schema                          │
│    - Creates FraudPredictionRequest object                   │
└──────────────┬───────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────┐
│ 5. ML inference                                              │
│    - Generate unique request ID                              │
│    - Start timing clock                                      │
│    - Call fraud detection model                              │
│    - Calculate risk score (0-999)                            │
│    - Record inference latency                                │
└──────────────┬───────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────┐
│ 6. Response composition                                       │
│    {                                                          │
│      "schema_version": "1.0",                               │
│      "request_id": "REQ-XXXXX",                             │
│      "ml_score_0_999": 45.2,                                │
│      "model_meta": {...},                                   │
│      "latency_ms": 32.2                                     │
│    }                                                          │
└──────────────┬───────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────┐
│ 7. Response returned to API Gateway                           │
│    - Apply response template: $input.json('$')               │
│    - Status: 200 OK                                          │
└──────────────┬───────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────┐
│ 8. API Gateway returns to client                             │
│    - HTTP 200 OK                                             │
│    - JSON response body                                      │
└──────────────────────────────────────────────────────────────┘
```

---

## Configuration

### Terraform Variables

**File:** `terraform/terraform.tfvars`

```hcl
# AWS Configuration
aws_region              = "us-east-1"
project_name            = "fraudes"
environment             = "prod"

# Feature Flags
create_sagemaker              = true
create_sagemaker_endpoint     = true
create_api_gateway            = true

# SageMaker Configuration
instance_type           = "ml.m5.large"
initial_instance_count  = 1

# API Configuration
api_endpoint_name       = "predict"
```

### Environment Variables

Set in `endpoint_prototipo/main.py` or Dockerfile:

```bash
LOG_LEVEL=INFO
PYTHONUNBUFFERED=1
```

### Docker Build Process

**Buildspec:** `buildspec.yml`

1. Install Python dependencies from `requirements.txt`
2. Build image with name `fraud-detection-api`
3. Tag with `latest` and commit hash
4. Push to ECR repository

---

## Monitoring and Logging

### CloudWatch Log Groups

| Component | Log Group |
|-----------|-----------|
| CodeBuild | `/aws/codebuild/fraudes-docker-build-prod` |
| SageMaker | `/aws/sagemaker/fraudes-model-prod` |
| API Gateway | `/aws/apigateway/we9wpnfvqa` |

### Application Logging

**Logger:** Python logging module

**Format:** `[MODULE] Message`

**Levels:**
- `INFO` - General operations
- `ERROR` - Error conditions
- `WARNING` - Potential issues

**Examples:**
```
[INVOCATIONS] Raw body length: 245
[INVOCATIONS] Parsed as JSON directly
[INVOCATIONS] Prediction completed: score=45.2
```

### Metrics to Monitor

- **Endpoint Status:** InService / Creating / Failed
- **Response Latency:** latency_ms in response
- **Error Rate:** 5xx responses from API Gateway
- **Model Load Time:** Application startup time
- **Prediction Distribution:** Score ranges for fraud vs legitimate

---

## Troubleshooting

### API Gateway Errors

**502 Bad Gateway**
- Check SageMaker endpoint status: `InService`
- Verify endpoint name matches in integration URI
- Check CloudWatch logs for API Gateway

**422 Unprocessable Entity**
- Validate request JSON schema
- Ensure all required fields present
- Check Content-Type header: `application/json`

### SageMaker Endpoint Issues

**Endpoint Status: Creating**
- Wait for endpoint to initialize
- Typical time: 5-10 minutes
- Monitor AWS Console

**Endpoint Status: Failed**
- Check CloudWatch logs for errors
- Verify Docker image exists in ECR
- Check IAM role permissions

### Application Errors

**Model not loaded (503)**
- Verify model loads in application startup
- Check CloudWatch application logs
- Restart endpoint

**Base64 decoding error**
- Verify request format
- Check Content-Type header
- Review raw request body in logs

### Deployment Issues

**Terraform Apply Fails**
- Check AWS credentials
- Verify IAM permissions
- Review Terraform output for errors

**CodeBuild Build Fails**
- Check buildspec.yml syntax
- Verify Dockerfile exists
- Review CodeBuild logs in CloudWatch

---

## Production Deployment Checklist

- [x] Terraform infrastructure created and tested
- [x] ECR image built and pushed successfully
- [x] SageMaker Model created with correct image
- [x] SageMaker Endpoint in InService status
- [x] API Gateway configured and deployed
- [x] End-to-end API testing completed
- [x] CloudWatch logging configured
- [x] Error handling implemented
- [x] Type hints and documentation complete
- [x] No hardcoded values in infrastructure

---

## Support and Updates

For detailed information on specific components, refer to:
- Terraform code in `terraform/` directory
- Python API code in `endpoint_prototipo/` directory
- Internal documentation in `.INTERNAL_DOCUMENTATION.md`

For deployment from scratch, execute:
```bash
cd terraform
terraform apply -auto-approve
```

This will:
1. Create all AWS resources
2. Trigger CodeBuild to build Docker image
3. Create SageMaker Model and Endpoint
4. Deploy API Gateway and enable /predict endpoint
5. Return API endpoint URL for testing
