#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script Orquestador Completo: Docker Build + ECR Push + CloudFormation Deploy

Automatiza el pipeline completo de MLOps:
1. Construir imagen Docker (si no existe o cambió código)
2. Pushear a ECR
3. Crear rol IAM para SageMaker
4. Desplegar con CloudFormation (Modelo + Endpoint + API Gateway)

Uso:
    python deploy-completo.py --stack-name mi-stack
    python deploy-completo.py --stack-name mi-stack --image-tag v2
    python deploy-completo.py --stack-name mi-stack --skip-docker
"""

import boto3
import json
import sys
import time
import subprocess
import hashlib
import os
import io
from pathlib import Path
from botocore.exceptions import ClientError

# Configurar stdout para UTF-8 en Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


class MLOpsOrchestrator:
    """Orquestador completo del pipeline MLOps"""
    
    def __init__(self, region='us-east-1', stack_name='fraudes-stack', image_tag='latest'):
        """
        Inicializar el orquestador.
        
        Args:
            region: Region AWS
            stack_name: Nombre del stack CloudFormation
            image_tag: Tag de la imagen Docker
        """
        self.region = region
        self.stack_name = stack_name
        self.image_tag = image_tag
        self.image_name = 'fraud-detection-api'
        
        # Clientes AWS
        self.ecr_client = boto3.client('ecr', region_name=region)
        self.iam_client = boto3.client('iam')
        self.cf_client = boto3.client('cloudformation', region_name=region)
        self.sts_client = boto3.client('sts', region_name=region)
        self.sagemaker_client = boto3.client('sagemaker', region_name=region)
        
        # Información de la cuenta
        self.account_id = self.sts_client.get_caller_identity()['Account']
        self.sagemaker_role_arn = None
        
        print(f"\n[*] Cuenta actual: {self.account_id}")
        print(f"[*] Region: {self.region}")
        print(f"[*] Stack: {stack_name}\n")

    def step(self, step_num, description):
        """Imprimir paso del proceso"""
        print(f"\n[PASO {step_num}] {description}")
        print("=" * 70)

    # ========================================================================
    # PASO 1: DOCKER BUILD (INTELIGENTE)
    # ========================================================================

    def docker_build(self, skip_docker=False):
        """Construir imagen Docker solo si no existe"""
        self.step(1, "Docker Build - Verificar/construir imagen local")
        
        if skip_docker:
            print("[SKIP] Docker build omitido (--skip-docker)")
            return True
        
        dockerfile_path = Path('Dockerfile')
        if not dockerfile_path.exists():
            print(f"[ERROR] Dockerfile no encontrado en {dockerfile_path.absolute()}")
            return False
        
        image_full_name = f"{self.image_name}:{self.image_tag}"
        
        # Verificar si la imagen ya existe localmente
        print(f"[CHECK] Verificando si imagen local existe: {image_full_name}...")
        result = subprocess.run(
            ['docker', 'images', '--filter', f'reference={image_full_name}', '--quiet'],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.stdout.strip():
            print(f"[OK] Imagen ya existe localmente: {image_full_name}")
            print(f"     ID: {result.stdout.strip()[:12]}...")
            return True
        
        # Imagen no existe, construir
        try:
            print(f"[BUILD] Construyendo imagen: {image_full_name}...")
            result = subprocess.run(
                ['docker', 'build', '-t', image_full_name, '.'],
                capture_output=True,
                text=True,
                timeout=600
            )
            
            if result.returncode != 0:
                print(f"[ERROR] Docker build falló:")
                print(result.stderr)
                return False
            
            print(f"[OK] Imagen construida: {image_full_name}")
            return True
            
        except FileNotFoundError:
            print("[ERROR] Docker no está instalado o no está en PATH")
            return False
        except subprocess.TimeoutExpired:
            print("[ERROR] Docker build timeout (> 10 minutos)")
            return False

    # ========================================================================
    # PASO 2: ECR SETUP
    # ========================================================================

    def ecr_setup(self):
        """Configurar ECR (crear repositorio si no existe)"""
        self.step(2, "ECR Setup - Crear/verificar repositorio")
        
        try:
            response = self.ecr_client.describe_repositories(
                repositoryNames=[self.image_name]
            )
            print(f"[OK] Repositorio ya existe: {self.image_name}")
            return True
            
        except ClientError as e:
            if 'RepositoryNotFoundException' in str(e):
                print(f"[CREANDO] Repositorio: {self.image_name}...")
                try:
                    self.ecr_client.create_repository(
                        repositoryName=self.image_name,
                        imageScanningConfiguration={'scanOnPush': True}
                    )
                    print(f"[OK] Repositorio creado: {self.image_name}")
                    return True
                except ClientError as create_error:
                    print(f"[ERROR] Fallo creando repositorio: {create_error}")
                    return False
            else:
                print(f"[ERROR] {e}")
                return False

    # ========================================================================
    # PASO 3: DOCKER PUSH A ECR (INTELIGENTE)
    # ========================================================================

    def docker_push_to_ecr(self):
        """Pushear imagen Docker a ECR solo si no existe"""
        self.step(3, "Docker Push - Verificar/subir imagen a ECR")
        
        # Construir URI
        image_uri = f"{self.account_id}.dkr.ecr.{self.region}.amazonaws.com/{self.image_name}:{self.image_tag}"
        
        try:
            # Verificar si la imagen ya existe en ECR
            print(f"[CHECK] Verificando si imagen existe en ECR: {self.image_name}:{self.image_tag}...")
            
            try:
                response = self.ecr_client.describe_images(
                    repositoryName=self.image_name,
                    imageIds=[{'imageTag': self.image_tag}]
                )
                
                if response['imageDetails']:
                    image_detail = response['imageDetails'][0]
                    print(f"[OK] Imagen ya existe en ECR")
                    print(f"     Pushed: {image_detail['imagePushedAt']}")
                    print(f"     Size: {image_detail.get('imageSizeInBytes', 0) / (1024*1024):.1f} MB")
                    print(f"     URI: {image_uri}")
                    return image_uri
            except ClientError as e:
                if 'ImageNotFound' not in str(e):
                    raise
            
            # Imagen no existe en ECR, pushear
            print(f"\n[PUSH] Imagen no existe en ECR, iniciando upload...")
            
            # Obtener token de autenticación
            print("[AUTH] Obteniendo credenciales ECR...")
            auth_response = self.ecr_client.get_authorization_token()
            auth_data = auth_response['authorizationData'][0]
            
            # Decodificar credenciales
            import base64
            auth_token = base64.b64decode(auth_data['authorizationToken']).decode('utf-8')
            username, password = auth_token.split(':')
            registry = auth_data['proxyEndpoint'].replace('https://', '')
            
            # Login a Docker
            print(f"[LOGIN] Docker login a {registry}...")
            result = subprocess.run(
                f"docker login -u {username} -p {password} {registry}",
                shell=True,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode != 0:
                print(f"[ERROR] Docker login falló:")
                print(result.stderr)
                return None
            
            print("[OK] Login exitoso")
            
            # Tag la imagen
            print(f"[TAG] Tagging imagen como {image_uri}...")
            result = subprocess.run(
                ['docker', 'tag', f"{self.image_name}:{self.image_tag}", image_uri],
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode != 0:
                print(f"[ERROR] Docker tag falló: {result.stderr}")
                return None
            
            # Push a ECR
            print(f"[PUSH] Pusheando a ECR...")
            result = subprocess.run(
                ['docker', 'push', image_uri],
                capture_output=True,
                text=True,
                timeout=600
            )
            
            if result.returncode != 0:
                print(f"[ERROR] Docker push falló:")
                print(result.stderr)
                return None
            
            print(f"[OK] Imagen subida: {image_uri}")
            return image_uri
            
        except FileNotFoundError:
            print("[ERROR] Docker no está instalado")
            return None
        except Exception as e:
            print(f"[ERROR] {e}")
            return None

    # ========================================================================
    # PASO 4: CREAR SAGEMAKER ROLE
    # ========================================================================

    def create_sagemaker_role(self):
        """Crear rol IAM para SageMaker si no existe"""
        self.step(4, "IAM Setup - Crear rol para SageMaker")
        
        role_name = f'sagemaker-execution-{self.stack_name}'
        
        try:
            # Verificar si existe
            response = self.iam_client.get_role(RoleName=role_name)
            self.sagemaker_role_arn = response['Role']['Arn']
            print(f"[OK] Rol ya existe: {role_name}")
            print(f"     ARN: {self.sagemaker_role_arn}")
            return True
            
        except ClientError as e:
            if 'NoSuchEntity' in str(e):
                print(f"[CREANDO] Rol: {role_name}...")
                
                assume_role_policy = {
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {"Service": "sagemaker.amazonaws.com"},
                            "Action": "sts:AssumeRole"
                        }
                    ]
                }
                
                try:
                    response = self.iam_client.create_role(
                        RoleName=role_name,
                        AssumeRolePolicyDocument=json.dumps(assume_role_policy),
                        Description="Rol de ejecución para SageMaker Endpoint"
                    )
                    
                    self.sagemaker_role_arn = response['Role']['Arn']
                    
                    # Adjuntar política managedarn
                    print(f"[ADJUNTANDO] Política AmazonSageMakerFullAccess...")
                    self.iam_client.attach_role_policy(
                        RoleName=role_name,
                        PolicyArn='arn:aws:iam::aws:policy/AmazonSageMakerFullAccess'
                    )
                    
                    # Adjuntar política ECR
                    print(f"[ADJUNTANDO] Política ECR...")
                    self.iam_client.attach_role_policy(
                        RoleName=role_name,
                        PolicyArn='arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly'
                    )
                    
                    # Esperar a que el rol esté listo
                    time.sleep(5)
                    
                    print(f"[OK] Rol creado: {role_name}")
                    print(f"     ARN: {self.sagemaker_role_arn}")
                    return True
                    
                except ClientError as create_error:
                    print(f"[ERROR] {create_error}")
                    return False
            else:
                print(f"[ERROR] {e}")
                return False

    # ========================================================================
    # PASO 5: CLOUDFORMATION DEPLOY
    # ========================================================================

    def cloudformation_deploy(self, image_uri):
        """Desplegar stack CloudFormation completo"""
        self.step(5, "CloudFormation Deploy - Crear infraestructura")
        
        template_path = 'infra-sagemaker-complete.yaml'
        
        if not Path(template_path).exists():
            print(f"[ERROR] Template no encontrado: {template_path}")
            return False
        
        print(f"[VALIDANDO] Template CloudFormation...")
        
        try:
            with open(template_path, 'r', encoding='utf-8') as f:
                template_body = f.read()
            
            self.cf_client.validate_template(TemplateBody=template_body)
            print("[OK] Template válido")
            
            # Preparar parámetros
            parameters = [
                {
                    'ParameterKey': 'ImageUri',
                    'ParameterValue': image_uri
                },
                {
                    'ParameterKey': 'SageMakerRoleArn',
                    'ParameterValue': self.sagemaker_role_arn
                }
            ]
            
            # Verificar si el stack existe
            print(f"[VERIFICANDO] Stack: {self.stack_name}...")
            
            try:
                response = self.cf_client.describe_stacks(StackName=self.stack_name)
                stack_status = response['Stacks'][0]['StackStatus']
                print(f"     Stack existe (status: {stack_status})")
                print(f"[UPDATE] Actualizando stack...")
                
                try:
                    self.cf_client.update_stack(
                        StackName=self.stack_name,
                        TemplateBody=template_body,
                        Parameters=parameters,
                        Capabilities=['CAPABILITY_NAMED_IAM']
                    )
                    operation = "UPDATE"
                except ClientError as e:
                    if "No updates are to be performed" in str(e):
                        print("[SKIP] No hay cambios para aplicar")
                        return self.get_cloudformation_outputs()
                    raise
                    
            except ClientError as e:
                if 'does not exist' in str(e):
                    print(f"[CREATE] Creando nuevo stack...")
                    self.cf_client.create_stack(
                        StackName=self.stack_name,
                        TemplateBody=template_body,
                        Parameters=parameters,
                        Capabilities=['CAPABILITY_NAMED_IAM']
                    )
                    operation = "CREATE"
                else:
                    raise
            
            # Esperar a que se complete
            self.wait_for_stack(operation)
            
            # Obtener outputs
            return self.get_cloudformation_outputs()
            
        except ClientError as e:
            print(f"[ERROR] {e}")
            return False

    def wait_for_stack(self, operation, max_attempts=360):
        """Esperar a que el stack se complete"""
        print(f"\n[ESPERANDO] Deployment {operation}...")
        
        operation_complete = 'CREATE_COMPLETE' if operation == 'CREATE' else 'UPDATE_COMPLETE'
        operation_failed = 'CREATE_FAILED' if operation == 'CREATE' else 'UPDATE_FAILED'
        
        for attempt in range(max_attempts):
            try:
                response = self.cf_client.describe_stacks(StackName=self.stack_name)
                status = response['Stacks'][0]['StackStatus']
                
                if attempt % 4 == 0:
                    print(f"  [{attempt*5}s] Status: {status}")
                
                if status == operation_complete:
                    print(f"\n[OK] Stack {operation} completado exitosamente")
                    return True
                
                if 'FAILED' in status or 'ROLLBACK' in status:
                    print(f"[ERROR] Stack {operation} falló: {status}")
                    self.print_stack_events()
                    return False
                
                time.sleep(5)
                
            except ClientError as e:
                print(f"[ERROR] {e}")
                return False
        
        print(f"[ERROR] Timeout esperando stack (> 30 minutos)")
        return False

    def get_cloudformation_outputs(self):
        """Obtener outputs del stack"""
        print("\n[OUTPUTS] Extrayendo configuración...")
        
        try:
            response = self.cf_client.describe_stacks(StackName=self.stack_name)
            outputs = response['Stacks'][0].get('Outputs', [])
            
            if not outputs:
                print("[WARN] No hay outputs disponibles")
                return {}
            
            outputs_dict = {o['OutputKey']: o['OutputValue'] for o in outputs}
            
            print("\n[RESULTADOS]")
            for key, value in outputs_dict.items():
                if len(value) > 60:
                    print(f"  {key}: {value[:60]}...")
                else:
                    print(f"  {key}: {value}")
            
            # Guardar configuración
            self.save_outputs(outputs_dict)
            return outputs_dict
            
        except ClientError as e:
            print(f"[ERROR] {e}")
            return {}

    def print_stack_events(self):
        """Mostrar eventos del stack para debugging"""
        try:
            response = self.cf_client.describe_stack_events(StackName=self.stack_name)
            print("\n[EVENTOS] Últimos errores:")
            for event in reversed(response['StackEvents'][-10:]):
                if 'FAILED' in event['ResourceStatus'] or 'ERROR' in event.get('ResourceStatusReason', ''):
                    timestamp = event['Timestamp'].strftime('%H:%M:%S')
                    resource = event['LogicalResourceId']
                    status = event['ResourceStatus']
                    reason = event.get('ResourceStatusReason', '')
                    print(f"  [{timestamp}] {resource}: {status}")
                    if reason:
                        print(f"             {reason[:80]}")
        except:
            pass

    def save_outputs(self, outputs):
        """Guardar outputs en archivos"""
        print("\n[GUARDANDO] Configuración...")
        
        try:
            # API URL
            if 'ApiInvokeUrl' in outputs:
                with open('api-invoke-url.txt', 'w') as f:
                    f.write(outputs['ApiInvokeUrl'])
                print("  [OK] api-invoke-url.txt")
            
            # Endpoint
            if 'EndpointName' in outputs:
                with open('endpoint-name.txt', 'w') as f:
                    f.write(outputs['EndpointName'])
                print("  [OK] endpoint-name.txt")
            
            # Configuración completa
            with open('deployment-config.json', 'w') as f:
                json.dump(outputs, f, indent=2)
            print("  [OK] deployment-config.json")
            
        except Exception as e:
            print(f"  [WARN] Error guardando: {e}")

    # ========================================================================
    # ORQUESTADOR PRINCIPAL
    # ========================================================================

    def orchestrate(self, skip_docker=False):
        """Ejecutar pipeline completo"""
        print("\n" + "=" * 70)
        print("ORQUESTADOR MLOPS - PIPELINE COMPLETO")
        print("=" * 70)
        
        # Paso 1: Docker Build
        if not self.docker_build(skip_docker=skip_docker):
            return False
        
        # Paso 2: ECR Setup
        if not self.ecr_setup():
            return False
        
        # Paso 3: Docker Push
        image_uri = self.docker_push_to_ecr()
        if not image_uri:
            return False
        
        # Paso 4: SageMaker Role
        if not self.create_sagemaker_role():
            return False
        
        # Paso 5: CloudFormation Deploy
        if not self.cloudformation_deploy(image_uri):
            return False
        
        print("\n" + "=" * 70)
        print("✅ PIPELINE COMPLETADO EXITOSAMENTE")
        print("=" * 70 + "\n")
        
        return True


def main():
    """Entrada principal"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Orquestador MLOps: Docker Build + ECR Push + CloudFormation',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  # Despliegue completo
  python deploy-completo.py --stack-name fraudes-api

  # Con tag personalizado
  python deploy-completo.py --stack-name fraudes-api --image-tag v2

  # Omitir Docker build
  python deploy-completo.py --stack-name fraudes-api --skip-docker
        """
    )
    
    parser.add_argument(
        '--stack-name',
        type=str,
        required=True,
        help='Nombre del stack CloudFormation'
    )
    
    parser.add_argument(
        '--region',
        type=str,
        default='us-east-1',
        help='Region AWS (default: us-east-1)'
    )
    
    parser.add_argument(
        '--image-tag',
        type=str,
        default='latest',
        help='Tag de la imagen Docker (default: latest)'
    )
    
    parser.add_argument(
        '--skip-docker',
        action='store_true',
        help='Omitir Docker build (usar imagen existente)'
    )
    
    args = parser.parse_args()
    
    # Crear orquestador
    orchestrator = MLOpsOrchestrator(
        region=args.region,
        stack_name=args.stack_name,
        image_tag=args.image_tag
    )
    
    # Ejecutar
    success = orchestrator.orchestrate(skip_docker=args.skip_docker)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
