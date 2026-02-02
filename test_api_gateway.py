#!/usr/bin/env python3
"""
Script para probar la API Gateway con el endpoint de fraudes
Esto es equivalente a lo que harías en Postman
"""
import requests
import json

# URL del API Gateway
API_URL = "https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude"

# Datos de prueba
payload = {
    "transaction_id": "TRX123456",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
}

print("\n" + "="*70)
print("PROBANDO API GATEWAY → SAGEMAKER ENDPOINT")
print("="*70)

print(f"\n📍 URL: {API_URL}")
print(f"📦 Método: POST")
print(f"📋 Headers: Content-Type: application/json")
print(f"\n📤 Enviando payload:")
print(json.dumps(payload, indent=2))

try:
    # Hacer la solicitud
    print("\n⏳ Esperando respuesta...\n")
    response = requests.post(
        API_URL,
        json=payload,
        headers={'Content-Type': 'application/json'},
        timeout=30
    )
    
    # Verificar el status code
    if response.status_code == 200:
        print("✅ RESPUESTA EXITOSA (Status: 200)\n")
        result = response.json()
        print(json.dumps(result, indent=2))
    else:
        print(f"❌ ERROR: Status Code {response.status_code}\n")
        print("Respuesta:")
        print(response.text)
        
except requests.exceptions.ConnectionError as e:
    print(f"❌ ERROR DE CONEXIÓN:\n{str(e)}")
except requests.exceptions.Timeout as e:
    print(f"❌ TIMEOUT (la solicitud tardó demasiado):\n{str(e)}")
except json.JSONDecodeError:
    print(f"❌ ERROR: La respuesta no es JSON válido")
    print(f"Respuesta raw: {response.text}")
except Exception as e:
    print(f"❌ ERROR INESPERADO:\n{str(e)}")
    import traceback
    traceback.print_exc()

print("\n" + "="*70 + "\n")
