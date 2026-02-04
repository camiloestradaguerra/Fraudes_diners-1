# ============================================================
# PASO 2: IAM POLICIES - CodeBuild
# ============================================================
# En este paso definimos SOLO las políticas necesarias para
# que CodeBuild pueda construir y pushear la imagen Docker a ECR
# ============================================================

# ============================================================
# Policy Document: CodeBuild Trust (quien puede asumir el rol)
# ============================================================

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

# ============================================================
# Policy Document: CodeBuild ECR Push (permisos para pushear)
# ============================================================

data "aws_iam_policy_document" "codebuild_ecr" {
  count = var.enable_codebuild ? 1 : 0

  statement {
    sid    = "ECRPushImage"
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = [local.ecr_repository_arn]
  }

  statement {
    sid    = "ECRAuthToken"
    effect = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

# ============================================================
# Policy Document: CodeBuild CloudWatch Logs
# ============================================================

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
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.project_name}-*"
    ]
  }
}
