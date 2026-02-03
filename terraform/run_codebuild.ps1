# Script para iniciar CodeBuild y esperar a que se complete
param(
    [string]$ProjectName = "fraudes-docker-build-prod",
    [string]$Region = "us-east-1"
)

Write-Host "🚀 Iniciando CodeBuild para proyecto: $ProjectName"

# Iniciar el build
$buildStartResult = aws codebuild start-build `
    --project-name $ProjectName `
    --region $Region `
    --query 'build.id' `
    --output text

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Error al iniciar CodeBuild"
    exit 1
}

$buildId = $buildStartResult
Write-Host "✓ Build iniciado: $buildId"

# Esperar a que se complete (máximo 30 minutos)
$maxWaitSeconds = 1800
$startTime = Get-Date
$completed = $false

while ((Get-Date) -lt $startTime.AddSeconds($maxWaitSeconds)) {
    # Obtener estado del build
    $buildStatus = aws codebuild batch-get-builds `
        --ids $buildId `
        --region $Region `
        --query 'builds[0].buildStatus' `
        --output text
    
    Write-Host "Status: $buildStatus"
    
    if ($buildStatus -eq "SUCCEEDED") {
        Write-Host "✓ Build completado exitosamente!"
        $completed = $true
        break
    }
    elseif ($buildStatus -eq "FAILED") {
        Write-Error "❌ Build falló"
        exit 1
    }
    elseif ($buildStatus -eq "FAULT") {
        Write-Error "❌ Error en la infraestructura de CodeBuild"
        exit 1
    }
    
    # Esperar 10 segundos antes de la próxima verificación
    Start-Sleep -Seconds 10
}

if (-not $completed) {
    Write-Error "❌ Timeout esperando el build (> 30 minutos)"
    exit 1
}

Write-Host "✓ CodeBuild completó satisfactoriamente"
exit 0
