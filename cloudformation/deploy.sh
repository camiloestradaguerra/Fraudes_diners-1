#!/bin/bash

# CloudFormation Deployment Script for Fraud Detection API
# Usage: ./deploy.sh [stack-name] [environment] [region]

set -e

STACK_NAME="${1:-fraudes-diners-stack}"
ENVIRONMENT="${2:-development}"
REGION="${3:-us-east-1}"
TEMPLATE_FILE="./fraud-detection-api-template.yaml"
PARAMETERS_FILE="./parameters-${ENVIRONMENT}.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}CloudFormation Stack Deployment${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Stack Name: $STACK_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "Template: $TEMPLATE_FILE"
echo "Parameters: $PARAMETERS_FILE"
echo

# Validate template
echo -e "${YELLOW}Validating CloudFormation template...${NC}"
aws cloudformation validate-template \
  --template-body file://$TEMPLATE_FILE \
  --region $REGION > /dev/null

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Template validation successful${NC}"
else
  echo -e "${RED}✗ Template validation failed${NC}"
  exit 1
fi

# Check if stack exists
echo -e "${YELLOW}Checking if stack exists...${NC}"
if aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $REGION > /dev/null 2>&1; then
  
  echo -e "${YELLOW}Stack exists. Updating...${NC}"
  
  aws cloudformation update-stack \
    --stack-name $STACK_NAME \
    --template-body file://$TEMPLATE_FILE \
    --parameters file://$PARAMETERS_FILE \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION
  
  WAIT_CONDITION="stack-update-complete"
  
else
  echo -e "${YELLOW}Stack does not exist. Creating...${NC}"
  
  aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://$TEMPLATE_FILE \
    --parameters file://$PARAMETERS_FILE \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION
  
  WAIT_CONDITION="stack-create-complete"
fi

echo -e "${YELLOW}Waiting for stack operation to complete...${NC}"

aws cloudformation wait $WAIT_CONDITION \
  --stack-name $STACK_NAME \
  --region $REGION

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Stack deployment successful${NC}"
  
  # Get outputs
  echo
  echo -e "${YELLOW}Stack Outputs:${NC}"
  aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs' \
    --output table
  
else
  echo -e "${RED}✗ Stack deployment failed${NC}"
  
  # Get stack events for debugging
  echo
  echo -e "${RED}Recent stack events:${NC}"
  aws cloudformation describe-stack-events \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'StackEvents[0:5]' \
    --output table
  
  exit 1
fi

echo
echo -e "${GREEN}Deployment completed successfully!${NC}"
