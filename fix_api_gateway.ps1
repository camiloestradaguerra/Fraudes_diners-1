# Script para arreglar la integración de API Gateway
# Ejecutar en PowerShell

Write-Host "`n🔧 ARREGLANDO INTEGRACIÓN DE API GATEWAY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Asumir rol
Write-Host "📍 Asumiendo rol con permisos..." -ForegroundColor Yellow
$assume = aws sts assume-role --role-arn "arn:aws:iam::822626720556:role/ElasticBeanstalkRole" --role-session-name "fix-api-$(Get-Random)" --external-id "fraudes-diners-eb" | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID = $assume.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $assume.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $assume.Credentials.SessionToken

Write-Host "✅ Rol asumido`n" -ForegroundColor Green

# Obtener IDs
$apiId = Get-Content "api-id.txt"
$resourceId = Get-Content "resource-id.txt"
$roleArn = Get-Content "role-arn.txt"

Write-Host "📋 Información:" -ForegroundColor Yellow
Write-Host "   API ID: $apiId" -ForegroundColor Gray
Write-Host "   Resource ID: $resourceId" -ForegroundColor Gray
Write-Host "   Role ARN: $roleArn`n" -ForegroundColor Gray

# PASO 1: Eliminar integración anterior
Write-Host "🗑️  Eliminando integración anterior..." -ForegroundColor Yellow
aws apigateway delete-integration `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method POST `
  --region us-east-1 2>$null

Write-Host "✅ Eliminada`n" -ForegroundColor Green

# PASO 2: Crear nueva integración con servicio proxy directo
Write-Host "🔗 Creando nueva integración..." -ForegroundColor Yellow

aws apigateway put-integration `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method POST `
  --type AWS `
  --integration-http-method POST `
  --uri "arn:aws:apigateway:us-east-1:sagemaker:path/endpoints/endpoint-fraudes-v5/invocations" `
  --credentials $roleArn `
  --region us-east-1 | Out-Null

Write-Host "✅ Integración creada`n" -ForegroundColor Green

# PASO 3: Crear response de integración
Write-Host "📤 Configurando response..." -ForegroundColor Yellow

aws apigateway put-integration-response `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method POST `
  --status-code 200 `
  --region us-east-1 | Out-Null

Write-Host "✅ Response configurada`n" -ForegroundColor Green

# PASO 4: Crear método response
Write-Host "📥 Configurando método response..." -ForegroundColor Yellow

aws apigateway put-method-response `
  --rest-api-id $apiId `
  --resource-id $resourceId `
  --http-method POST `
  --status-code 200 `
  --region us-east-1 2>$null

Write-Host "✅ Método response configurado`n" -ForegroundColor Green

# PASO 5: Redeploy
Write-Host "🚀 Redeployando API..." -ForegroundColor Yellow

aws apigateway create-deployment `
  --rest-api-id $apiId `
  --stage-name prod `
  --region us-east-1 | Out-Null

Write-Host "✅ API redeployada`n" -ForegroundColor Green

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║        ✅ API GATEWAY ARREGLADA Y LISTA PARA PROBAR        ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📍 URL: https://$apiId.execute-api.us-east-1.amazonaws.com/prod/fraude`n" -ForegroundColor Cyan
Write-Host "Intenta nuevamente en Postman. Si sigue sin funcionar, verifica que:" -ForegroundColor Yellow
Write-Host "  • El endpoint de SageMaker esté en estado 'InService'" -ForegroundColor Gray
Write-Host "  • El rol tenga permisos sagemaker:InvokeEndpoint" -ForegroundColor Gray
Write-Host "  • Haya transcurrido tiempo suficiente para que se replique el cambio" -ForegroundColor Gray
Write-Host "`n"
