#!/bin/bash

# Final deployment script
# Este script asume el rol, trigger el build y despliega a ECS

AWS_ACCOUNT_ID="822626720556"
AWS_REGION="us-east-1"
ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/ElasticBeanstalkRole"
EXTERNAL_ID="fraudes-diners-eb"

echo "========================================="
echo "AWS CodeBuild + ECS/Fargate Deployment"
echo "========================================="

# Get credentials
echo "Getting credentials..."
CREDENTIALS=$(aws sts assume-role \
  --role-arn $ROLE_ARN \
  --role-session-name "final-deploy" \
  --external-id $EXTERNAL_ID \
  --region $AWS_REGION \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | awk '{print $1}')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | awk '{print $2}')
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | awk '{print $3}')
export AWS_DEFAULT_REGION=$AWS_REGION

echo "Credentials obtained"

# Trigger build
echo "Triggering CodeBuild..."
BUILD=$(aws codebuild start-build \
  --project-name fraudes-diners-build \
  --region $AWS_REGION \
  --query 'build.id' \
  --output text)

echo "Build ID: $BUILD"

# Wait and check
echo "Waiting for build to complete..."
while true; do
  STATUS=$(aws codebuild batch-get-builds \
    --ids "$BUILD" \
    --region $AWS_REGION \
    --query 'builds[0].buildStatus' \
    --output text)
  
  if [ "$STATUS" = "SUCCEEDED" ]; then
    echo "Build SUCCEEDED!"
    break
  elif [ "$STATUS" = "FAILED" ]; then
    echo "Build FAILED!"
    aws logs tail /aws/codebuild/fraudes-diners --region $AWS_REGION
    exit 1
  fi
  
  echo "Status: $STATUS..."
  sleep 10
done

echo "Deployment to ECS will happen next..."
echo "Run: ./deploy_to_ecs.ps1"
