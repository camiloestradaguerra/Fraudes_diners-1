param()
$ErrorActionPreference = "Stop"

$AWS_ACCOUNT_ID = "822626720556"
$AWS_REGION = "us-east-1"
$CODEBUILD_PROJECT = "fraudes-diners-build"

Write-Host "Triggering CodeBuild build..." -ForegroundColor Cyan

# Assume role
Write-Host "Assuming IAM role..." -ForegroundColor Yellow
$assume = aws sts assume-role --role-arn "arn:aws:iam::$AWS_ACCOUNT_ID:role/ElasticBeanstalkRole" --role-session-name "codebuild-trigger" --external-id "fraudes-diners-eb" --region $AWS_REGION | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID = $assume.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $assume.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $assume.Credentials.SessionToken
$env:AWS_DEFAULT_REGION = $AWS_REGION

Write-Host "Starting build..." -ForegroundColor Yellow

# Trigger build with local source
$build_output = aws codebuild start-build --project-name $CODEBUILD_PROJECT --region $AWS_REGION | ConvertFrom-Json

$BUILD_ID = $build_output.build.id

Write-Host "Build triggered successfully!" -ForegroundColor Green
Write-Host "Build ID: $BUILD_ID" -ForegroundColor White

# Monitor the build
Write-Host "`nMonitoring build progress..." -ForegroundColor Yellow

$build_status = "IN_PROGRESS"
$previous_status = ""

while ($build_status -eq "IN_PROGRESS") {
    Start-Sleep -Seconds 5
    
    $build_info = aws codebuild batch-get-builds --ids $BUILD_ID --region $AWS_REGION | ConvertFrom-Json
    $build_status = $build_info.builds[0].buildStatus
    $phase = $build_info.builds[0].currentPhase
    
    if ($phase -ne $previous_status) {
        Write-Host "Phase: $phase" -ForegroundColor Cyan
        $previous_status = $phase
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Build Status: $build_status" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

if ($build_status -eq "SUCCEEDED") {
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "Docker image pushed to ECR" -ForegroundColor Green
    Write-Host "`nNext: Run deploy_to_ecs.ps1 to deploy to ECS/Fargate" -ForegroundColor Yellow
} else {
    Write-Host "Build failed. Check logs:" -ForegroundColor Red
    Write-Host "aws logs tail /aws/codebuild/$CODEBUILD_PROJECT --follow --region $AWS_REGION" -ForegroundColor Gray
}
