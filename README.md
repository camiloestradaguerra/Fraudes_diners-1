# Fraud Detection API - Production Deployment

**Status:** Production Ready  
**Date:** February 4, 2026  
**Version:** 2024.11  
**Infrastructure:** AWS + Terraform

---

## Quick Start

```bash
# Deploy infrastructure
cd terraform
terraform apply -auto-approve

# Retrieve API endpoint
terraform output -raw api_gateway_invoke_url

# Test endpoint
curl -X POST https://<API_URL>/prod/predict \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX001",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "Restaurant",
    "especialidad": "RESTAURANTES"
  }'
```

**Expected Response:**
```json
{
  "schema_version": "1.0",
  "request_id": "REQ-XXXXX",
  "ml_score_0_999": 45.2,
  "model_meta": {
    "name": "fraud_model_prod",
    "version": "2024.11",
    "provider": "ExternalVendor"
  },
  "latency_ms": 32.2
}
```

---

## Architecture

### System Components

- **ECR Repository:** fraud-detection-api
- **CodeBuild Project:** fraudes-docker-build-prod (auto-triggered)
- **SageMaker Model:** fraudes-model-prod-YYYY-MM-DD
- **SageMaker Endpoint:** Fraudes-Diners-Prod-Endpoint (ml.m5.large)
- **API Gateway:** we9wpnfvqa (REST API with /predict endpoint)
- **CloudWatch Logs:** Comprehensive logging for all components

### Data Flow

```
POST /predict
    ↓
API Gateway (request template: $input.body)
    ↓
SageMaker Runtime (InvokeEndpoint)
    ↓
Docker Container (/invocations endpoint)
    ↓
FastAPI Application
    ├─ Decode request (handles JSON or base64)
    ├─ Validate with Pydantic schema
    ├─ Run fraud detection model
    └─ Return score (0-999)
    ↓
API Gateway (response template: $input.json('$'))
    ↓
HTTP 200 with prediction
```

---

## API Endpoints

### Single Prediction

```http
POST /fraud/predict

{
  "transaction_id": "string",
  "monto": float,
  "edad": int (18-120),
  "ciudad": "string",
  "establecimiento": "string",
  "especialidad": "string" (optional)
}
```

### Batch Prediction

```http
POST /fraud/batch-predict

[
  { transaction data },
  { transaction data }
]
```

### Health Check

```http
GET /health/

Response:
{
  "status": "healthy",
  "model_loaded": true,
  "version": "1.0.0"
}
```

---

## Configuration

### Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
aws_region              = "us-east-1"
project_name            = "fraudes"
environment             = "prod"

create_sagemaker            = true
create_sagemaker_endpoint   = true
create_api_gateway          = true

instance_type           = "ml.m5.large"
initial_instance_count  = 1
```

### Environment Setup

```bash
# Initialize Terraform
cd terraform
terraform init

# Validate configuration
terraform validate

# Generate deployment plan
terraform plan -out=tfplan
```

---

## Deployment Process

### Step 1: Validate AWS Access

```bash
aws sts get-caller-identity
# Output should show: Account, UserId, Arn
```

### Step 2: Plan Deployment

```bash
cd terraform
terraform plan -out=tfplan
```

### Step 3: Apply Infrastructure

```bash
terraform apply tfplan
```

**Timeline:**
- CodeBuild Docker build: ~60 seconds
- SageMaker Model creation: ~2 minutes
- SageMaker Endpoint startup: 5-10 minutes
- API Gateway deployment: ~1 minute
- **Total:** ~15-20 minutes

### Step 4: Verify Deployment

```bash
# Check endpoint status
aws sagemaker describe-endpoint \
  --endpoint-name Fraudes-Diners-Prod-Endpoint \
  --query 'EndpointStatus'

# Retrieve API URL
API_URL=$(terraform output -raw api_gateway_invoke_url)
echo $API_URL

