#!/usr/bin/env python3
"""
Script para obtener la URL final de la API Gateway y probar con Postman
"""
import boto3
import json

# Crear cliente de API Gateway
client = boto3.client('apigateway', region_name='us-east-1')

print("\n" + "="*60)
print("BUSCANDO API 'fraudes-api'...")
print("="*60 + "\n")

# Obtener todas las APIs
try:
    response = client.get_rest_apis(limit=100)
    apis = response.get('items', [])
    
    # Buscar la API fraudes-api
    fraudes_api = None
    for api in apis:
        if api['name'] == 'fraudes-api':
            fraudes_api = api
            break
    
    if fraudes_api:
        api_id = fraudes_api['id']
        invoke_url = f"https://{api_id}.execute-api.us-east-1.amazonaws.com/prod/fraude"
        
        print("✅ API ENCONTRADA\n")
        print("DETALLES:")
        print(f"  ID: {api_id}")
        print(f"  Nombre: {fraudes_api['name']}")
        print(f"  Descripción: {fraudes_api.get('description', 'N/A')}")
        print(f"  Creada: {fraudes_api['createdDate']}\n")
        
        print("╔════════════════════════════════════════════════════════════╗")
        print("║              URL PARA USAR EN POSTMAN                       ║")
        print("╚════════════════════════════════════════════════════════════╝\n")
        print(f"  {invoke_url}\n")
        
        # Guardar la URL
        with open('api-invoke-url.txt', 'w') as f:
            f.write(invoke_url)
        print("✅ URL guardada en api-invoke-url.txt\n")
        
        # Mostrar instrucciones para Postman
        print("\n" + "="*60)
        print("INSTRUCCIONES PARA POSTMAN:")
        print("="*60)
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
        
    else:
        print("❌ API 'fraudes-api' NO ENCONTRADA\n")
        print("APIs disponibles:")
        for api in apis:
            print(f"  • {api['name']} (ID: {api['id']})")
            
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()

print("\n")
