# Script de deployment automatizado
# 1. Ejecuta terraform plan y apply para crear infraestructura
# 2. Ejecuta CodeBuild para compilar la imagen Docker
# 3. Espera a que complete

param(
    [string]$TerraformDir = "./terraform",
    [string]$ProjectName = "fraudes-docker-build-prod",
    [string]$Region = "us-east-1"
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT AUTOMATIZADO FRAUDES DINERS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Paso 1: Ejecutar terraform plan
Write-Host "`n[1/3] Creando infraestructura base con Terraform..." -ForegroundColor Yellow
Set-Location $TerraformDir
rm tfplan* -ErrorAction SilentlyContinue
terraform plan -out=tfplan 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Error en terraform plan" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Plan de Terraform creado" -ForegroundColor Green

# Paso 2: Ejecutar terraform apply (crea CodeBuild, SageMaker, etc)
Write-Host "`n[2/3] Desplegando infraestructura (crea CodeBuild, SageMaker, API Gateway)..." -ForegroundColor Yellow
terraform apply -auto-approve tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Error en terraform apply" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Infraestructura creada" -ForegroundColor Green

# Paso 3: Construir imagen Docker con CodeBuild
Write-Host "`n[3/3] Compilando imagen Docker con CodeBuild..." -ForegroundColor Yellow

$buildStartResult = aws codebuild start-build --project-name $ProjectName --region $Region --query 'build.id' --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] No se pudo iniciar CodeBuild" -ForegroundColor Red
    exit 1
}

$buildId = $buildStartResult
Write-Host "[OK] Build iniciado: $buildId" -ForegroundColor Green

# Esperar a que se complete
Write-Host "[Esperando compilacion...]" -ForegroundColor Cyan
$maxWaitSeconds = 1800
$startTime = Get-Date
$completed = $false

while ((Get-Date) -lt $startTime.AddSeconds($maxWaitSeconds)) {
    $buildStatus = aws codebuild batch-get-builds --ids $buildId --region $Region --query 'builds[0].buildStatus' --output text
    
    $elapsedSeconds = [int]((Get-Date) - $startTime).TotalSeconds
    $elapsedMinutes = [int]($elapsedSeconds / 60)
    
    Write-Host "  [$($elapsedMinutes)min] Status: $buildStatus" -ForegroundColor Cyan
    
    if ($buildStatus -eq "SUCCEEDED") {
        Write-Host "[OK] Imagen compilada correctamente" -ForegroundColor Green
        $completed = $true
        break
    }
    
    if ($buildStatus -eq "FAILED") {
        Write-Host "[ERROR] La compilacion fallo" -ForegroundColor Red
        Write-Host "Revisa los logs en CloudWatch: /aws/codebuild/$ProjectName/docker-build-stream" -ForegroundColor Red
        exit 1
    }
    
    if ($buildStatus -eq "FAULT") {
        Write-Host "[ERROR] Error en infraestructura de CodeBuild" -ForegroundColor Red
        exit 1
    }
    
    Start-Sleep -Seconds 10
}

if (-not $completed) {
    Write-Host "[ERROR] Timeout esperando compilacion (> 30 minutos)" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETADO EXITOSAMENTE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Mostrar outputs
Write-Host "`nInformacion de deployment:" -ForegroundColor Green
terraform output deployment_info 2>/dev/null

exit 0
