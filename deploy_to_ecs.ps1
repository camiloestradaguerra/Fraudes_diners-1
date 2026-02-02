param()
$ErrorActionPreference = "Stop"

$AWS_ACCOUNT_ID = "822626720556"
$AWS_REGION = "us-east-1"
$ECS_CLUSTER = "fraudes-diners-cluster"
$ECS_SERVICE = "fraudes-diners-service"
$ECS_TASK_FAMILY = "fraudes-diners-task"
$ECR_REPO = "fraudes-diners"

Write-Host "Deploying to ECS/Fargate..." -ForegroundColor Cyan

# Assume role
Write-Host "Assuming IAM role..." -ForegroundColor Yellow
$assume = aws sts assume-role --role-arn "arn:aws:iam::$($AWS_ACCOUNT_ID):role/ElasticBeanstalkRole" --role-session-name "ecs-deploy" --external-id "fraudes-diners-eb" --region $AWS_REGION | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID = $assume.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $assume.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $assume.Credentials.SessionToken
$env:AWS_DEFAULT_REGION = $AWS_REGION

Write-Host "Credentials set" -ForegroundColor Green

# Create ECS cluster
Write-Host "Creating ECS cluster..." -ForegroundColor Yellow
aws ecs create-cluster --cluster-name $ECS_CLUSTER --region $AWS_REGION 2>&1 | Out-Null
Write-Host "Cluster ready" -ForegroundColor Green

# Get latest image from ECR
Write-Host "Getting latest image from ECR..." -ForegroundColor Yellow
$FULL_IMAGE_URI = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO`:latest"
Write-Host "Image URI: $FULL_IMAGE_URI" -ForegroundColor Green

# Register task definition
Write-Host "Registering task definition..." -ForegroundColor Yellow

$task_def = @{
    family = $ECS_TASK_FAMILY
    networkMode = "awsvpc"
    requiresCompatibilities = @("FARGATE")
    cpu = "256"
    memory = "512"
    containerDefinitions = @(
        @{
            name = "fraudes-diners-container"
            image = $FULL_IMAGE_URI
            portMappings = @(
                @{
                    containerPort = 8000
                    hostPort = 8000
                    protocol = "tcp"
                }
            )
            environment = @(
                @{
                    name = "PYTHONUNBUFFERED"
                    value = "1"
                }
            )
            logConfiguration = @{
                logDriver = "awslogs"
                options = @{
                    "awslogs-group" = "/ecs/fraudes-diners"
                    "awslogs-region" = $AWS_REGION
                    "awslogs-stream-prefix" = "ecs"
                }
            }
        }
    )
    executionRoleArn = "arn:aws:iam::$($AWS_ACCOUNT_ID):role/ecsTaskExecutionRole"
}

$task_json = $task_def | ConvertTo-Json -Depth 10
$task_json | Out-File -FilePath "task_def.json" -Force -Encoding UTF8

aws ecs register-task-definition --cli-input-json file://task_def.json --region $AWS_REGION 2>&1 | Out-Null
Write-Host "Task definition registered" -ForegroundColor Green

# Create default VPC if needed
Write-Host "Setting up VPC..." -ForegroundColor Yellow
$vpc = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region $AWS_REGION --query 'Vpcs[0].VpcId' --output text 2>&1

if ($vpc -like "None" -or $vpc -eq "") {
    Write-Host "Creating default VPC..." -ForegroundColor Gray
    aws ec2 create-default-vpc --region $AWS_REGION 2>&1 | Out-Null
    $vpc = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region $AWS_REGION --output text --query 'Vpcs[0].VpcId'
}

# Get subnet
$subnet = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --region $AWS_REGION --output text --query 'Subnets[0].SubnetId'
Write-Host "Subnet: $subnet" -ForegroundColor Green

# Get security group
$sg = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" "Name=group-name,Values=default" --region $AWS_REGION --output text --query 'SecurityGroups[0].GroupId'
Write-Host "Security Group: $sg" -ForegroundColor Green

# Create service
Write-Host "Creating ECS service..." -ForegroundColor Yellow

aws ecs create-service --cluster $ECS_CLUSTER --service-name $ECS_SERVICE --task-definition $ECS_TASK_FAMILY --desired-count 1 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$subnet],securityGroups=[$sg],assignPublicIp=ENABLED}" --region $AWS_REGION 2>&1 | Out-Null

Write-Host "Service created" -ForegroundColor Green

Write-Host "`n=============================" -ForegroundColor Green
Write-Host "ECS Deployment Complete!" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

Write-Host "`nDeployment Information:" -ForegroundColor Cyan
Write-Host "Cluster: $ECS_CLUSTER" -ForegroundColor White
Write-Host "Service: $ECS_SERVICE" -ForegroundColor White
Write-Host "Image: $FULL_IMAGE_URI" -ForegroundColor White
Write-Host "Region: $AWS_REGION" -ForegroundColor White

Write-Host "`nMonitor service:" -ForegroundColor Yellow
Write-Host "aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --region $AWS_REGION" -ForegroundColor Gray

Write-Host "`nView logs:" -ForegroundColor Yellow
Write-Host "aws logs tail /ecs/fraudes-diners --follow --region $AWS_REGION" -ForegroundColor Gray

