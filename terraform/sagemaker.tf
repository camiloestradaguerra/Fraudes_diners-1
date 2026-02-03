# ============================================================
# SageMaker Model
# ============================================================

resource "aws_sagemaker_model" "fraud_detection" {
  depends_on = [null_resource.docker_push]

  name             = local.sagemaker_model_name
  execution_role_arn = aws_iam_role.sagemaker_execution.arn

  primary_container {
    image          = local.docker_image_uri
    model_data_url = null # Docker image contiene el modelo

    environment = {
      SAGEMAKER_PROGRAM       = "main.py"
      SAGEMAKER_SUBMIT_DIRECTORY = "/opt/ml/code"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.sagemaker_model_name
    }
  )
}

# ============================================================
# SageMaker Endpoint Configuration
# ============================================================

resource "aws_sagemaker_endpoint_configuration" "fraud_detection" {
  name = local.sagemaker_endpoint_config

  production_variants {
    model_name            = aws_sagemaker_model.fraud_detection.name
    variant_name          = "Primary"
    initial_instance_count = var.sagemaker_initial_instance_count
    instance_type         = var.sagemaker_instance_type
    initial_variant_weight = 1.0
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.sagemaker_endpoint_config
    }
  )
}

# ============================================================
# SageMaker Endpoint
# ============================================================

resource "aws_sagemaker_endpoint" "fraud_detection" {
  name                 = local.sagemaker_endpoint_name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.fraud_detection.name

  tags = merge(
    local.common_tags,
    {
      Name = local.sagemaker_endpoint_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
