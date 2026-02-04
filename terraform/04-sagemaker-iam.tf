# PASO 4: SageMaker Model IAM Role

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

resource "aws_iam_role" "sagemaker_role" {
  count              = var.create_sagemaker ? 1 : 0
  name               = "fraudes-sagemaker-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_trust.json

  tags = merge(
    local.common_tags,
    {
      Component = "SageMaker"
    }
  )
}

# Policy: SageMaker ECR Access
data "aws_iam_policy_document" "sagemaker_ecr" {
  statement {
    sid    = "ECRPullImage"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetAuthorizationToken"
    ]
    resources = [
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.docker_image_name}"
    ]
  }

  statement {
    sid    = "ECRAuthToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sagemaker_ecr" {
  count  = var.create_sagemaker ? 1 : 0
  name   = "fraudes-sagemaker-ecr-${var.environment}"
  policy = data.aws_iam_policy_document.sagemaker_ecr.json
  role   = aws_iam_role.sagemaker_role[0].id
}

# Policy: SageMaker S3 Access (for artifacts)
data "aws_iam_policy_document" "sagemaker_s3" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::fraudes-sagemaker-*",
      "arn:aws:s3:::fraudes-sagemaker-*/*"
    ]
  }
}

resource "aws_iam_role_policy" "sagemaker_s3" {
  count  = var.create_sagemaker ? 1 : 0
  name   = "fraudes-sagemaker-s3-${var.environment}"
  policy = data.aws_iam_policy_document.sagemaker_s3.json
  role   = aws_iam_role.sagemaker_role[0].id
}

# Policy: SageMaker CloudWatch Logs
data "aws_iam_policy_document" "sagemaker_logs" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/*"
    ]
  }
}

resource "aws_iam_role_policy" "sagemaker_logs" {
  count  = var.create_sagemaker ? 1 : 0
  name   = "fraudes-sagemaker-logs-${var.environment}"
  policy = data.aws_iam_policy_document.sagemaker_logs.json
  role   = aws_iam_role.sagemaker_role[0].id
}
