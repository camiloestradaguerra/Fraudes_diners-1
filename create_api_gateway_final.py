#!/usr/bin/env python3
"""
Script para crear toda la estructura de API Gateway desde cero
"""
import boto3
import json
import sys

def main():
    try:
        # Clientes
        api_gateway = boto3.client('apigateway', region_name='us-east-1')
        
        print("\n" + "="*70)
        print("CREANDO API GATEWAY COMPLETA")
        print("="*70 + "\n")
        
        # PASO 1: Crear API
        print("1️⃣ Creando API Gateway...")
        try:
            api_response = api_gateway.create_rest_api(
                name='fraudes-api-v2',
                description='API para detección de fraudes con SageMaker',
                endpointConfiguration={'types': ['REGIONAL']}
            )
            api_id = api_response['id']
            print(f"✅ API creada: {api_id}\n")
        except api_gateway.exceptions.BadRequestException as e:
            if 'already exists' in str(e):
                print("ℹ️ API ya existe. Buscando...\n")
                apis = api_gateway.get_rest_apis(limit=100)
                api = next((a for a in apis['items'] if a['name'] == 'fraudes-api-v2'), None)
                if api:
                    api_id = api['id']
                    print(f"✅ API encontrada: {api_id}\n")
                else:
                    print("❌ API no encontrada\n")
                    return False
            else:
                print(f"❌ Error: {str(e)}\n")
                return False
        
        # PASO 2: Obtener root resource
        print("2️⃣ Obteniendo recurso raíz...")
        resources = api_gateway.get_resources(restApiId=api_id, limit=100)
        root_id = next(r['id'] for r in resources['items'] if r['path'] == '/')
        print(f"✅ Root ID: {root_id}\n")
        
        # PASO 3: Crear recurso /fraude
        print("3️⃣ Creando recurso /fraude...")
        try:
            resource_response = api_gateway.create_resource(
                restApiId=api_id,
                parentId=root_id,
                pathPart='fraude'
            )
            resource_id = resource_response['id']
            print(f"✅ Recurso creado: {resource_id}\n")
        except api_gateway.exceptions.ConflictException:
            print("ℹ️ Recurso ya existe. Obteniendo ID...\n")
            resources = api_gateway.get_resources(restApiId=api_id)
            resource = next(r for r in resources['items'] if r.get('pathPart') == 'fraude')
            resource_id = resource['id']
            print(f"✅ Recurso encontrado: {resource_id}\n")
        
        # PASO 4: Crear método POST
        print("4️⃣ Creando método POST...")
        try:
            api_gateway.put_method(
                restApiId=api_id,
                resourceId=resource_id,
                httpMethod='POST',
                authorizationType='NONE'
            )
            print("✅ Método POST creado\n")
        except api_gateway.exceptions.ConflictException:
            print("ℹ️ Método ya existe\n")
        
        # PASO 5: Crear integración con SageMaker
        print("5️⃣ Configurando integración con SageMaker...")
        
        # Obtener ARN del rol
        iam = boto3.client('iam', region_name='us-east-1')
        try:
            role = iam.get_role(RoleName='apigateway-sagemaker-proxy')
            role_arn = role['Role']['Arn']
        except:
            print("❌ Rol no encontrado\n")
            return False
        
        # URI correcto para SageMaker (no AWS_PROXY)
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
        
        # PASO 6: Crear método response
        print("6️⃣ Configurando responses...")
        api_gateway.put_method_response(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST',
            statusCode='200'
        )
        print("✅ Method response configurado\n")
        
        # PASO 7: Crear integration response
        api_gateway.put_integration_response(
            restApiId=api_id,
            resourceId=resource_id,
            httpMethod='POST',
            statusCode='200',
            responseTemplates={'application/json': ''}
        )
        print("✅ Integration response configurado\n")
        
        # PASO 8: Desplegar
        print("7️⃣ Desplegando API...")
        deployment = api_gateway.create_deployment(
            restApiId=api_id,
            stageName='prod'
        )
        print("✅ Deployment completado\n")
        
        # Guardar IDs
        with open('api-id.txt', 'w') as f:
            f.write(api_id)
        with open('resource-id.txt', 'w') as f:
            f.write(resource_id)
        with open('role-arn.txt', 'w') as f:
            f.write(role_arn)
        
        # URL final
        invoke_url = f"https://{api_id}.execute-api.us-east-1.amazonaws.com/prod/fraude"
        with open('api-invoke-url.txt', 'w') as f:
            f.write(invoke_url)
        
        # Mostrar resultado
        print("╔" + "="*68 + "╗")
        print("║" + " "*15 + "🎉 API GATEWAY LISTA PARA USAR 🎉" + " "*17 + "║")
        print("╚" + "="*68 + "╝\n")
        
        print("📍 URL DE INVOCACIÓN:")
        print(f"   {invoke_url}\n")
        
        print("✅ Configuración completada\n")
        return True
        
    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
