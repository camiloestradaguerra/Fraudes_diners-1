import boto3
import json

# Cliente de SageMaker
client = boto3.client('sagemaker-runtime', region_name='us-east-1')

endpoint_name = "endpoint-fraudes-v5"
payload = {
    "transaction_id": "TRX123456",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
}

print(f"Enviando datos al endpoint: {endpoint_name}...")

try:
    response = client.invoke_endpoint(
        EndpointName=endpoint_name,
        ContentType='application/json',
        Body=json.dumps(payload)
    )
    
    # Decodificar la respuesta
    result = json.loads(response['Body'].read().decode())
    print("\n Respuesta recibida:")
    print(json.dumps(result, indent=4))

except Exception as e:
    print(f"\n Error al invocar el endpoint: {str(e)}")