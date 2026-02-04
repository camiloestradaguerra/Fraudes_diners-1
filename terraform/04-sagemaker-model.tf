# PASO 4: SageMaker Model Creation

# S3 bucket for SageMaker artifacts
resource "aws_s3_bucket" "sagemaker_artifacts" {
  count  = var.create_sagemaker ? 1 : 0
  bucket = "fraudes-sagemaker-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  tags = merge(
    local.common_tags,
    {
      Component = "SageMaker"
    }
  )
}

resource "aws_s3_bucket_versioning" "sagemaker_artifacts" {
  count  = var.create_sagemaker ? 1 : 0
  bucket = aws_s3_bucket.sagemaker_artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# SageMaker Model
resource "aws_sagemaker_model" "fraudes" {
  count           = var.create_sagemaker ? 1 : 0
  name            = "fraudes-model-${var.environment}-${formatdate("YYYY-MM-DD", timestamp())}"
  execution_role_arn = aws_iam_role.sagemaker_role[0].arn

  primary_container {
    image          = "${aws_ecr_repository.fraud_detection.repository_url}:latest"
    model_data_url = null
    environment = {
      SAGEMAKER_PROGRAM       = "inference.py"
      SAGEMAKER_SUBMIT_DIRECTORY = "/opt/ml/code"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Component = "SageMaker"
      Model     = "fraudes"
    }
  )

  depends_on = [
    aws_iam_role_policy.sagemaker_ecr,
    aws_iam_role_policy.sagemaker_s3,
    aws_iam_role_policy.sagemaker_logs
  ]
}

# CloudWatch Log Group for SageMaker
resource "aws_cloudwatch_log_group" "sagemaker" {
  count             = var.create_sagemaker ? 1 : 0
  name              = "/aws/sagemaker/fraudes-model-${var.environment}"
  retention_in_days = 30

  tags = merge(
    local.common_tags,
    {
      Component = "SageMaker"
    }
  )
}
