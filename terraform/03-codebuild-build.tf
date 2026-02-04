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
    when       = create
    command    = "powershell.exe -Command \"$bid = (aws codebuild start-build --project-name ${aws_codebuild_project.docker_build[0].name} --region ${var.aws_region} --output json | ConvertFrom-Json).build.id; for($i=0; $i -lt 240; $i++) { $s = (aws codebuild batch-get-builds --ids $bid --region ${var.aws_region} --output json | ConvertFrom-Json).builds[0].buildStatus; Write-Host $s; if($s -in 'SUCCEEDED','FAILED','FAULT','STOPPED') { exit 0 }; Start-Sleep -Seconds 15 }\""
    on_failure = fail
  }
}
