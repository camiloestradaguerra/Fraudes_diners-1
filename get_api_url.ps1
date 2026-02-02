# Script para obtener la URL final de la API
# Ejecuta: powershell .\get_api_url.ps1

Write-Host "`nBuscando API 'fraudes-api'..." -ForegroundColor Cyan

# Obtener todas las APIs
$apis = aws apigateway get-rest-apis --region us-east-1 | ConvertFrom-Json

# Buscar la API fraudes-api
$fraudesApi = $apis.items | Where-Object { $_.name -eq "fraudes-api" }

if ($fraudesApi) {
    $apiId = $fraudesApi.id
    $invokeUrl = "https://$apiId.execute-api.us-east-1.amazonaws.com/prod/fraude"
    
    Write-Host "`n✅ API ENCONTRADA" -ForegroundColor Green
    Write-Host "`nDETALLES:" -ForegroundColor Cyan
    Write-Host "ID: $apiId" -ForegroundColor Yellow
    Write-Host "Nombre: $($fraudesApi.name)" -ForegroundColor Yellow
    Write-Host "Descripción: $($fraudesApi.description)" -ForegroundColor Yellow
    Write-Host "Creada: $($fraudesApi.createdDate)" -ForegroundColor Yellow
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              URL PARA USAR EN POSTMAN                       ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "`n$invokeUrl`n" -ForegroundColor Cyan
    
    # Guardar la URL correcta
    $invokeUrl | Set-Content "api-invoke-url.txt"
    Write-Host "✅ URL guardada en api-invoke-url.txt" -ForegroundColor Green
    
} else {
    Write-Host "`n❌ API 'fraudes-api' NO ENCONTRADA" -ForegroundColor Red
    Write-Host "`nAPIs disponibles:" -ForegroundColor Yellow
    $apis.items | Select-Object id, name, description, createdDate | Format-Table
}
