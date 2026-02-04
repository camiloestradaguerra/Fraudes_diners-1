# PASO 6: API Gateway IAM Role

data "aws_iam_policy_document" "apigateway_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "apigateway_role" {
  count              = var.create_api_gateway ? 1 : 0
  name               = "${local.iam_role_apigateway_name}-prod"
  assume_role_policy = data.aws_iam_policy_document.apigateway_trust.json

  tags = merge(
    local.common_tags,
    {
      Component = "APIGateway"
    }
  )
}

# Policy: API Gateway SageMaker Invoke
data "aws_iam_policy_document" "apigateway_sagemaker" {
  statement {
    sid    = "SageMakerInvoke"
    effect = "Allow"
    actions = [
      "sagemaker:InvokeEndpoint"
    ]
    resources = [
      "arn:aws:sagemaker:${var.aws_region}:${data.aws_caller_identity.current.account_id}:endpoint/${local.sagemaker_endpoint_name}"
    ]
  }
}

resource "aws_iam_role_policy" "apigateway_sagemaker" {
  count  = var.create_api_gateway ? 1 : 0
  name   = "apigateway-sagemaker-invoke-prod"
  policy = data.aws_iam_policy_document.apigateway_sagemaker.json
  role   = aws_iam_role.apigateway_role[0].id
}

# Policy: API Gateway CloudWatch Logs
data "aws_iam_policy_document" "apigateway_logs" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
}

resource "aws_iam_role_policy" "apigateway_logs" {
  count  = var.create_api_gateway ? 1 : 0
  name   = "apigateway-logs-prod"
  policy = data.aws_iam_policy_document.apigateway_logs.json
  role   = aws_iam_role.apigateway_role[0].id
}

# Managed Policy: CloudWatch Logs Full Access (para API Gateway Account)
resource "aws_iam_role_policy_attachment" "apigateway_logs_managed" {
  count      = var.create_api_gateway ? 1 : 0
  role       = aws_iam_role.apigateway_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
