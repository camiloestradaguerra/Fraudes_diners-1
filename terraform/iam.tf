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

# ============================================================
# IAM Role: AWS CodeBuild
# ============================================================

resource "aws_iam_role" "codebuild_role" {
  count = var.enable_codebuild ? 1 : 0

  name               = "${var.project_name}-codebuild-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.codebuild_trust[0].json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "codebuild_trust" {
  count = var.enable_codebuild ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "codebuild_ecr" {
  count = var.enable_codebuild ? 1 : 0

  name   = "${var.project_name}-codebuild-ecr-${var.environment}"
  role   = aws_iam_role.codebuild_role[0].id
  policy = data.aws_iam_policy_document.codebuild_ecr[0].json
}

data "aws_iam_policy_document" "codebuild_ecr" {
  count = var.enable_codebuild ? 1 : 0

  statement {
    sid    = "ECRPushImage"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
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

resource "aws_iam_role_policy" "codebuild_logs" {
  count = var.enable_codebuild ? 1 : 0

  name   = "${var.project_name}-codebuild-logs-${var.environment}"
  role   = aws_iam_role.codebuild_role[0].id
  policy = data.aws_iam_policy_document.codebuild_logs[0].json
}

data "aws_iam_policy_document" "codebuild_logs" {
  count = var.enable_codebuild ? 1 : 0

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.project_name}-docker-build-${var.environment}*"]
  }
}