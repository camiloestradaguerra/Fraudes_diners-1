# PASO 6: API Gateway REST API

# API Gateway REST API
resource "aws_api_gateway_rest_api" "fraudes" {
  count       = var.create_api_gateway ? 1 : 0
  name        = "${local.api_gateway_name}-api"
  description = "API Gateway para Fraud Detection con SageMaker Endpoint"

  tags = merge(
    local.common_tags,
    {
      Component = "APIGateway"
    }
  )
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "apigateway" {
  count             = var.create_api_gateway ? 1 : 0
  name              = "/aws/apigateway/${local.api_gateway_name}"
  retention_in_days = 30

  tags = merge(
    local.common_tags,
    {
      Component = "APIGateway"
    }
  )
}

# API Gateway Account (para habilitar CloudWatch logs)
resource "aws_api_gateway_account" "fraudes" {
  count              = var.create_api_gateway ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.apigateway_role[0].arn

  depends_on = [
    aws_iam_role_policy_attachment.apigateway_logs_managed,
    aws_api_gateway_rest_api.fraudes
  ]
}

# API Gateway Resource: /predict
resource "aws_api_gateway_resource" "predict" {
  count       = var.create_api_gateway ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.fraudes[0].id
  parent_id   = aws_api_gateway_rest_api.fraudes[0].root_resource_id
  path_part   = "predict"
}

# API Gateway Method: POST /predict
resource "aws_api_gateway_method" "predict" {
  count            = var.create_api_gateway ? 1 : 0
  rest_api_id      = aws_api_gateway_rest_api.fraudes[0].id
  resource_id      = aws_api_gateway_resource.predict[0].id
  http_method      = "POST"
  authorization    = "NONE"
  request_models   = {
    "application/json" = "Empty"
  }
  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}

# API Gateway Integration: POST /predict -> SageMaker Endpoint
resource "aws_api_gateway_integration" "predict" {
  count                   = var.create_api_gateway ? 1 : 0
  rest_api_id             = aws_api_gateway_rest_api.fraudes[0].id
  resource_id             = aws_api_gateway_resource.predict[0].id
  http_method             = aws_api_gateway_method.predict[0].http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:runtime.sagemaker:path/endpoints/${local.sagemaker_endpoint_name}/invocations"
  credentials             = aws_iam_role.apigateway_role[0].arn
  
  request_templates = {
    "application/json" = "$input.body"
  }

  depends_on = [
    aws_iam_role_policy.apigateway_sagemaker
  ]
}

# API Gateway Integration Response
resource "aws_api_gateway_integration_response" "predict" {
  count           = var.create_api_gateway ? 1 : 0
  rest_api_id     = aws_api_gateway_rest_api.fraudes[0].id
  resource_id     = aws_api_gateway_resource.predict[0].id
  http_method     = aws_api_gateway_method.predict[0].http_method
  status_code     = "200"

  depends_on = [
    aws_api_gateway_integration.predict
  ]
}

# API Gateway Method Response
resource "aws_api_gateway_method_response" "predict" {
  count       = var.create_api_gateway ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.fraudes[0].id
  resource_id = aws_api_gateway_resource.predict[0].id
  http_method = aws_api_gateway_method.predict[0].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Content-Type" = true
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "fraudes" {
  count       = var.create_api_gateway ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.fraudes[0].id

  depends_on = [
    aws_api_gateway_integration.predict,
    aws_api_gateway_integration_response.predict
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "fraudes" {
  count             = var.create_api_gateway ? 1 : 0
  deployment_id     = aws_api_gateway_deployment.fraudes[0].id
  rest_api_id       = aws_api_gateway_rest_api.fraudes[0].id
  stage_name        = var.api_gateway_stage
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway[0].arn
    format = "$context.requestId $context.extendedRequestId $context.identity.sourceIp $context.requestTime $context.routeKey $context.status"
  }

  tags = merge(
    local.common_tags,
    {
      Component = "APIGateway"
    }
  )

  depends_on = [
    aws_api_gateway_account.fraudes
  ]
}