# Test API
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"transaction_id":"TEST001","monto":100,"edad":30,"ciudad":"Quito","establecimiento":"Test"}'
```

---

## File Structure

```
endpoint_prototipo/
├── main.py                   # FastAPI application
├── schemas.py               # Pydantic models (request/response)
├── requirements.txt         # Python dependencies
└── routers/
    ├── health.py           # Health check endpoints
    └── fraud_prediction.py  # ML inference logic

terraform/
├── provider.tf              # AWS provider configuration
├── variables.tf             # Variable definitions
├── locals.tf                # Computed values
├── terraform.tfvars         # Configuration values
├── 01-ecr-repository.tf     # Docker registry
├── 02-codebuild.tf          # Build service
├── 03-iam.tf                # IAM roles/policies
├── 04-sagemaker.tf          # ML model/endpoint
├── 06-apigateway-api.tf     # REST API
└── outputs.tf               # Exported values

Dockerfile                    # Container image
buildspec.yml                # CodeBuild specification
TECHNICAL_ARCHITECTURE.md    # Detailed documentation
```

---

## Monitoring and Logging

### CloudWatch Log Groups

- `/aws/codebuild/fraudes-docker-build-prod`
- `/aws/sagemaker/fraudes-model-prod`
- `/aws/apigateway/we9wpnfvqa`

### View Logs

```bash
# CodeBuild logs
aws logs tail /aws/codebuild/fraudes-docker-build-prod --follow

# SageMaker logs
aws logs tail /aws/sagemaker/fraudes-model-prod --follow

# API Gateway logs
aws logs tail /aws/apigateway/we9wpnfvqa --follow
```

### Key Metrics

- Endpoint Status: InService
- API Response Time: < 100ms
- Error Rate: < 1%
- Model Inference Latency: Included in response (latency_ms)

---

## Troubleshooting

### Endpoint Creation Fails

```bash
# Check CloudWatch logs
aws logs tail /aws/sagemaker/fraudes-model-prod --follow

# Verify Docker image in ECR
aws ecr describe-images \
  --repository-name fraud-detection-api \
  --query 'imageDetails[*].[imageTags,imageSizeInBytes]'
```

### API Returns 502 Bad Gateway

```bash
# Check endpoint status
aws sagemaker describe-endpoint \
  --endpoint-name Fraudes-Diners-Prod-Endpoint

# Check API Gateway integration
aws apigateway get-integration \
  --rest-api-id we9wpnfvqa \
  --resource-id <resource-id> \
  --http-method POST
```

### Model Not Loaded (503)

```bash
# Restart endpoint
aws sagemaker update-endpoint \
  --endpoint-name Fraudes-Diners-Prod-Endpoint \
  --endpoint-config-name fraudes-endpoint-config

# Monitor logs
aws logs tail /aws/sagemaker/fraudes-model-prod --follow
```

---

## Cleanup

```bash
# Destroy all infrastructure
cd terraform
terraform destroy -auto-approve

# Note: This will also remove the SageMaker endpoint,
# API Gateway, and ECR repository
```

---

## Code Quality

All Python code follows professional standards:
- Type hints for all functions and classes
- Comprehensive docstrings
- PEP 8 compliant
- Pydantic for data validation
- Structured logging
- Error handling

See `TECHNICAL_ARCHITECTURE.md` for detailed documentation.

---

## Support

For line-by-line code explanation, see `.INTERNAL_DOCUMENTATION.md` (internal only, not in git).

For detailed technical architecture, see `TECHNICAL_ARCHITECTURE.md`.

---

## Status

✅ Infrastructure deployed and operational  
✅ All AWS resources created  
✅ API endpoint responding with valid predictions  
✅ SageMaker endpoint InService  
✅ End-to-end testing passed  
✅ Production ready

**Deployment Status:** COMPLETE

---

**Last Updated:** February 4, 2026  
**API Version:** 2024.11  
**Deployment:** Production
