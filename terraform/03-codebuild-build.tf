# PASO 3b: Ejecutar CodeBuild para construir y pushear Docker image a ECR
# Este recurso solo se ejecuta si la imagen no existe (should_run_codebuild = true)

resource "null_resource" "trigger_codebuild" {
  count = local.should_run_codebuild ? 1 : 0

  depends_on = [
    aws_codebuild_project.docker_build,
    aws_iam_role_policy.codebuild_ecr,
    aws_iam_role_policy.codebuild_logs,
    aws_cloudwatch_log_group.codebuild,
    aws_cloudwatch_log_stream.codebuild
  ]

  # Trigger CodeBuild start-build via AWS CLI
  provisioner "local-exec" {
    when    = create
    command = "aws codebuild start-build --project-name ${aws_codebuild_project.docker_build[0].name} --region ${var.aws_region} --query 'build.id' --output text > codebuild_id.txt && timeout /t 1800 /nobreak"
    on_failure = continue
  }
}
