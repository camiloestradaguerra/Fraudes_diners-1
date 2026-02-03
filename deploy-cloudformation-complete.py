#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Deploy CloudFormation completo con CodeBuild integrado.

Uso:
    python deploy-cloudformation-complete.py --stack-name mi-stack
    python deploy-cloudformation-complete.py --stack-name mi-stack --region us-west-2
"""

import boto3
import json
import sys
import time
import argparse
import io
from pathlib import Path
from botocore.exceptions import ClientError

# Configurar stdout para UTF-8 en Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


class CloudFormationDeployer:
    """Desplegador de CloudFormation con CodeBuild integrado"""
    
    def __init__(self, region='us-east-1', stack_name='fraudes-stack'):
        """Inicializar el deployer"""
        self.region = region
        self.stack_name = stack_name
        self.cf_client = boto3.client('cloudformation', region_name=region)
        self.codebuild_client = boto3.client('codebuild', region_name=region)
        self.account_id = boto3.client('sts').get_caller_identity()['Account']
    
    def print_banner(self):
        """Imprimir banner"""
        print("\n" + "="*70)
        print("DEPLOY CLOUDFORMATION COMPLETO (TODO EN CF + CodeBuild)")
        print("="*70)
        print(f"[*] Cuenta: {self.account_id}")
        print(f"[*] Region: {self.region}")
        print(f"[*] Stack: {self.stack_name}\n")
    
    def validate_template(self):
        """Validar template CloudFormation"""
        print("[VALIDANDO] Template CloudFormation...")
        try:
            template_path = Path('infra-complete-codebuild.yaml')
            if not template_path.exists():
                print(f"[ERROR] Template no encontrado: {template_path}")
                return False
            
            with open(template_path, 'r', encoding='utf-8') as f:
                template_body = f.read()
            
            self.cf_client.validate_template(TemplateBody=template_body)
            print("[OK] Template válido\n")
            return template_body
        except ClientError as e:
            print(f"[ERROR] {e}\n")
            return False
    
    def check_stack_exists(self):
        """Verificar si el stack ya existe"""
        try:
            response = self.cf_client.describe_stacks(StackName=self.stack_name)
            return response['Stacks'][0] if response['Stacks'] else None
        except ClientError as e:
            if 'does not exist' in str(e):
                return None
            raise
    
    def create_or_update_stack(self, template_body):
        """Crear o actualizar el stack"""
        print("[PREPARANDO] Enviando template a CloudFormation...")
        
        try:
            existing_stack = self.check_stack_exists()
            
            if existing_stack:
                print(f"[UPDATE] Stack existente detectado ({existing_stack['StackStatus']})")
                print("[UPDATE] Actualizando stack...")
                
                self.cf_client.update_stack(
                    StackName=self.stack_name,
                    TemplateBody=template_body,
                    Capabilities=['CAPABILITY_NAMED_IAM']
                )
                
                operation = 'UPDATE'
            else:
                print("[CREATE] Stack no existe, creando nuevo...")
                
                self.cf_client.create_stack(
                    StackName=self.stack_name,
                    TemplateBody=template_body,
                    Capabilities=['CAPABILITY_NAMED_IAM']
                )
                
                operation = 'CREATE'
            
            return operation
        except ClientError as e:
            if 'No updates are to be performed' in str(e):
                print("[SKIP] No hay cambios para actualizar")
                return None
            print(f"[ERROR] {e}")
            return False
    
    def wait_for_stack(self, operation):
        """Esperar a que el stack se complete"""
        if operation is None:
            return True
        
        print(f"\n[ESPERANDO] Deployment {operation}...\n")
        
        try:
            waiter_name = f'stack_{operation.lower()}_complete'
            waiter = self.cf_client.get_waiter(waiter_name)
            
            # Callback para mostrar progreso
            start_time = time.time()
            while True:
                try:
                    response = self.cf_client.describe_stacks(StackName=self.stack_name)
                    stack = response['Stacks'][0]
                    status = stack['StackStatus']
                    elapsed = int(time.time() - start_time)
                    
                    print(f"  [{elapsed:3d}s] Status: {status}")
                    
                    if 'COMPLETE' in status:
                        print(f"\n[OK] Stack {operation} completado exitosamente\n")
                        return True
                    elif 'FAILED' in status or 'ROLLBACK' in status:
                        print(f"\n[ERROR] Stack {operation} falló: {status}\n")
                        self.print_stack_events()
                        return False
                    
                    time.sleep(20)
                except Exception as e:
                    print(f"[ERROR] {e}")
                    return False
        except ClientError as e:
            print(f"[ERROR] {e}")
            return False
    
    def print_stack_events(self):
        """Imprimir eventos del stack"""
        try:
            response = self.cf_client.describe_stack_events(StackName=self.stack_name)
            
            failed_events = [
                e for e in response['StackEvents']
                if 'FAILED' in e['ResourceStatus']
            ]
            
            if failed_events:
                print("[EVENTOS] Últimos errores:")
                for event in failed_events[:5]:
                    print(f"  [{event['Timestamp']}] {event['LogicalResourceId']}: {event['ResourceStatusReason']}")
        except:
            pass
    
    def get_stack_outputs(self):
        """Obtener outputs del stack"""
        try:
            response = self.cf_client.describe_stacks(StackName=self.stack_name)
            stack = response['Stacks'][0]
            
            outputs = {}
            for output in stack.get('Outputs', []):
                outputs[output['OutputKey']] = output['OutputValue']
            
            return outputs
        except:
            return {}
    
    def print_results(self):
        """Imprimir resultados"""
        outputs = self.get_stack_outputs()
        
        if outputs:
            print("[RESULTADOS]")
            for key, value in outputs.items():
                if 'Url' in key or 'Uri' in key:
                    print(f"  {key}: {value}")
                else:
                    print(f"  {key}: {value}")
            
            # Guardar configuración
            print("\n[GUARDANDO] Configuración...")
            
            if 'ApiInvokeUrl' in outputs:
                with open('api-invoke-url.txt', 'w') as f:
                    f.write(outputs['ApiInvokeUrl'])
                print("  [OK] api-invoke-url.txt")
            
            if 'EndpointName' in outputs:
                with open('endpoint-name.txt', 'w') as f:
                    f.write(outputs['EndpointName'])
                print("  [OK] endpoint-name.txt")
            
            config = {
                'stack_name': self.stack_name,
                'region': self.region,
                'outputs': outputs
            }
            
            with open('deployment-config.json', 'w') as f:
                json.dump(config, f, indent=2)
            print("  [OK] deployment-config.json")
    
    def deploy(self):
        """Ejecutar el deploy completo"""
        self.print_banner()
        
        # 1. Validar template
        template_body = self.validate_template()
        if not template_body:
            return False
        
        # 2. Crear o actualizar stack
        operation = self.create_or_update_stack(template_body)
        if operation is False:
            return False
        
        # 3. Esperar a que termine
        success = self.wait_for_stack(operation)
        if not success:
            return False
        
        # 4. Mostrar resultados
        self.print_results()
        
        print("\n" + "="*70)
        print("✅ DEPLOY COMPLETADO EXITOSAMENTE")
        print("="*70)
        print("\n📝 PRÓXIMOS PASOS:")
        print("1. Ejecutar CodeBuild manualmente para Docker build:")
        print(f"   aws codebuild start-build --project-name fraud-detection-docker-build-{self.stack_name}")
        print("\n2. Invocar el API:")
        print(f"   curl -X POST $(cat api-invoke-url.txt) \\")
        print("     -H 'Content-Type: application/json' \\")
        print("     -d '{...}'")
        print("\n")
        
        return True


def main():
    """Función principal"""
    parser = argparse.ArgumentParser(
        description='Deploy CloudFormation completo con CodeBuild integrado'
    )
    parser.add_argument('--stack-name', default='fraudes-prod', help='Nombre del stack')
    parser.add_argument('--region', default='us-east-1', help='Región AWS')
    
    args = parser.parse_args()
    
    deployer = CloudFormationDeployer(
        region=args.region,
        stack_name=args.stack_name
    )
    
    success = deployer.deploy()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
