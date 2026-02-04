# ============================================================
# PASO 2: IAM ROLES - CodeBuild
# ============================================================
# En este paso creamos el rol y las políticas de CodeBuild
# ============================================================

# ============================================================
# Data Source: Get AWS Account ID (para usar en ARNs)
# ============================================================

data "aws_caller_identity" "current" {}

# ============================================================
# IAM Role: AWS CodeBuild
# ============================================================

resource "aws_iam_role" "codebuild_role" {
  count = var.enable_codebuild ? 1 : 0

  name               = "${var.project_name}-codebuild-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.codebuild_trust[0].json
  tags               = local.common_tags
}

# ============================================================
# Attach: CodeBuild ECR Policy
# ============================================================

resource "aws_iam_role_policy" "codebuild_ecr" {
  count = var.enable_codebuild ? 1 : 0

  name   = "${var.project_name}-codebuild-ecr-${var.environment}"
  role   = aws_iam_role.codebuild_role[0].id
  policy = data.aws_iam_policy_document.codebuild_ecr[0].json
}

# ============================================================
# Attach: CodeBuild CloudWatch Logs Policy
# ============================================================

resource "aws_iam_role_policy" "codebuild_logs" {
  count = var.enable_codebuild ? 1 : 0

  name   = "${var.project_name}-codebuild-logs-${var.environment}"
  role   = aws_iam_role.codebuild_role[0].id
  policy = data.aws_iam_policy_document.codebuild_logs[0].json
}
