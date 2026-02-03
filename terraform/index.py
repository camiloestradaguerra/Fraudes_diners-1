import json
import boto3
import os

sagemaker_client = boto3.client('sagemaker-runtime')
ENDPOINT_NAME = os.environ['SAGEMAKER_ENDPOINT']

def handler(event, context):
    try:
        # Obtener el body del request
        body = event.get('body')
        
        if isinstance(body, str):
            payload = body
        else:
            payload = json.dumps(body)
        
        # Invocar el endpoint de SageMaker
        response = sagemaker_client.invoke_endpoint(
            EndpointName=ENDPOINT_NAME,
            ContentType='application/json',
            Body=payload
        )
        
        # Leer la respuesta
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
                'error': str(e)
            })
        }
