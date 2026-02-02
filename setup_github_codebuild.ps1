param()
$ErrorActionPreference = "Stop"

$AWS_ACCOUNT_ID = "822626720556"
$AWS_REGION = "us-east-1"
$GITHUB_REPO = "https://github.com/camiloestradaguerra/Fraudes_diners-1.git"
$CODEBUILD_PROJECT = "fraudes-diners-build"

Write-Host "Setting up CodeBuild with GitHub..." -ForegroundColor Cyan

# Assume role
Write-Host "Assuming IAM role..." -ForegroundColor Yellow
$assume = aws sts assume-role --role-arn "arn:aws:iam::$($AWS_ACCOUNT_ID):role/ElasticBeanstalkRole" --role-session-name "codebuild-github" --external-id "fraudes-diners-eb" --region $AWS_REGION | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID = $assume.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $assume.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $assume.Credentials.SessionToken
$env:AWS_DEFAULT_REGION = $AWS_REGION

Write-Host "Credentials set" -ForegroundColor Green

# Create CodeBuild project
Write-Host "Creating CodeBuild project..." -ForegroundColor Yellow

$codebuild_config = @{
    name = $CODEBUILD_PROJECT
    description = "Build Docker image from GitHub to ECR"
    source = @{
        type = "GITHUB"
        location = $GITHUB_REPO
        buildspec = "buildspec.yml"
    }
    artifacts = @{
        type = "NO_ARTIFACTS"
    }
    environment = @{
        type = "LINUX_CONTAINER"
        image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
        computeType = "BUILD_GENERAL1_SMALL"
        environmentVariables = @(
            @{
                name = "AWS_ACCOUNT_ID"
                value = $AWS_ACCOUNT_ID
                type = "PLAINTEXT"
            },
            @{
                name = "AWS_DEFAULT_REGION"
                value = $AWS_REGION
                type = "PLAINTEXT"
            }
        )
        privilegedMode = $true
    }
    serviceRole = "arn:aws:iam::$($AWS_ACCOUNT_ID):role/codebuild-fraudes-diners-role"
    logsConfig = @{
        cloudWatchLogs = @{
            status = "ENABLED"
            groupName = "/aws/codebuild/fraudes-diners"
        }
    }
}

$config_json = $codebuild_config | ConvertTo-Json -Depth 10
$config_json | Out-File -FilePath "codebuild.json" -Force -Encoding UTF8

Write-Host "Creating project..." -ForegroundColor Gray
aws codebuild create-project --cli-input-json file://codebuild.json --region $AWS_REGION 2>&1 | Out-Null

Write-Host "`n=============================" -ForegroundColor Green
Write-Host "CodeBuild Setup Complete!" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

Write-Host "`nProject Details:" -ForegroundColor Cyan
Write-Host "Project Name: $CODEBUILD_PROJECT" -ForegroundColor White
Write-Host "GitHub Repo: $GITHUB_REPO" -ForegroundColor White
Write-Host "Region: $AWS_REGION" -ForegroundColor White

Write-Host "`nTo trigger a build:" -ForegroundColor Yellow
Write-Host "aws codebuild start-build --project-name $CODEBUILD_PROJECT --region $AWS_REGION" -ForegroundColor Gray

Write-Host "`nNext step: .\deploy_to_ecs.ps1" -ForegroundColor Yellow
