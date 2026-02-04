# Script para iniciar CodeBuild y esperar a que se complete
param(
    [string]$ProjectName = "fraudes-docker-build-prod",
    [string]$Region = "us-east-1"
)

Write-Host "[CODEBUILD] Iniciando build para proyecto: $ProjectName"

# Iniciar el build
$buildStartResult = aws codebuild start-build --project-name $ProjectName --region $Region --query 'build.id' --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] No se pudo iniciar CodeBuild"
    exit 1
}

$buildId = $buildStartResult
Write-Host "[CODEBUILD] Build iniciado: $buildId"

# Esperar a que se complete (maximo 30 minutos)
$maxWaitSeconds = 1800
$startTime = Get-Date
$completed = $false
$loopCount = 0

while ((Get-Date) -lt $startTime.AddSeconds($maxWaitSeconds)) {
    $loopCount = $loopCount + 1
    
    # Obtener estado del build
    $buildStatus = aws codebuild batch-get-builds --ids $buildId --region $Region --query 'builds[0].buildStatus' --output text
    
    Write-Host "[CODEBUILD] Iteracion $loopCount - Status: $buildStatus"
    
    if ($buildStatus -eq "SUCCEEDED") {
        Write-Host "[CODEBUILD] Build completado exitosamente"
        $completed = $true
        break
    }
    
    if ($buildStatus -eq "FAILED") {
        Write-Host "[ERROR] Build fallo"
        exit 1
    }
    
    if ($buildStatus -eq "FAULT") {
        Write-Host "[ERROR] Error en infraestructura de CodeBuild"
        exit 1
    }
    
    # Esperar 10 segundos antes de la proxima verificacion
    Start-Sleep -Seconds 10
}

if (-not $completed) {
    Write-Host "[ERROR] Timeout esperando el build - mas de 30 minutos"
    exit 1
}

Write-Host "[CODEBUILD] Completado correctamente"
exit 0
