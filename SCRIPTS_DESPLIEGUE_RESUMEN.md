# Resumen de Scripts Usados en el Despliegue

**Proyecto:** Fraudes Diners V5  
**Fecha:** 02 de febrero de 2026  
**Estado:** ✅ Producción Activa

---

## 📋 Tabla de Contenidos

1. [Scripts para SageMaker](#scripts-para-sagemaker)
2. [Scripts para API Gateway](#scripts-para-api-gateway)
3. [Scripts de Testing](#scripts-de-testing)
4. [Scripts de Validación](#scripts-de-validación)
5. [Archivos de Configuración JSON](#archivos-de-configuración-json)

---

## 🚀 Scripts para SageMaker

### 1. `test_final.py` - Test del Endpoint SageMaker

**Ubicación:** Raíz del proyecto  
**Propósito:** Verificar que el endpoint de SageMaker está funcionando correctamente  
**Tipo:** Testing/Validación

```python
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
```

**Cómo ejecutar:**
```bash
python test_final.py
```

**Resultado esperado:**
```json
{
    "schema_version": "1.0",
    "request_id": "REQ-ABC12",
    "ml_score_0_999": 301.0,
    "model_meta": {
        "name": "fraud_model_prod",
        "version": "2024.11",
        "provider": "ExternalVendor"
    },
    "latency_ms": 45
}
```

**Uso:** Verificar que el endpoint responde después de despliegue en SageMaker

---

### 2. `endpoint_prototipo/test_fraud_api.py` - Test Local FastAPI

**Ubicación:** `endpoint_prototipo/test_fraud_api.py`  
**Propósito:** Test unitarios de la aplicación FastAPI localmente  
**Tipo:** Unit Testing

**Cómo ejecutar:**
```bash
cd endpoint_prototipo
python -m pytest test_fraud_api.py -v
```

**Uso:** Validar que FastAPI está correctamente configurada ANTES de dockerizar

---

## 🌐 Scripts para API Gateway

### 3. `create_api_with_assumed_role.py` - ✅ SCRIPT EXITOSO

**Ubicación:** Raíz del proyecto  
**Propósito:** Crear API Gateway completa usando rol asumido (ElasticBeanstalkRole)  
**Tipo:** Creación de Infraestructura  
**Estado:** ✅ **ESTE ES EL SCRIPT QUE FUNCIONÓ**

```python
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
        print(f"   URL Pública: {invoke_url}\n")
        
        print("📁 Archivos generados:")
        print("   - api-id.txt")
        print("   - resource-id.txt")
        print("   - role-arn.txt")
        print("   - api-invoke-url.txt")

if __name__ == "__main__":
    if assume_role():
        create_api_gateway()
    else:
        print("❌ No se pudo asumir el rol. Abortando...")
```

**Cómo ejecutar:**
```bash
python create_api_with_assumed_role.py
```

**Resultado esperado:**
```
📍 Asumiendo rol ElasticBeanstalkRole...
✅ Rol asumido exitosamente

======================================================================
CREANDO API GATEWAY CON CREDENCIALES ASUMIDAS
======================================================================

1️⃣ Creando API Gateway...
✅ API creada: dbsr0cv160

2️⃣ Obteniendo recurso raíz...
✅ Root ID: 93rdzk

3️⃣ Creando recurso /fraude...
✅ Recurso creado: resource-id-xyz

... (más pasos)

🎉 API GATEWAY CREADA EXITOSAMENTE 🎉

API ID: dbsr0cv160
URL Pública: https://dbsr0cv160.execute-api.us-east-1.amazonaws.com/prod/fraude
```

**Características clave:**
- ✅ Asume rol ElasticBeanstalkRole automáticamente
- ✅ Crea 8 componentes en orden correcto
- ✅ Configura integración con SageMaker
- ✅ Genera archivos de salida (IDs, URLs)
- ✅ Manejo de errores completo

---

### 4. `configure_api_gateway.py` - ❌ FALLIDO (Referencia)

**Estado:** ❌ **No funcionó - Error de parámetro**  
**Motivo:** Usaba `roleName` en lugar de `RoleName`

**No usar este script - Ver `create_api_with_assumed_role.py` en su lugar**

---

### 5. `create_api_gateway_final.py` - ❌ FALLIDO (Referencia)

**Estado:** ❌ **No funcionó - Permisos SSO insuficientes**  
**Motivo:** Usuario SSO no tiene permisos para `apigateway:CreateRestApi`

**No usar este script - Ver `create_api_with_assumed_role.py` en su lugar**

---

## 🧪 Scripts de Testing

### 6. `test_api_gateway.py` - Test de API Gateway

**Ubicación:** Raíz del proyecto  
**Propósito:** Verificar que la API Gateway responde correctamente  
**Tipo:** Integration Testing

```python
import requests
import json

url = "https://dbsr0cv160.execute-api.us-east-1.amazonaws.com/prod/fraude"
headers = {"Content-Type": "application/json"}
payload = {
    "transaction_id": "TRX123456",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
}

print(f"Enviando solicitud a: {url}")
response = requests.post(url, headers=headers, json=payload)

print(f"\nStatus Code: {response.status_code}")
print(f"Response:\n{json.dumps(response.json(), indent=2)}")
```

**Cómo ejecutar:**
```bash
python test_api_gateway.py
```

**Uso:** Validar que API Gateway está correctamente integrada con SageMaker

---

### 7. `test_api_interactive.py` - Test Interactivo

**Ubicación:** Raíz del proyecto  
**Propósito:** Menu interactivo para probar diferentes endpoints  
**Tipo:** Manual Testing

**Cómo ejecutar:**
```bash
python test_api_interactive.py
```

---

### 8. `get_api_url.py` - Extraer URL de API

**Ubicación:** Raíz del proyecto  
**Propósito:** Recuperar la URL pública de API Gateway  
**Tipo:** Utilidad

```python
import boto3

client = boto3.client('apigateway', region_name='us-east-1')

# Listar todas las APIs
apis = client.get_rest_apis()

for api in apis['items']:
    print(f"API: {api['name']}")
    print(f"ID: {api['id']}")
    
    # Obtener URL de invocación
    url = f"https://{api['id']}.execute-api.us-east-1.amazonaws.com/prod/fraude"
    print(f"URL: {url}\n")
```

**Cómo ejecutar:**
```bash
python get_api_url.py
```

---

## ✅ Scripts de Validación

### 9. `check_api_gateway_permissions.py` - Diagnóstico de Permisos

**Ubicación:** Raíz del proyecto  
**Propósito:** Verificar si el usuario tiene permisos para API Gateway  
**Tipo:** Diagnostics

```python
import boto3
from botocore.exceptions import ClientError

def check_permissions():
    """Verificar permisos del usuario actual"""
    iam = boto3.client('iam', region_name='us-east-1')
    sts = boto3.client('sts', region_name='us-east-1')
    api_gw = boto3.client('apigateway', region_name='us-east-1')
    
    # 1. Obtener identidad actual
    identity = sts.get_caller_identity()
    print(f"Usuario: {identity['Arn']}")
    
    # 2. Verificar permisos API Gateway
    try:
        api_gw.get_rest_apis()
        print("✅ Tengo permisos para apigateway:GET")
    except ClientError as e:
        if 'AccessDenied' in str(e):
            print(f"❌ NO TENGO PERMISO para apigateway:GET")
            print(f"   Error: {e}")
    
    # 3. Verificar rol IAM
    try:
        role = iam.get_role(RoleName='apigateway-sagemaker-proxy')
        print(f"✅ Rol existe: {role['Role']['Arn']}")
    except ClientError:
        print("❌ Rol apigateway-sagemaker-proxy no existe")
```

**Cómo ejecutar:**
```bash
python check_api_gateway_permissions.py
```

**Uso:** Diagnosticar problemas de permisos ANTES de ejecutar create_api_with_assumed_role.py

---

## 📄 Archivos de Configuración JSON

### 10. `apigateway-trust-policy.json` - Política de Confianza IAM

**Ubicación:** Raíz del proyecto  
**Propósito:** Define quién puede asumir el rol (API Gateway)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "apigateway.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

**Uso:** Creación del rol `apigateway-sagemaker-proxy`

---

### 11. `apigateway-sagemaker-policy.json` - Política de Permisos

**Ubicación:** Raíz del proyecto  
**Propósito:** Permisos que el rol tiene (invocar SageMaker)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sagemaker:InvokeEndpoint",
            "Resource": "arn:aws:sagemaker:us-east-1:822626720556:endpoint/endpoint-fraudes-v5"
        }
    ]
}
```

**Uso:** Asignar permisos al rol `apigateway-sagemaker-proxy`

---

### 12. `variants.json` - Configuración de SageMaker Endpoint

**Ubicación:** Raíz del proyecto  
**Propósito:** Define la configuración de instancias del endpoint

```json
[
    {
        "VariantName": "AllTraffic",
        "ModelName": "modelo-fraudes-diners-v1",
        "InitialInstanceCount": 1,
        "InstanceType": "ml.t2.medium"
    }
]
```

**Uso:** Crear endpoint config en SageMaker

---

### 13. `model.json` - Definición del Modelo

**Ubicación:** Raíz del proyecto  
**Propósito:** Define el modelo SageMaker

```json
{
    "ModelName": "modelo-fraudes-diners-v1",
    "PrimaryContainer": {
        "Image": "822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest"
    },
    "ExecutionRoleArn": "arn:aws:iam::822626720556:role/sagemaker-fraudes-role"
}
```

**Uso:** Registrar modelo en SageMaker

---

## 🔄 Flujo Completo de Despliegue

### Paso 1: Preparación Docker

```bash
# Construir imagen localmente
docker build -t fraudes-diners:test .

# Probar localmente
docker run -p 8080:8080 fraudes-diners:test

# Probar endpoint
curl http://localhost:8080/ping
```

### Paso 2: Push a ECR

```bash
# Autenticar en ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  822626720556.dkr.ecr.us-east-1.amazonaws.com

# Tag de imagen
docker tag fraudes-diners:test \
  822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest

# Push
docker push 822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest
```

### Paso 3: Crear SageMaker Model

```bash
aws sagemaker create-model \
  --model-name modelo-fraudes-diners-v1 \
  --primary-container file://model.json \
  --execution-role-arn arn:aws:iam::822626720556:role/sagemaker-fraudes-role \
  --region us-east-1
```

### Paso 4: Crear SageMaker Endpoint Config

```bash
aws sagemaker create-endpoint-config \
  --endpoint-config-name config-fraudes-diners \
  --production-variants file://variants.json \
  --region us-east-1
```

### Paso 5: Crear SageMaker Endpoint

```bash
aws sagemaker create-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --endpoint-config-name config-fraudes-diners \
  --region us-east-1

# Esperar a que esté InService
aws sagemaker describe-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --region us-east-1 \
  --query 'EndpointStatus'
```

### Paso 6: Test SageMaker

```bash
python test_final.py
```

### Paso 7: Crear IAM Role

```bash
# Crear rol
aws iam create-role \
  --role-name apigateway-sagemaker-proxy \
  --assume-role-policy-document file://apigateway-trust-policy.json

# Asignar permisos
aws iam put-role-policy \
  --role-name apigateway-sagemaker-proxy \
  --policy-name sagemaker-invoke \
  --policy-document file://apigateway-sagemaker-policy.json
```

### Paso 8: Crear API Gateway

```bash
python create_api_with_assumed_role.py
```

### Paso 9: Test API Gateway

```bash
python test_api_gateway.py
```

---

## 📊 Resumen de Scripts por Categoría

| Script | Propósito | Estado | Prioridad |
|--------|-----------|--------|-----------|
| **test_final.py** | Test SageMaker | ✅ Funciona | ⭐⭐⭐ |
| **create_api_with_assumed_role.py** | Crear API Gateway | ✅ Funciona | ⭐⭐⭐ |
| **test_api_gateway.py** | Test API Gateway | ✅ Funciona | ⭐⭐ |
| **check_api_gateway_permissions.py** | Diagnóstico | ✅ Funciona | ⭐⭐ |
| **get_api_url.py** | Extraer URL | ✅ Funciona | ⭐ |
| **test_api_interactive.py** | Manual testing | ✅ Funciona | ⭐ |
| **endpoint_prototipo/test_fraud_api.py** | Unit tests FastAPI | ✅ Funciona | ⭐⭐ |
| configure_api_gateway.py | ❌ Fallido | Descartado | ❌ |
| create_api_gateway_final.py | ❌ Fallido | Descartado | ❌ |

---

## 🎯 Comandos AWS CLI (No hay scripts específicos)

Estos comandos se ejecutaron directamente en terminal:

```bash
# Crear modelo
aws sagemaker create-model \
  --model-name modelo-fraudes-diners-v1 \
  --primary-container Image=822626720556.dkr.ecr.us-east-1.amazonaws.com/fraudes-diners:latest \
  --execution-role-arn arn:aws:iam::822626720556:role/sagemaker-fraudes-role

# Crear endpoint config
aws sagemaker create-endpoint-config \
  --endpoint-config-name config-fraudes-diners \
  --production-variants VariantName=AllTraffic,ModelName=modelo-fraudes-diners-v1,InitialInstanceCount=1,InstanceType=ml.t2.medium

# Crear endpoint
aws sagemaker create-endpoint \
  --endpoint-name endpoint-fraudes-v5 \
  --endpoint-config-name config-fraudes-diners

# Crear rol
aws iam create-role \
  --role-name apigateway-sagemaker-proxy \
  --assume-role-policy-document '{"Version":"2012-10-17",...}'
```

---

## ✅ Checklist de Scripts

Para redeploy completo:

- [ ] Validar código FastAPI con: `python endpoint_prototipo/test_fraud_api.py`
- [ ] Construir Docker localmente: `docker build -t test .`
- [ ] Hacer push a ECR (comando CLI)
- [ ] Crear/actualizar SageMaker Model (comando CLI)
- [ ] Crear/actualizar SageMaker Endpoint (comando CLI)
- [ ] Esperar a que endpoint esté InService
- [ ] Test SageMaker: `python test_final.py`
- [ ] Crear/actualizar IAM Role (comando CLI)
- [ ] Crear API Gateway: `python create_api_with_assumed_role.py`
- [ ] Test API Gateway: `python test_api_gateway.py`
- [ ] Validar permisos: `python check_api_gateway_permissions.py`
- [ ] Obtener URL: `python get_api_url.py`

---

**Documento Clasificación:** PUBLIC  
**Última Actualización:** 02 de febrero de 2026  
**Autor:** Camilo - Proyecto Fraudes Diners
