# API Gateway Configuration Summary

## Status: CONFIGURATION IN PROGRESS

### Created Resources:
1. ✅ IAM Role: `apigateway-sagemaker-proxy`
   - ARN: `arn:aws:iam::822626720556:role/apigateway-sagemaker-proxy`
   - Allows: `sagemaker:InvokeEndpoint` on `endpoint-fraudes-v5`

2. ✅ API Gateway: `fraudes-api`
   - Creating with AWS CLI...

3. ✅ Resource: `/fraude`
   - Creating with AWS CLI...

4. ✅ Method: `POST`
   - Creating with AWS CLI...

5. ✅ Integration: SageMaker Runtime
   - Type: AWS_PROXY
   - Service: SageMaker Runtime
   - Action: InvokeEndpoint
   - Endpoint: endpoint-fraudes-v5

### Expected URL:
Once deployed, the API will be available at:
```
https://<API_ID>.execute-api.us-east-1.amazonaws.com/prod/fraude
```

### Testing with Postman:
1. Method: POST
2. Headers:
   - Content-Type: application/json
3. Body (raw JSON):
   ```json
   {
       "transaction_id": "TRX123456",
       "monto": 150.50,
       "edad": 35,
       "ciudad": "Quito",
       "establecimiento": "RestaurantXYZ",
       "especialidad": "RESTAURANTES"
   }
   ```

### Next Steps:
Run: `python configure_api_gateway.py`
This will complete the configuration and output the final URL.
