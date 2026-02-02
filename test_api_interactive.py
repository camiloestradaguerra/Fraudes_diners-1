#!/usr/bin/env python3
"""
Script simple para probar la API Gateway desde línea de comandos
Equivalente a lo que harías en Postman
"""
import sys
import json

# Verificar si requests está instalado
try:
    import requests
except ImportError:
    print("❌ ERROR: Se necesita instalar 'requests'")
    print("\nInstala con: pip install requests")
    sys.exit(1)

# URL de la API
API_URL = "https://tooahxop09.execute-api.us-east-1.amazonaws.com/prod/fraude"

# Casos de prueba
test_cases = {
    "1": {
        "name": "Transacción Normal",
        "data": {
            "transaction_id": "TRX123456",
            "monto": 150.50,
            "edad": 35,
            "ciudad": "Quito",
            "establecimiento": "RestaurantXYZ",
            "especialidad": "RESTAURANTES"
        }
    },
    "2": {
        "name": "Monto Alto (Riesgo)",
        "data": {
            "transaction_id": "TRX999999",
            "monto": 5000.00,
            "edad": 45,
            "ciudad": "New York",
            "establecimiento": "Luxury Hotel",
            "especialidad": "HOTELES"
        }
    },
    "3": {
        "name": "Edad Baja + Monto Alto (Muy Riesgoso)",
        "data": {
            "transaction_id": "TRX111111",
            "monto": 10000.00,
            "edad": 18,
            "ciudad": "Las Vegas",
            "establecimiento": "Casino",
            "especialidad": "ENTRETENIMIENTO"
        }
    }
}

def print_menu():
    """Mostrar menú de opciones"""
    print("\n" + "="*70)
    print("🧪 PRUEBA DE API GATEWAY - FRAUDE DETECTION")
    print("="*70)
    print("\nSelecciona un caso de prueba:\n")
    
    for key, test in test_cases.items():
        print(f"  {key}. {test['name']}")
    
    print(f"  0. Salir")
    print("\n" + "-"*70)
    choice = input("Opción: ").strip()
    return choice

def test_api(payload, test_name):
    """Enviar prueba a la API"""
    print("\n" + "="*70)
    print(f"📤 ENVIANDO: {test_name}")
    print("="*70)
    
    print(f"\n📍 URL: {API_URL}")
    print(f"📋 Método: POST")
    print(f"📦 Payload:")
    print(json.dumps(payload, indent=2))
    
    print("\n⏳ Esperando respuesta...\n")
    
    try:
        response = requests.post(
            API_URL,
            json=payload,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        # Mostrar resultado
        if response.status_code == 200:
            print("✅ RESPUESTA EXITOSA\n")
            result = response.json()
            
            # Parsear la respuesta
            print("📥 Resultado:")
            print(json.dumps(result, indent=2))
            
            # Interpretación
            print("\n" + "-"*70)
            if isinstance(result, dict):
                if 'prediction' in result or 'is_fraud' in result:
                    pred = result.get('prediction', result.get('is_fraud'))
                    prob = result.get('probability', 'N/A')
                    
                    if pred == 1 or pred == True:
                        print("🚨 ALERTA: ¡Posible FRAUDE detectado!")
                    else:
                        print("✅ SEGURO: Transacción parece legítima")
                    
                    if prob != 'N/A':
                        print(f"📊 Confianza: {prob*100:.1f}%" if isinstance(prob, (int, float)) else f"📊 Confianza: {prob}")
            
            print("-"*70)
            
        else:
            print(f"❌ ERROR: Status Code {response.status_code}\n")
            print(f"Respuesta:\n{response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ ERROR DE CONEXIÓN:")
        print("   No se pudo conectar a la API")
        print("   Verifica que el endpoint esté activo")
    except requests.exceptions.Timeout:
        print("❌ TIMEOUT:")
        print("   La solicitud tardó demasiado tiempo")
        print("   Intenta aumentar el timeout")
    except json.JSONDecodeError:
        print(f"❌ ERROR: La respuesta no es JSON")
        print(f"   Respuesta: {response.text}")
    except Exception as e:
        print(f"❌ ERROR INESPERADO: {str(e)}")
        import traceback
        traceback.print_exc()

def main():
    """Función principal"""
    while True:
        choice = print_menu()
        
        if choice == "0":
            print("\n👋 ¡Hasta luego!\n")
            break
        elif choice in test_cases:
            test = test_cases[choice]
            test_api(test['data'], test['name'])
            input("\nPresiona Enter para continuar...")
        else:
            print("❌ Opción inválida. Intenta de nuevo.")

if __name__ == "__main__":
    main()
