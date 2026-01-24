"""
Test script for Fraud Detection API

This script provides examples of how to test the fraud prediction endpoint.
"""

import json
import requests
from typing import Dict, Any


def test_health_check(base_url: str = "http://localhost:8000") -> Dict[str, Any]:
    """Test the health check endpoint."""
    print("\n" + "="*60)
    print("Testing Health Check Endpoint")
    print("="*60)
    
    response = requests.get(f"{base_url}/health/")
    print(f"Status Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    return response.json()


def test_single_prediction(base_url: str = "http://localhost:8000") -> Dict[str, Any]:
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
    
    print(f"Request Payload:\n{json.dumps(payload, indent=2)}")
    
    response = requests.post(f"{base_url}/fraud/predict", json=payload)
    print(f"\nStatus Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    return response.json()


def test_batch_prediction(base_url: str = "http://localhost:8000") -> list:
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
        },
        {
            "transaction_id": "TRX123458",
            "monto": 25.99,
            "edad": 28,
            "ciudad": "Ambato",
            "establecimiento": "CafeteriaXYZ",
            "especialidad": "CAFETERIAS"
        }
    ]
    
    print(f"Request Payload (3 transactions):\n{json.dumps(payloads, indent=2)}")
    
    response = requests.post(f"{base_url}/fraud/batch-predict", json=payloads)
    print(f"\nStatus Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    return response.json()


def test_high_risk_transaction(base_url: str = "http://localhost:8000") -> Dict[str, Any]:
    """Test a high-risk transaction prediction."""
    print("\n" + "="*60)
    print("Testing High-Risk Transaction")
    print("="*60)
    
    # High risk: large amount + unusual age (elderly)
    payload = {
        "transaction_id": "TRX999999",
        "monto": 9500.00,
        "edad": 82,
        "ciudad": "Quito",
        "establecimiento": "TiendaDesconocida",
        "especialidad": "ELECTRONICA"
    }
    
    print(f"Request Payload:\n{json.dumps(payload, indent=2)}")
    
    response = requests.post(f"{base_url}/fraud/predict", json=payload)
    print(f"\nStatus Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    return response.json()


def test_low_risk_transaction(base_url: str = "http://localhost:8000") -> Dict[str, Any]:
    """Test a low-risk transaction prediction."""
    print("\n" + "="*60)
    print("Testing Low-Risk Transaction")
    print("="*60)
    
    # Low risk: small amount + normal age
    payload = {
        "transaction_id": "TRX111111",
        "monto": 15.00,
        "edad": 35,
        "ciudad": "Quito",
        "establecimiento": "RestaurantConocido",
        "especialidad": "RESTAURANTES"
    }
    
    print(f"Request Payload:\n{json.dumps(payload, indent=2)}")
    
    response = requests.post(f"{base_url}/fraud/predict", json=payload)
    print(f"\nStatus Code: {response.status_code}")
    print(f"Response:\n{json.dumps(response.json(), indent=2)}")
    
    return response.json()


def compare_predictions(low_risk: Dict, high_risk: Dict) -> None:
    """Compare fraud scores between low and high risk transactions."""
    print("\n" + "="*60)
    print("Fraud Risk Comparison")
    print("="*60)
    
    low_score = low_risk.get("ml_score_0_999", 0)
    high_score = high_risk.get("ml_score_0_999", 0)
    
    print(f"Low-Risk Transaction Score:  {low_score}")
    print(f"High-Risk Transaction Score: {high_score}")
    print(f"\nScore Difference: {high_score - low_score}")
    print(f"High-Risk score is {high_score/low_score:.2f}x higher" if low_score > 0 else "")


def main():
    """Run all tests."""
    print("\n" + "="*60)
    print("FRAUD DETECTION API - TEST SUITE")
    print("="*60)
    
    base_url = "http://localhost:8000"
    
    try:
        # Test health check
        health = test_health_check(base_url)
        
        # Test single prediction
        single = test_single_prediction(base_url)
        
        # Test batch prediction
        batch = test_batch_prediction(base_url)
        
        # Test high-risk transaction
        high_risk = test_high_risk_transaction(base_url)
        
        # Test low-risk transaction
        low_risk = test_low_risk_transaction(base_url)
        
        # Compare predictions
        compare_predictions(low_risk, high_risk)
        
        print("\n" + "="*60)
        print("ALL TESTS COMPLETED SUCCESSFULLY")
        print("="*60 + "\n")
        
    except requests.exceptions.ConnectionError:
        print("\n❌ ERROR: Could not connect to the API")
        print("Make sure the API is running on http://localhost:8000")
        print("\nTo start the API, run:")
        print("  python main.py\n")
    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}\n")


if __name__ == "__main__":
    main()
