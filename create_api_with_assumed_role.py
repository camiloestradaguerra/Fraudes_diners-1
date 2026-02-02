#!/usr/bin/env python3
"""
Script para crear API Gateway usando credenciales asumidas del rol ElasticBeanstalkRole
"""
import boto3
import json
import os
from botocore.exceptions import ClientError

def assume_role():
    """Asumir el rol ElasticBeanstalkRole"""
    print("📍 Asumiendo rol ElasticBeanstalkRole...")
    
    sts_client = boto3.client('sts', region_name='us-east-1')
    
    try:
        assumed_role = sts_client.assume_role(
            RoleArn='arn:aws:iam::822626720556:role/ElasticBeanstalkRole',
            RoleSessionName='create-api-gateway',
            ExternalId='fraudes-diners-eb'
        )
        
        credentials = assumed_role['Credentials']
        
        # Guardar credenciales en variables de entorno
        os.environ['AWS_ACCESS_KEY_ID'] = credentials['AccessKeyId']
        os.environ['AWS_SECRET_ACCESS_KEY'] = credentials['SecretAccessKey']
        os.environ['AWS_SESSION_TOKEN'] = credentials['SessionToken']
        
        print("✅ Rol asumido exitosamente\n")
        return True
        
    except Exception as e:
        print(f"❌ Error asumiendo rol: {str(e)}\n")
        return False

def create_api_gateway():
    """Crear API Gateway con credenciales asumidas"""
    try:
        # Crear nuevo cliente con credenciales asumidas
        api_gateway = boto3.client('apigateway', region_name='us-east-1')
        iam = boto3.client('iam', region_name='us-east-1')
        
        print("\n" + "="*70)
        print("CREANDO API GATEWAY CON CREDENCIALES ASUMIDAS")
        print("="*70 + "\n")
        
        # PASO 1: Crear API
        print("1️⃣ Creando API Gateway...")
        api_response = api_gateway.create_rest_api(
            name='fraudes-api-prod',
            description='API para detección de fraudes con SageMaker',
            endpointConfiguration={'types': ['REGIONAL']}
        )
        api_id = api_response['id']
        print(f"✅ API creada: {api_id}\n")
        
        # PASO 2: Obtener root resource
        print("2️⃣ Obteniendo recurso raíz...")
        resources = api_gateway.get_resources(restApiId=api_id, limit=100)
        root_id = next(r['id'] for r in resources['items'] if r['path'] == '/')
        print(f"✅ Root ID: {root_id}\n")
        
        # PASO 3: Crear recurso /fraude
        print("3️⃣ Creando recurso /fraude...")
        resource_response = api_gateway.create_resource(
            restApiId=api_id,
            parentId=root_id,
            pathPart='fraude'
        )
        resource_id = resource_response['id']
        print(f"✅ Recurso creado: {resource_id}\n")
        
        # PASO 4: Crear método POST
        print("4️⃣ Creando método POST...")
        api_gateway.put_method(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST',
            authorizationType='NONE'
        )
        print("✅ Método POST creado\n")
        
        # PASO 5: Obtener rol de IAM
        print("5️⃣ Obteniendo rol IAM...")
        role = iam.get_role(RoleName='apigateway-sagemaker-proxy')
        role_arn = role['Role']['Arn']
        print(f"✅ Rol encontrado: {role_arn}\n")
        
        # PASO 6: Crear integración con SageMaker
        print("6️⃣ Configurando integración con SageMaker...")
        uri = "arn:aws:apigateway:us-east-1:runtime.sagemaker:path/endpoints/endpoint-fraudes-v5/invocations"
        
        api_gateway.put_integration(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST',
            type='AWS',
            integrationHttpMethod='POST',
            uri=uri,
            credentials=role_arn
        )
        print(f"✅ Integración SageMaker configurada\n")
        
        # PASO 7: Crear método response
        print("7️⃣ Configurando responses...")
        api_gateway.put_method_response(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST',
            statusCode='200'
        )
        api_gateway.put_integration_response(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST',
            statusCode='200',
            responseTemplates={'application/json': ''}
        )
        print("✅ Responses configurados\n")
        
        # PASO 8: Desplegar
        print("8️⃣ Desplegando API...")
        api_gateway.create_deployment(
            restApiId=api_id,
            stageName='prod'
        )
        print("✅ API desplegada\n")
        
        # Guardar configuración
        with open('api-id.txt', 'w') as f:
            f.write(api_id)
        with open('resource-id.txt', 'w') as f:
            f.write(resource_id)
        with open('role-arn.txt', 'w') as f:
            f.write(role_arn)
        
        invoke_url = f"https://{api_id}.execute-api.us-east-1.amazonaws.com/prod/fraude"
        with open('api-invoke-url.txt', 'w') as f:
            f.write(invoke_url)
        
        # Resultado final
        print("╔" + "="*68 + "╗")
        print("║" + " "*15 + "🎉 API GATEWAY CREADA EXITOSAMENTE 🎉" + " "*15 + "║")
        print("╚" + "="*68 + "╝\n")
        
        print("📍 DETALLES:")
        print(f"   API ID: {api_id}")
        print(f"   Resource ID: {resource_id}")
        print(f"   Rol ARN: {role_arn}\n")
        
        print("📍 URL DE INVOCACIÓN:")
        print(f"   {invoke_url}\n")
        
        print("✅ Configuración guardada en archivos .txt\n")
        
        return True
        
    except ClientError as e:
        print(f"\n❌ Error de AWS: {e.response['Error']['Message']}\n")
        return False
    except Exception as e:
        print(f"\n❌ Error: {str(e)}\n")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("\n" + "="*70)
    print("CREADOR DE API GATEWAY - FRAUDES DINERS")
    print("="*70 + "\n")
    
    # Asumir rol primero
    if not assume_role():
        return False
    
    # Crear API Gateway
    if not create_api_gateway():
        return False
    
    print("\n" + "="*70)
    print("PRÓXIMOS PASOS:")
    print("="*70)
    print("""
1. Abre Postman

2. Crea un POST a:
   https://<API_ID>.execute-api.us-east-1.amazonaws.com/prod/fraude

3. Body (JSON):
   {
       "transaction_id": "TRX123456",
       "monto": 150.50,
       "edad": 35,
       "ciudad": "Quito",
       "establecimiento": "RestaurantXYZ",
       "especialidad": "RESTAURANTES"
   }

4. Send!
    """)
    
    return True

if __name__ == '__main__':
    import sys
    success = main()
    sys.exit(0 if success else 1)
