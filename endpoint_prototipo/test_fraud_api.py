"""
Test script for Fraud Detection API via Ngrok

This script tests the fraud prediction endpoint using a public ngrok tunnel.
"""

import json
import requests
from typing import Dict, Any

# ==========================================================
# CONFIGURACIÓN DEL ENTORNO
# ==========================================================
# Asegúrate de que esta URL sea la correcta de tu sesión actual de Ngrok
BASE_URL = "https://nondistillable-audriana-satiably.ngrok-free.dev" 

HEADERS = {
    "ngrok-skip-browser-warning": "true",
    "Content-Type": "application/json"
}

def test_health_check(url: str) -> Dict[str, Any]:
    """Test the health check endpoint."""
    print("\n" + "="*60)
    print(f"Testing Health Check en: {url}")
    print("="*60)
    
    try:
        # El router tiene el prefijo /health/ y el endpoint es /
        response = requests.get(f"{url}/health/", headers=HEADERS)
        response.raise_for_status()
        print(f"Status Code: {response.status_code}")
        print(f"Response:\n{json.dumps(response.json(), indent=2)}")
        return response.json()
    except Exception as e:
        print(f"❌ Error en Health Check: {e}")
        return {}

def test_single_prediction(url: str) -> Dict[str, Any]:
    """Test single fraud prediction."""
    print("\n" + "="*60)
    print("Testing Single Fraud Prediction")
    print("="*60)
    
    payload = {
        "transaction_id": "TRX123456",
        "monto": 150.50,
        "edad": 35,
        "ciudad": "Quito",
        "establecimiento": "RestaurantXYZ",
        "especialidad": "RESTAURANTES"
    }
    
    # El router tiene prefijo /fraud y el endpoint es /predict
    response = requests.post(f"{url}/fraud/predict", json=payload, headers=HEADERS)
    print(f"Status Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    return response.json()

def test_batch_prediction(url: str) -> list:
    """Test batch fraud predictions."""
    print("\n" + "="*60)
    print("Testing Batch Fraud Predictions")
    print("="*60)
    
    payloads = [
        {
            "transaction_id": "TRX123456",
            "monto": 150.50,
            "edad": 35,
            "ciudad": "Quito",
            "establecimiento": "RestaurantXYZ",
            "especialidad": "RESTAURANTES"
        },
        {
            "transaction_id": "TRX123457",
            "monto": 5000.00,
            "edad": 72,
            "ciudad": "Guayaquil",
            "establecimiento": "JoyeriaXYZ",
            "especialidad": "JOYERIAS"
        }
    ]
    
    # CORRECCIÓN: Se usa la variable 'payloads' que contiene la lista
    response = requests.post(f"{url}/fraud/batch-predict", json=payloads, headers=HEADERS)
    print(f"Status Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    return response.json()

def test_high_risk_transaction(url: str) -> Dict[str, Any]:
    """Test a high-risk transaction prediction."""
    print("\n" + "="*60)
    print("Testing High-Risk Transaction")
    print("="*60)
    
    payload = {
        "transaction_id": "TRX999999",
        "monto": 9500.00,
        "edad": 82,
        "ciudad": "Quito",
        "establecimiento": "TiendaDesconocida",
        "especialidad": "ELECTRONICA"
    }
    
    response = requests.post(f"{url}/fraud/predict", json=payload, headers=HEADERS)
    print(f"Status Code: {response.status_code}")
    # Se retorna el json para la comparación final
    return response.json()

def compare_predictions(low_risk: Dict, high_risk: Dict) -> None:
    """Compare fraud scores between transactions."""
    print("\n" + "="*60)
    print("Fraud Risk Comparison")
    print("="*60)
    
    # ml_score_0_999 es el campo definido en FraudPredictionResponse
    low_score = low_risk.get("ml_score_0_999", 0)
    high_score = high_risk.get("ml_score_0_999", 0)
    
    print(f"Low-Risk Score:  {low_score}")
    print(f"High-Risk Score: {high_score}")
    if low_score > 0:
        print(f"Ratio de Riesgo: {high_score/low_score:.2f}x más probable")

def main():
    print("\n🚀 INICIANDO TEST SUITE (NGROK MODE)")
    
    if "tu-url-de-ngrok" in BASE_URL:
        print("❌ ERROR: Debes pegar tu URL de Ngrok en la variable BASE_URL")
        return

    try:
        # Ejecución de pruebas
        test_health_check(BASE_URL)
        single = test_single_prediction(BASE_URL)
        test_batch_prediction(BASE_URL)
        high_risk = test_high_risk_transaction(BASE_URL)
        
        # Comparación final
        compare_predictions(single, high_risk)
        
        print("\n" + "="*60)
        print("✅ TODAS LAS PRUEBAS COMPLETADAS")
        print("="*60)
        
    except requests.exceptions.ConnectionError:
        print("\n❌ ERROR: No se pudo conectar a Ngrok.")
        print("Asegúrate de que 'ngrok' esté corriendo y la URL sea correcta.")
    except Exception as e:
        print(f"\n❌ ERROR INESPERADO: {str(e)}")

if __name__ == "__main__":
    main()