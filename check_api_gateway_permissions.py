#!/usr/bin/env python3
"""
Script de diagnóstico para verificar permisos de API Gateway
"""
import boto3
import json
from botocore.exceptions import ClientError

def check_permissions():
    """Verificar todos los permisos necesarios"""
    
    print("\n" + "="*70)
    print("🔍 DIAGNÓSTICO DE PERMISOS - API GATEWAY")
    print("="*70 + "\n")
    
    # Crear clientes
    iam = boto3.client('iam', region_name='us-east-1')
    sts = boto3.client('sts', region_name='us-east-1')
    api_gw = boto3.client('apigateway', region_name='us-east-1')
    
    # 1. Verificar identidad actual
    print("1️⃣ IDENTIDAD ACTUAL")
    print("-" * 70)
    try:
        identity = sts.get_caller_identity()
        print(f"✅ Account ID: {identity['Account']}")
        print(f"✅ User ARN: {identity['Arn']}")
        print(f"✅ User ID: {identity['UserId']}\n")
    except Exception as e:
        print(f"❌ Error: {str(e)}\n")
        return False
    
    # 2. Verificar acceso a API Gateway
    print("2️⃣ ACCESO A API GATEWAY")
    print("-" * 70)
    try:
        apis = api_gw.get_rest_apis(limit=1)
        print(f"✅ Puedo listar APIs (intenté get_rest_apis)")
        print(f"   → Resultado: {len(apis['items'])} APIs encontradas\n")
    except ClientError as e:
        if e.response['Error']['Code'] == 'AccessDeniedException':
            print(f"❌ NO TENGO PERMISO para apigateway:GET")
            print(f"   → Error: {e.response['Error']['Message']}\n")
            return False
        else:
            print(f"❌ Error: {e.response['Error']['Message']}\n")
            return False
    except Exception as e:
        print(f"❌ Error inesperado: {str(e)}\n")
        return False
    
    # 3. Verificar acceso a IAM
    print("3️⃣ ACCESO A IAM")
    print("-" * 70)
    try:
        role = iam.get_role(RoleName='apigateway-sagemaker-proxy')
        print(f"✅ Puedo acceder al rol IAM")
        print(f"   → Rol: {role['Role']['RoleName']}")
        print(f"   → ARN: {role['Role']['Arn']}\n")
    except ClientError as e:
        if 'AccessDenied' in str(e):
            print(f"❌ NO TENGO PERMISO para iam:GetRole")
            print(f"   → Error: {e}\n")
            return False
        elif 'NoSuchEntity' in str(e):
            print(f"⚠️ El rol NO EXISTE")
            print(f"   → Necesita ser creado\n")
            return False
        else:
            print(f"❌ Error: {str(e)}\n")
            return False
    except Exception as e:
        print(f"❌ Error inesperado: {str(e)}\n")
        return False
    
    # 4. Verificar acceso a SageMaker
    print("4️⃣ ACCESO A SAGEMAKER")
    print("-" * 70)
    try:
        sagemaker = boto3.client('sagemaker', region_name='us-east-1')
        endpoint = sagemaker.describe_endpoint(EndpointName='endpoint-fraudes-v5')
        print(f"✅ Puedo acceder a SageMaker")
        print(f"   → Endpoint: {endpoint['EndpointName']}")
        print(f"   → Estado: {endpoint['EndpointStatus']}\n")
    except ClientError as e:
        if 'AccessDenied' in str(e):
            print(f"❌ NO TENGO PERMISO para sagemaker:DescribeEndpoint")
            print(f"   → Error: {e}\n")
        elif 'ValidationException' in str(e):
            print(f"⚠️ Endpoint NO EXISTE")
            print(f"   → Error: {e}\n")
        else:
            print(f"❌ Error: {str(e)}\n")
    except Exception as e:
        print(f"❌ Error: {str(e)}\n")
    
    # 5. Resumen de permisos necesarios
    print("5️⃣ PERMISOS REQUERIDOS PARA API GATEWAY")
    print("-" * 70)
    required_permissions = [
        "apigateway:CreateRestApi",
        "apigateway:CreateResource",
        "apigateway:PutMethod",
        "apigateway:PutIntegration",
        "apigateway:PutIntegrationResponse",
        "apigateway:CreateDeployment",
        "iam:PassRole",
        "iam:GetRole"
    ]
    
    for perm in required_permissions:
        print(f"  • {perm}")
    
    print("\n" + "="*70)
    print("✅ DIAGNÓSTICO COMPLETADO")
    print("="*70 + "\n")
    
    return True

if __name__ == '__main__':
    try:
        check_permissions()
    except Exception as e:
        print(f"\n❌ ERROR CRÍTICO: {str(e)}")
        import traceback
        traceback.print_exc()
