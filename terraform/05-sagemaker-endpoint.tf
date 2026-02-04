# PASO 5: SageMaker Endpoint Configuration

# SageMaker Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "fraudes" {
  count           = var.create_sagemaker_endpoint ? 1 : 0
  name            = "${local.sagemaker_endpoint_config}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  production_variants {
    variant_name           = "Primary"
    model_name             = aws_sagemaker_model.fraudes[0].name
    initial_instance_count = var.sagemaker_initial_instance_count
    instance_type          = var.sagemaker_instance_type

    accelerator_type = null
  }

  tags = merge(
    local.common_tags,
    {
      Component = "SageMaker"
      Type      = "EndpointConfig"
    }
  )

  lifecycle {
    ignore_changes = [name]
  }

  depends_on = [
    aws_sagemaker_model.fraudes
  ]
}

# SageMaker Endpoint
# NOTA: El endpoint ya existe y está en servicio. Se maneja con lifecycle ignore_changes.
resource "aws_sagemaker_endpoint" "fraudes" {
  count                    = 0  # Disabled: el endpoint ya existe en AWS
  name                     = local.sagemaker_endpoint_name
  endpoint_config_name     = aws_sagemaker_endpoint_configuration.fraudes[0].name

  tags = merge(
    local.common_tags,
    {
      Component = "SageMaker"
      Type      = "Endpoint"
    }
  )
  lifecycle {
    ignore_changes = all
  }
  depends_on = [
    aws_sagemaker_endpoint_configuration.fraudes
  ]
}

# CloudWatch Log Group for SageMaker Endpoint
# NOTA: Este log group ya existe en AWS. Se deshabilita para evitar conflictos.
resource "aws_cloudwatch_log_group" "sagemaker_endpoint" {
  count             = 0  # Disabled: log group ya existe
  name              = "/aws/sagemaker/Endpoints/${local.sagemaker_endpoint_name}"
  retention_in_days = 30

  tags = merge(
    local.common_tags,
    {
      Component = "SageMaker"
      Type      = "Endpoint"
    }
  )

  lifecycle {
    ignore_changes = all
  }
}
