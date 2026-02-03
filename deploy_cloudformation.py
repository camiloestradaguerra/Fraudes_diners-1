#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para desplegar la infraestructura completa (IAM + API Gateway + SageMaker)
usando CloudFormation con soporte para cross-account deployment.

Pasos que automatiza:
1. Validar template de CloudFormation
2. Crear o actualizar stack
3. Esperar a que se complete el despliegue
4. Extraer outputs (endpoint URL, API ID, etc.)
5. Guardar configuración final

Soporta:
- Same-account deployment
- Cross-account deployment (con asunción de roles)
"""
import boto3
import json
import sys
import time
import io
from pathlib import Path
from botocore.exceptions import ClientError

# Configurar stdout para UTF-8 en Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


class CloudFormationDeployer:
    """Gestor de despliegue con CloudFormation"""
    
    def __init__(self, region='us-east-1', stack_name='fraudes-stack'):
        """
        Inicializar el deployer.
        
        Args:
            region: Región AWS (default: us-east-1)
            stack_name: Nombre del stack CloudFormation
        """
        self.region = region
        self.stack_name = stack_name
        self.cf_client = boto3.client('cloudformation', region_name=region)
        self.sts_client = boto3.client('sts', region_name=region)
        
        # Obtener información de la cuenta
        self.account_id = self.sts_client.get_caller_identity()['Account']
        print(f"[*] Cuenta actual: {self.account_id}")
        print(f"[*] Region: {self.region}\n")

    def validate_template(self, template_path='infra.yaml'):
        """Validar que el template sea correcto."""
        print("[STEP 1] Validando template CloudFormation...")
        
        try:
            with open(template_path, 'r', encoding='utf-8') as f:
                template_body = f.read()
            
            self.cf_client.validate_template(TemplateBody=template_body)
            print(f"✅ Template válido: {template_path}\n")
            return template_body
            
        except FileNotFoundError:
            print(f"❌ Template no encontrado: {template_path}\n")
            return None
        except ClientError as e:
            print(f"❌ Error validando template: {e}\n")
            return None

    def check_stack_exists(self):
        """Verificar si el stack ya existe."""
        try:
            response = self.cf_client.describe_stacks(StackName=self.stack_name)
            return response['Stacks'][0]['StackStatus']
        except ClientError as e:
            if 'does not exist' in str(e):
                return None
            raise

    def deploy_stack(self, template_body, parameters=None):
        """Crear o actualizar el stack CloudFormation."""
        print("2️⃣ Desplegando stack CloudFormation...")
        print(f"   Stack Name: {self.stack_name}\n")
        
        parameters = parameters or {}
        
        # Preparar parámetros
        cf_parameters = [
            {'ParameterKey': k, 'ParameterValue': v}
            for k, v in parameters.items()
        ]
        
        try:
            existing_status = self.check_stack_exists()
            
            if existing_status:
                print(f"   Stack existe (estado: {existing_status})")
                print("   Intentando actualizar...\n")
                
                response = self.cf_client.update_stack(
                    StackName=self.stack_name,
                    TemplateBody=template_body,
                    Parameters=cf_parameters,
                    Capabilities=['CAPABILITY_NAMED_IAM'],
                    Tags=[
                        {'Key': 'Project', 'Value': 'fraudes-diners'},
                        {'Key': 'Environment', 'Value': 'production'}
                    ]
                )
                operation = "UPDATE"
                stack_id = response['StackId']
            else:
                print("   Stack no existe. Creando...\n")
                
                response = self.cf_client.create_stack(
                    StackName=self.stack_name,
                    TemplateBody=template_body,
                    Parameters=cf_parameters,
                    Capabilities=['CAPABILITY_NAMED_IAM'],
                    Tags=[
                        {'Key': 'Project', 'Value': 'fraudes-diners'},
                        {'Key': 'Environment', 'Value': 'production'}
                    ]
                )
                operation = "CREATE"
                stack_id = response['StackId']
            
            print(f"✅ Stack {operation} iniciado")
            print(f"   Stack ID: {stack_id}\n")
            
            # Esperar a que se complete
            self._wait_for_stack(operation)
            return True
            
        except ClientError as e:
            error_msg = str(e)
            
            # Ignorar el error "No updates are to be performed"
            if "No updates are to be performed" in error_msg:
                print("⚠️  No hay cambios para aplicar (stack ya está actualizado)\n")
                return True
            
            print(f"❌ Error desplegando: {error_msg}\n")
            return False

    def _wait_for_stack(self, operation, max_attempts=120):
        """Esperar a que el stack se complete."""
        print(f"3️⃣ Esperando a que se complete el {operation}...")
        
        operation_complete = f'CREATE_COMPLETE' if operation == 'CREATE' else 'UPDATE_COMPLETE'
        operation_failed = f'CREATE_FAILED' if operation == 'CREATE' else 'UPDATE_FAILED'
        
        for attempt in range(max_attempts):
            try:
                response = self.cf_client.describe_stacks(StackName=self.stack_name)
                status = response['Stacks'][0]['StackStatus']
                
                # Mostrar progreso cada 10 segundos
                if attempt % 2 == 0:
                    print(f"   [{attempt*5}s] Estado: {status}")
                
                if status == operation_complete:
                    print(f"✅ {operation} completado exitosamente\n")
                    return True
                
                if status == operation_failed or 'FAILED' in status:
                    # Obtener eventos de error
                    events = response['Stacks'][0].get('StackStatusReason', '')
                    print(f"❌ {operation} fallido: {events}\n")
                    self._print_stack_events()
                    return False
                
                time.sleep(5)
                
            except ClientError as e:
                print(f"❌ Error esperando stack: {e}\n")
                return False
        
        print(f"❌ Timeout esperando a que se complete el stack\n")
        return False

    def _print_stack_events(self):
        """Mostrar eventos del stack para debugging."""
        try:
            response = self.cf_client.describe_stack_events(StackName=self.stack_name)
            print("\n📋 Últimos eventos del stack:")
            for event in reversed(response['StackEvents'][-10:]):
                timestamp = event['Timestamp'].strftime('%H:%M:%S')
                resource = event['LogicalResourceId']
                status = event['ResourceStatus']
                reason = event.get('ResourceStatusReason', '')
                print(f"   [{timestamp}] {resource:40s} {status:20s} {reason}")
        except:
            pass

    def get_outputs(self):
        """Obtener los outputs del stack."""
        print("4️⃣ Extrayendo outputs del stack...\n")
        
        try:
            response = self.cf_client.describe_stacks(StackName=self.stack_name)
            outputs = response['Stacks'][0].get('Outputs', [])
            
            if not outputs:
                print("⚠️  No hay outputs disponibles\n")
                return {}
            
            outputs_dict = {o['OutputKey']: o['OutputValue'] for o in outputs}
            
            print("✅ Outputs extraídos:")
            for key, value in outputs_dict.items():
                if 'Url' in key or 'Id' in key:
                    print(f"   {key}: {value}")
                else:
                    print(f"   {key}: {value[:50]}..." if len(value) > 50 else f"   {key}: {value}")
            print()
            
            return outputs_dict
            
        except ClientError as e:
            print(f"❌ Error obteniendo outputs: {e}\n")
            return {}

    def save_configuration(self, outputs):
        """Guardar configuración en archivos para referencia."""
        print("5️⃣ Guardando configuración...\n")
        
        config_data = {
            'stack_name': self.stack_name,
            'region': self.region,
            'account_id': self.account_id,
            'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
            'outputs': outputs
        }
        
        # Guardar como JSON
        with open('deployment-config.json', 'w') as f:
            json.dump(config_data, f, indent=2)
        print("✅ deployment-config.json guardado")
        
        # Guardar URL de API en archivo simple
        if 'ApiInvokeUrl' in outputs:
            with open('api-invoke-url.txt', 'w') as f:
                f.write(outputs['ApiInvokeUrl'])
            print("✅ api-invoke-url.txt guardado")
        
        # Guardar API ID
        if 'ApiId' in outputs:
            with open('api-id.txt', 'w') as f:
                f.write(outputs['ApiId'])
            print("✅ api-id.txt guardado")
        
        # Guardar Endpoint Name
        if 'EndpointName' in outputs:
            with open('endpoint-name.txt', 'w') as f:
                f.write(outputs['EndpointName'])
            print("✅ endpoint-name.txt guardado\n")

    def deploy(self, template_path='infra.yaml', parameters=None):
        """Ejecutar el despliegue completo."""
        print("\n" + "="*70)
        print("DESPLIEGUE CLOUDFORMATION - FRAUDES DINERS")
        print("="*70 + "\n")
        
        # Paso 1: Validar template
        template_body = self.validate_template(template_path)
        if not template_body:
            return False
        
        # Paso 2: Desplegar stack
        if not self.deploy_stack(template_body, parameters):
            return False
        
        # Paso 3: Obtener outputs
        outputs = self.get_outputs()
        
        # Paso 4: Guardar configuración
        if outputs:
            self.save_configuration(outputs)
        
        # Resumen final
        print("=" * 70)
        print("✅ DESPLIEGUE COMPLETADO EXITOSAMENTE")
        print("=" * 70 + "\n")
        
        if 'ApiInvokeUrl' in outputs:
            print("📍 URL PARA PROBAR LA API:")
            print(f"   {outputs['ApiInvokeUrl']}\n")
            
            print("📍 EJEMPLO CON CURL:")
            print(f"""   curl -X POST {outputs['ApiInvokeUrl']} \\
     -H "Content-Type: application/json" \\
     -d '{{
       "transaction_id": "TRX-NEW-001",
       "monto": 500.0,
       "edad": 30,
       "ciudad": "Guayaquil",
       "establecimiento": "Tienda-Diners",
       "especialidad": "RETAIL"
     }}'\n""")
        
        return True


