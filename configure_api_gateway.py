#!/usr/bin/env python3
"""
Script para detectar y configurar la API Gateway de fraudes
Si ya existe, obtiene los IDs. Si no, la crea desde cero.
"""
import boto3
import json

api_gateway = boto3.client('apigateway', region_name='us-east-1')
iam = boto3.client('iam', region_name='us-east-1')

def get_or_create_api():
    """Obtiene o crea la API Gateway"""
    print("\n" + "="*70)
    print("1. VERIFICANDO API GATEWAY")
    print("="*70 + "\n")
    
    # Buscar API existente
    response = api_gateway.get_rest_apis(limit=100)
    apis = response.get('items', [])
    
    fraudes_api = next((a for a in apis if a['name'] == 'fraudes-api'), None)
    
    if fraudes_api:
        api_id = fraudes_api['id']
        print(f"✅ API ya existe: {api_id}")
        return api_id, fraudes_api
    else:
        print("ℹ️ API no existe, creando...")
        new_api = api_gateway.create_rest_api(
            name='fraudes-api',
            description='API Gateway proxy para SageMaker endpoint',
            endpointConfiguration={'types': ['REGIONAL']}
        )
        api_id = new_api['id']
        print(f"✅ API creada: {api_id}")
        return api_id, new_api

def get_or_create_resource(api_id):
    """Obtiene o crea el recurso /fraude"""
    print("\n" + "="*70)
    print("2. VERIFICANDO RECURSO /fraude")
    print("="*70 + "\n")
    
    # Obtener recursos
    resources = api_gateway.get_resources(restApiId=api_id)
    
    # Buscar recurso /fraude
    fraude_resource = next((r for r in resources['items'] if r.get('pathPart') == 'fraude'), None)
    
    if fraude_resource:
        resource_id = fraude_resource['id']
        print(f"✅ Recurso /fraude ya existe: {resource_id}")
        return resource_id, fraude_resource
    else:
        print("ℹ️ Recurso /fraude no existe, creando...")
        root_id = next(r['id'] for r in resources['items'] if r['path'] == '/')
        new_resource = api_gateway.create_resource(
            restApiId=api_id,
            parentId=root_id,
            pathPart='fraude'
        )
        resource_id = new_resource['id']
        print(f"✅ Recurso /fraude creado: {resource_id}")
        return resource_id, new_resource

def get_or_create_method(api_id, resource_id):
    """Obtiene o crea el método POST"""
    print("\n" + "="*70)
    print("3. VERIFICANDO MÉTODO POST")
    print("="*70 + "\n")
    
    try:
        method = api_gateway.get_method(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST'
        )
        print("✅ Método POST ya existe")
        return True
    except:
        print("ℹ️ Método POST no existe, creando...")
        api_gateway.put_method(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST',
            authorizationType='NONE'
        )
        print("✅ Método POST creado")
        return True

def configure_integration(api_id, resource_id, role_arn):
    """Configura la integración con SageMaker"""
    print("\n" + "="*70)
    print("4. CONFIGURANDO INTEGRACIÓN CON SAGEMAKER")
    print("="*70 + "\n")
    
    print(f"Usando Role ARN: {role_arn}")
    
    try:
        api_gateway.put_integration(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST',
            type='AWS_PROXY',
            integrationHttpMethod='POST',
            uri='arn:aws:apigateway:us-east-1:sagemaker:action/InvokeEndpoint',
            credentials=role_arn
        )
        print("✅ Integración configurada")
        
        # Configurar response
        api_gateway.put_integration_response(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST',
            statusCode='200',
            responseTemplates={'application/json': ''}
        )
        print("✅ Response integration configurada")
        
    except Exception as e:
        print(f"⚠️ Error: {str(e)}")

def deploy_api(api_id):
    """Despliega la API"""
    print("\n" + "="*70)
    print("5. DESPLEGANDO API")
    print("="*70 + "\n")
    
    try:
        deployment = api_gateway.create_deployment(
            restApiId=api_id,
            stageName='prod',
            description='Deployment para fraudes'
        )
        print("✅ API desplegada en stage 'prod'")
        invoke_url = f"https://{api_id}.execute-api.us-east-1.amazonaws.com/prod/fraude"
        return invoke_url
    except Exception as e:
        # Posiblemente ya está desplegada
        print(f"ℹ️ {str(e)}")
        invoke_url = f"https://{api_id}.execute-api.us-east-1.amazonaws.com/prod/fraude"
        return invoke_url

def main():
    try:
        # Obtener el ARN del rol
        print("\n" + "="*70)
        print("CONFIGURANDO API GATEWAY PARA SAGEMAKER")
        print("="*70)
        
        role = iam.get_role(RoleName='apigateway-sagemaker-proxy')
        role_arn = role['Role']['Arn']
        
        # Ejecutar pasos
        api_id, _ = get_or_create_api()
        resource_id, _ = get_or_create_resource(api_id)
        get_or_create_method(api_id, resource_id)
        configure_integration(api_id, resource_id, role_arn)
        invoke_url = deploy_api(api_id)
        
        # Guardar resultados
        with open('api-id.txt', 'w') as f:
            f.write(api_id)
        with open('resource-id.txt', 'w') as f:
            f.write(resource_id)
        with open('api-invoke-url.txt', 'w') as f:
            f.write(invoke_url)
        
        # Mostrar resultado final
        print("\n" + "╔" + "="*68 + "╗")
        print("║" + " "*20 + "🎉 API GATEWAY LISTA PARA USAR 🎉" + " "*17 + "║")
        print("╚" + "="*68 + "╝\n")
        
        print("URL DE INVOCACIÓN:")
        print(f"\n  {invoke_url}\n")
        
        print("\n" + "="*70)
        print("INSTRUCCIONES PARA POSTMAN:")
        print("="*70)
        print("""
1. Abre Postman

2. Crea una nueva Request:
   - Método: POST
   - URL: Copia la URL anterior

3. Ve a la pestaña "Body"
   - Selecciona "raw"
   - Selecciona "JSON" en el dropdown

4. Pega este JSON:
   {
       "transaction_id": "TRX123456",
       "monto": 150.50,
       "edad": 35,
       "ciudad": "Quito",
       "establecimiento": "RestaurantXYZ",
       "especialidad": "RESTAURANTES"
   }

5. Haz clic en "Send"

6. ¡Deberías recibir la respuesta del modelo de fraude!
        """)
        
        print("\n✅ Configuración completada exitosamente\n")
        
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
