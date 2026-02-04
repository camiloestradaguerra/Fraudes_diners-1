#!/usr/bin/env python3
"""Update SageMaker Endpoint with new model configuration."""

import boto3
import json
import sys

def update_endpoint():
    """Update SageMaker Endpoint."""
    client = boto3.client('sagemaker', region_name='us-east-1')
    
    # Parameters
    endpoint_name = 'Fraudes-Diners-Prod-Endpoint'
    endpoint_config_name = 'fraudes-config-prod-2026-02-04-0456'  # Latest config
    
    try:
        # Update endpoint with new configuration
        response = client.update_endpoint(
            EndpointName=endpoint_name,
            EndpointConfigName=endpoint_config_name
        )
        
        print(json.dumps({
            "status": "success",
            "endpoint_arn": response.get('EndpointArn'),
            "message": f"Endpoint {endpoint_name} updated successfully"
        }))
        
        return 0
    except Exception as e:
        print(json.dumps({
            "status": "error",
            "message": str(e)
        }), file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(update_endpoint())
