# ============================================================
# PASO 3: CodeBuild Project
# ============================================================
# Crear el proyecto CodeBuild solo si NO existe imagen en ECR
# En este paso: Clone GitHub → Build Docker → Push a ECR
# ============================================================

# ============================================================
# CloudWatch Log Group para CodeBuild
# ============================================================

resource "aws_cloudwatch_log_group" "codebuild" {
  count = local.should_run_codebuild ? 1 : 0

  name              = "/aws/codebuild/${var.project_name}-docker-build-${var.environment}"
  retention_in_days = var.codebuild_logs_retention_days

  tags = local.common_tags
}

# ============================================================
# CloudWatch Log Stream para CodeBuild
# ============================================================

resource "aws_cloudwatch_log_stream" "codebuild" {
  count = local.should_run_codebuild ? 1 : 0

  name           = "docker-build-stream"
  log_group_name = aws_cloudwatch_log_group.codebuild[0].name
}

# ============================================================
# CodeBuild Project
# ============================================================

resource "aws_codebuild_project" "docker_build" {
  count = local.should_run_codebuild ? 1 : 0

  name          = "${var.project_name}-docker-build-${var.environment}"
  service_role  = aws_iam_role.codebuild_role[0].arn
  source_version = var.github_branch

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = var.codebuild_privileged_mode

    # Variables de entorno para el buildspec.yml
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "DOCKER_IMAGE_NAME"
      value = var.docker_image_name
    }

    environment_variable {
      name  = "DOCKER_IMAGE_TAG"
      value = var.docker_image_tag
    }
  }

  source {
    type            = "GITHUB"
    location        = var.github_repository_url
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild[0].name
      stream_name = aws_cloudwatch_log_stream.codebuild[0].name
      status      = "ENABLED"
    }
  }

  tags = local.common_tags
}
