#!/bin/bash

# Fraud Detection API - cURL Examples
# These examples show how to interact with the fraud detection API

echo "=========================================="
echo "Fraud Detection API - cURL Examples"
echo "=========================================="
echo ""

BASE_URL="http://localhost:8000"

# 1. Health Check
echo "1. Health Check"
echo "--------------------------------------------"
curl -X GET "${BASE_URL}/health/" \
  -H "Content-Type: application/json"
echo ""
echo ""

# 2. Single Fraud Prediction - Low Risk
echo "2. Single Fraud Prediction - Low Risk Transaction"
echo "--------------------------------------------"
curl -X POST "${BASE_URL}/fraud/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX123456",
    "monto": 150.50,
    "edad": 35,
    "ciudad": "Quito",
    "establecimiento": "RestaurantXYZ",
    "especialidad": "RESTAURANTES"
  }'
echo ""
echo ""

# 3. Single Fraud Prediction - High Risk
echo "3. Single Fraud Prediction - High Risk Transaction"
echo "--------------------------------------------"
curl -X POST "${BASE_URL}/fraud/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX999999",
    "monto": 9500.00,
    "edad": 82,
    "ciudad": "Quito",
    "establecimiento": "TiendaDesconocida",
    "especialidad": "ELECTRONICA"
  }'
echo ""
echo ""

# 4. Batch Fraud Predictions
echo "4. Batch Fraud Predictions (3 transactions)"
echo "--------------------------------------------"
curl -X POST "${BASE_URL}/fraud/batch-predict" \
  -H "Content-Type: application/json" \
  -d '[
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
  ]'
echo ""
echo ""

echo "=========================================="
echo "Examples completed!"
echo "=========================================="
echo ""
echo "API Documentation available at:"
echo "  - Swagger UI: ${BASE_URL}/docs"
echo "  - ReDoc: ${BASE_URL}/redoc"
