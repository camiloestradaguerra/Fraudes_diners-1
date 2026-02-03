# ============================================================
# IAM Role: SageMaker Execution
# ============================================================

resource "aws_iam_role" "sagemaker_execution" {
  name               = local.iam_role_sagemaker_name
  assume_role_policy = data.aws_iam_policy_document.sagemaker_trust.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "sagemaker_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy" "sagemaker_ecr" {
  name   = "${local.iam_role_sagemaker_name}-ecr"
  role   = aws_iam_role.sagemaker_execution.id
  policy = data.aws_iam_policy_document.sagemaker_ecr.json
}

data "aws_iam_policy_document" "sagemaker_ecr" {
  statement {
    sid    = "ECRAccess"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories"
    ]
    resources = [aws_ecr_repository.fraud_detection.arn]
  }

  statement {
    sid    = "ECRAuthToken"
    effect = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

# ============================================================
# IAM Role: API Gateway -> SageMaker
# ============================================================

resource "aws_iam_role" "apigateway_sagemaker" {
  name               = local.iam_role_apigateway_name
  assume_role_policy = data.aws_iam_policy_document.apigateway_trust.json
  tags               = local.common_tags
}

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

resource "aws_iam_role_policy" "apigateway_invoke_endpoint" {
  name   = "${local.iam_role_apigateway_name}-invoke"
  role   = aws_iam_role.apigateway_sagemaker.id
  policy = data.aws_iam_policy_document.apigateway_invoke.json
}

data "aws_iam_policy_document" "apigateway_invoke" {
  statement {
    sid    = "InvokeSageMakerEndpoint"
    effect = "Allow"
    actions = ["sagemaker:InvokeEndpoint"]
    # USAMOS EL ARN DEL RECURSO PARA EVITAR DISCREPANCIAS DE NOMBRES
    resources = [aws_sagemaker_endpoint.fraud_detection.arn]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}