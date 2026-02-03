import json
import boto3
import base64

sagemaker_runtime = boto3.client('sagemaker-runtime')

def lambda_handler(event, context):
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body')
        
        # Convert to JSON string for SageMaker
        payload = json.dumps(body)
        
        # Invoke SageMaker endpoint
        response = sagemaker_runtime.invoke_endpoint(
            EndpointName='endpoint-fraud-detection-prod',
            ContentType='application/json',
            Body=payload
        )
        
        # Parse response
        result = json.loads(response['Body'].read().decode())
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps(result)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'error': str(e),
                'message': 'Error invoking SageMaker endpoint'
            })
        }