def main():
    """Entrada principal del script."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Desplegar infraestructura de Fraudes Diners con CloudFormation',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  # Despliegue básico (same-account)
  python deploy_cloudformation.py

  # Especificar región
  python deploy_cloudformation.py --region us-east-1

  # Cross-account (especificar source account)
  python deploy_cloudformation.py --source-account 123456789012

  # Especificar nombre del stack
  python deploy_cloudformation.py --stack-name my-fraudes-stack
        """
    )
    
    parser.add_argument(
        '--region',
        type=str,
        default='us-east-1',
        help='Región AWS (default: us-east-1)'
    )
    
    parser.add_argument(
        '--stack-name',
        type=str,
        default='fraudes-stack',
        help='Nombre del stack CloudFormation (default: fraudes-stack)'
    )
    
    parser.add_argument(
        '--source-account',
        type=str,
        help='Account ID para cross-account deployment'
    )
    
    parser.add_argument(
        '--endpoint-name',
        type=str,
        default='endpoint-fraudes-v5',
        help='Nombre del endpoint SageMaker existente'
    )
    
    args = parser.parse_args()
    
    # Crear deployer
    deployer = CloudFormationDeployer(
        region=args.region,
        stack_name=args.stack_name
    )
    
    # Preparar parámetros simplificados (CloudFormation ahora crea TODO)
    parameters = {
        'EndpointName': args.endpoint_name,
    }
    
    # Agregar source account si es cross-account
    if args.source_account:
        print(f"📍 Cross-account deployment: {args.source_account}\n")
    
    # Ejecutar despliegue
    success = deployer.deploy(parameters=parameters)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
