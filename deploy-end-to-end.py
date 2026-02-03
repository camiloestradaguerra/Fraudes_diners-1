#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Deploy end-to-end: Push Docker a ECR + CloudFormation

Con imagen Docker ya construida localmente.

Uso:
    python deploy-end-to-end.py --stack-name fraudes-prod
"""

import boto3
import subprocess
import sys
import time
import json
import io
import argparse
from pathlib import Path
from botocore.exceptions import ClientError

# Configurar stdout para UTF-8 en Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


class EndToEndDeployer:
    """Desplegador end-to-end: ECR Push + CloudFormation"""
    
    def __init__(self, region='us-east-1', stack_name='fraudes-prod'):
        self.region = region
        self.stack_name = stack_name
        self.account_id = boto3.client('sts').get_caller_identity()['Account']
        self.ecr_client = boto3.client('ecr', region_name=region)
        self.cf_client = boto3.client('cloudformation', region_name=region)
        
        self.image_name = 'fraud-detection-api'
        self.image_tag = 'latest'
        self.image_uri = f"{self.account_id}.dkr.ecr.{region}.amazonaws.com/{self.image_name}:{self.image_tag}"
    
    def print_banner(self):
        """Imprimir banner"""
        print("\n" + "="*70)
        print("DEPLOY END-TO-END: ECR Push + CloudFormation")
        print("="*70)
        print(f"[*] Cuenta: {self.account_id}")
        print(f"[*] Region: {self.region}")
        print(f"[*] Stack: {self.stack_name}")
        print(f"[*] Imagen: {self.image_uri}\n")
    
    def step(self, num, title):
        """Imprimir paso"""
        print("\n" + "="*70)
        print(f"[PASO {num}] {title}")
        print("="*70)
    
    def push_to_ecr(self):
        """Pushear imagen a ECR"""
        self.step(1, "Push Docker a ECR")
        
        try:
            # Crear repositorio si no existe
            try:
                self.ecr_client.describe_repositories(repositoryNames=[self.image_name])
                print(f"[OK] Repositorio ya existe: {self.image_name}")
            except ClientError as e:
                if 'RepositoryNotFoundException' in str(e):
                    print(f"[CREATE] Creando repositorio: {self.image_name}...")
                    self.ecr_client.create_repository(
                        repositoryName=self.image_name,
                        imageScanningConfiguration={'scanOnPush': True}
                    )
                    print("[OK] Repositorio creado")
                else:
                    raise
            
            # Obtener credenciales ECR
            print("[AUTH] Obteniendo credenciales ECR...")
            auth = self.ecr_client.get_authorization_token()
            auth_data = auth['authorizationData'][0]
            
            import base64
            auth_token = base64.b64decode(auth_data['authorizationToken']).decode('utf-8')
            username, password = auth_token.split(':')
            registry = auth_data['proxyEndpoint'].replace('https://', '')
            
            # Docker login
            print(f"[LOGIN] Login a ECR...")
            result = subprocess.run(
                f'docker login -u {username} -p {password} {registry}',
                shell=True,
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode != 0:
                print(f"[ERROR] {result.stderr}")
                return False
            
            # Tag
            print(f"[TAG] Tagging imagen...")
            subprocess.run(
                ['docker', 'tag', f'{self.image_name}:{self.image_tag}', self.image_uri],
                capture_output=True,
                timeout=60
            )
            
            # Push
            print(f"[PUSH] Pusheando a ECR...")
            result = subprocess.run(
                ['docker', 'push', self.image_uri],
                capture_output=True,
                text=True,
                timeout=600
            )
            if result.returncode != 0:
                print(f"[ERROR] {result.stderr}")
                return False
            
            print(f"[OK] Imagen en ECR: {self.image_uri}")
            return True
            
        except Exception as e:
            print(f"[ERROR] {e}")
            return False
    
    def deploy_cloudformation(self):
        """Desplegar CloudFormation"""
        self.step(2, "CloudFormation - SageMaker + Endpoint + API Gateway")
        
        try:
            # Validar template
            print("[VALIDAR] Template CloudFormation...")
            template_path = Path('infra-sagemaker-complete.yaml')
            if not template_path.exists():
                print(f"[ERROR] Template no encontrado: {template_path}")
                return False
            
            with open(template_path, 'r', encoding='utf-8') as f:
                template_body = f.read()
            
            self.cf_client.validate_template(TemplateBody=template_body)
            print("[OK] Template válido")
            
            # Crear rol SageMaker
            print("[CREATE] Rol SageMaker...")
            iam = boto3.client('iam')
            role_name = f'sagemaker-execution-{self.stack_name}'
            
            try:
                iam.get_role(RoleName=role_name)
                print(f"[OK] Rol ya existe: {role_name}")
            except:
                trust_policy = {
                    "Version": "2012-10-17",
                    "Statement": [{
                        "Effect": "Allow",
                        "Principal": {"Service": "sagemaker.amazonaws.com"},
                        "Action": "sts:AssumeRole"
                    }]
                }
                iam.create_role(
                    RoleName=role_name,
                    AssumeRolePolicyDocument=json.dumps(trust_policy),
                    ManagedPolicyArns=['arn:aws:iam::aws:policy/AmazonSageMakerFullAccess']
                )
                print(f"[OK] Rol creado: {role_name}")
            
            role_arn = f'arn:aws:iam::{self.account_id}:role/{role_name}'
            
            # Crear stack
            print("[STACK] Creando stack CloudFormation...")
            
            existing = self.check_stack_exists()
            if existing:
                print(f"[UPDATE] Stack existente: {existing['StackStatus']}")
                self.cf_client.update_stack(
                    StackName=self.stack_name,
                    TemplateBody=template_body,
                    Parameters=[
                        {'ParameterKey': 'ImageUri', 'ParameterValue': self.image_uri},
                        {'ParameterKey': 'SageMakerRoleArn', 'ParameterValue': role_arn}
                    ],
                    Capabilities=['CAPABILITY_NAMED_IAM']
                )
            else:
                print("[CREATE] Nuevo stack...")
                self.cf_client.create_stack(
                    StackName=self.stack_name,
                    TemplateBody=template_body,
                    Parameters=[
                        {'ParameterKey': 'ImageUri', 'ParameterValue': self.image_uri},
                        {'ParameterKey': 'SageMakerRoleArn', 'ParameterValue': role_arn}
                    ],
                    Capabilities=['CAPABILITY_NAMED_IAM']
                )
            
            # Esperar
            print("[WAIT] Esperando deployment...")
            return self.wait_for_stack()
            
        except Exception as e:
            print(f"[ERROR] {e}")
            return False
    
    def check_stack_exists(self):
        """Verificar si el stack existe"""
        try:
            response = self.cf_client.describe_stacks(StackName=self.stack_name)
            return response['Stacks'][0] if response['Stacks'] else None
        except:
            return None
    
    def wait_for_stack(self):
        """Esperar a que el stack termine"""
        start = time.time()
        while True:
            response = self.cf_client.describe_stacks(StackName=self.stack_name)
            stack = response['Stacks'][0]
            status = stack['StackStatus']
            elapsed = int(time.time() - start)
            
            print(f"  [{elapsed:3d}s] {status}")
            
            if 'COMPLETE' in status:
                print("[OK] Stack completado\n")
                self.print_outputs(stack)
                return True
            elif 'FAILED' in status or 'ROLLBACK' in status:
                print(f"[ERROR] {status}\n")
                return False
            
            time.sleep(20)
    
    def print_outputs(self, stack):
        """Imprimir outputs del stack"""
        if 'Outputs' in stack:
            print("[OUTPUTS]")
            for output in stack['Outputs']:
                key = output['OutputKey']
                value = output['OutputValue']
                print(f"  {key}: {value}")
                
                # Guardar archivos
                if key == 'ApiInvokeUrl':
                    with open('api-invoke-url.txt', 'w') as f:
                        f.write(value)
                    print(f"    [SAVED] api-invoke-url.txt")
                elif key == 'EndpointName':
                    with open('endpoint-name.txt', 'w') as f:
                        f.write(value)
                    print(f"    [SAVED] endpoint-name.txt")
    
    def deploy(self):
        """Deploy completo"""
        self.print_banner()
        
        # Push a ECR
        if not self.push_to_ecr():
            return False
        
        # CloudFormation
        if not self.deploy_cloudformation():
            return False
        
        print("="*70)
        print("✅ DEPLOY COMPLETADO")
        print("="*70)
        
        return True


def main():
    parser = argparse.ArgumentParser(description='Deploy end-to-end')
    parser.add_argument('--stack-name', default='fraudes-prod', help='Nombre del stack')
    parser.add_argument('--region', default='us-east-1', help='Región AWS')
    
    args = parser.parse_args()
    
    deployer = EndToEndDeployer(
        region=args.region,
        stack_name=args.stack_name
    )
    
    success = deployer.deploy()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
