# ============================================================
# API Gateway REST API
# ============================================================
resource "aws_api_gateway_rest_api" "fraud_detection" {
  name               = local.api_gateway_name
  binary_media_types = ["application/json", "application/vnd.amazon.eventstream"]
  tags               = local.common_tags
}

# ============================================================
# Recursos y Métodos
# ============================================================
resource "aws_api_gateway_resource" "fraude" {
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id
  parent_id   = aws_api_gateway_rest_api.fraud_detection.root_resource_id
  path_part   = "fraude"
}

resource "aws_api_gateway_method" "fraude_post" {
  rest_api_id      = aws_api_gateway_rest_api.fraud_detection.id
  resource_id      = aws_api_gateway_resource.fraude.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

# ============================================================
# Integración con SageMaker
# ============================================================
resource "aws_api_gateway_integration" "fraude_sagemaker" {
  rest_api_id             = aws_api_gateway_rest_api.fraud_detection.id
  resource_id             = aws_api_gateway_resource.fraude.id
  http_method             = aws_api_gateway_method.fraude_post.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations"
  credentials             = aws_iam_role.apigateway_sagemaker.arn
}

# ============================================================
# Respuestas de Integración
# ============================================================
resource "aws_api_gateway_integration_response" "fraude_integration_response" {
  rest_api_id       = aws_api_gateway_rest_api.fraud_detection.id
  resource_id       = aws_api_gateway_resource.fraude.id
  http_method       = aws_api_gateway_method.fraude_post.http_method
  status_code       = "200"

  depends_on = [aws_api_gateway_integration.fraude_sagemaker]
}

resource "aws_api_gateway_method_response" "fraude_200" {
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id
  resource_id = aws_api_gateway_resource.fraude.id
  http_method = aws_api_gateway_method.fraude_post.http_method
  status_code = "200"
  response_models = { "application/json" = "Empty" }
}

# ============================================================
# Despliegue y Stage
# ============================================================
resource "aws_api_gateway_deployment" "fraud_detection" {
  rest_api_id = aws_api_gateway_rest_api.fraud_detection.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.fraude.id,
      aws_api_gateway_method.fraude_post.id,
      aws_api_gateway_integration.fraude_sagemaker.id,
      aws_api_gateway_integration_response.fraude_integration_response.id,
      aws_iam_role_policy.apigateway_invoke_endpoint.policy
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.fraud_detection.id
  rest_api_id   = aws_api_gateway_rest_api.fraud_detection.id
  stage_name    = var.api_gateway_stage
}