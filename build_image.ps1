# Script para ejecutar CodeBuild y esperar a que complete

param(
    [string]$ProjectName = "fraudes-docker-build-prod",
    [string]$Region = "us-east-1"
)

Write-Host "================================" -ForegroundColor Green
Write-Host "CONSTRUCCION DE IMAGEN DOCKER" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

Write-Host "`n[1] Iniciando build en CodeBuild..." -ForegroundColor Cyan

$buildStartResult = aws codebuild start-build `
    --project-name $ProjectName `
    --region $Region `
    --query 'build.id' `
    --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] No se pudo iniciar CodeBuild" -ForegroundColor Red
    exit 1
}

$buildId = $buildStartResult
Write-Host "[OK] Build iniciado: $buildId" -ForegroundColor Green

Write-Host "`n[2] Esperando a que se complete (máximo 30 minutos)..." -ForegroundColor Yellow

$maxWaitSeconds = 1800
$startTime = Get-Date
$completed = $false
$failureReason = ""

while ((Get-Date) -lt $startTime.AddSeconds($maxWaitSeconds)) {
    $buildInfo = aws codebuild batch-get-builds `
        --ids $buildId `
        --region $Region `
        --output json | ConvertFrom-Json
    
    $buildStatus = $buildInfo.builds[0].buildStatus
    $elapsedSeconds = [int]((Get-Date) - $startTime).TotalSeconds
    $elapsedMinutes = [int]($elapsedSeconds / 60)
    
    Write-Host "  [$($elapsedMinutes)m] Status: $buildStatus" -ForegroundColor Cyan
    
    if ($buildStatus -eq "SUCCEEDED") {
        Write-Host "`n[OK] Build completado exitosamente" -ForegroundColor Green
        $completed = $true
        break
    }
    
    if ($buildStatus -eq "FAILED") {
        $failureReason = $buildInfo.builds[0].failureDetails.message
        Write-Host "`n[ERROR] Build fallo" -ForegroundColor Red
        Write-Host "Razon: $failureReason" -ForegroundColor Red
        exit 1
    }
    
    if ($buildStatus -eq "FAULT") {
        Write-Host "`n[ERROR] Error en infraestructura de CodeBuild" -ForegroundColor Red
        exit 1
    }
    
    Start-Sleep -Seconds 10
}

if (-not $completed) {
    Write-Host "`n[ERROR] Timeout esperando build (> 30 minutos)" -ForegroundColor Red
    exit 1
}

Write-Host "`n================================" -ForegroundColor Green
Write-Host "IMAGEN CREADA EXITOSAMENTE" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

exit 0
