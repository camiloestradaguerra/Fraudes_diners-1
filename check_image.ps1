# Script para verificar y crear imagen Docker en ECR si no existe
# Ejecutar ANTES de terraform apply

param(
    [string]$RepositoryName = "fraud-detection-api",
    [string]$ImageTag = "latest",
    [string]$Region = "us-east-1",
    [string]$AccountId = "761951921633"
)

function Check-ImageInECR {
    param([string]$RepoName, [string]$Tag, [string]$Region)
    
    try {
        $result = aws ecr describe-images `
            --repository-name $RepoName `
            --region $Region `
            --query "imageDetails[?imageTags[?contains(@, '$Tag')]].imageTags" `
            --output text 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            Write-Host "[ECR] Imagen encontrada: $RepoName:$Tag" -ForegroundColor Green
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function Create-ECRRepository {
    param([string]$RepoName, [string]$Region)
    
    Write-Host "[ECR] Creando repositorio: $RepoName" -ForegroundColor Yellow
    
    aws ecr create-repository `
        --repository-name $RepoName `
        --region $Region `
        --image-scanning-configuration scanOnPush=true `
        --encryption-configuration encryptionType=AES256 `
        --tags Key=ManagedBy,Value=Terraform Key=Environment,Value=prod 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[ECR] Repositorio creado exitosamente" -ForegroundColor Green
        return $true
    }
    return $false
}

function Build-DockerImage {
    param([string]$RepoName, [string]$Tag, [string]$Region, [string]$AccountId)
    
    Write-Host "[CodeBuild] Compilando imagen Docker..." -ForegroundColor Yellow
    
    # El proyecto CodeBuild debe estar definido en Terraform
    # Este script asume que ya existe o lo crea Terraform primero
    
    $ImageUri = "$AccountId.dkr.ecr.$Region.amazonaws.com/$RepoName:$Tag"
    Write-Host "[Build] URI de imagen: $ImageUri" -ForegroundColor Cyan
    
    # Aquí se ejecutaría CodeBuild
    # Por ahora solo es un placeholder
    
    return $false
}

# INICIO DEL SCRIPT

Write-Host "================================" -ForegroundColor Green
Write-Host "VERIFICACION DE IMAGEN DOCKER" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

Write-Host "`n[1] Verificando si imagen existe en ECR..." -ForegroundColor Cyan

$imageExists = Check-ImageInECR -RepoName $RepositoryName -Tag $ImageTag -Region $Region

if ($imageExists) {
    Write-Host "[OK] La imagen Docker ya existe en ECR - no hay que compilar" -ForegroundColor Green
    Write-Host "     Continuando con Terraform..." -ForegroundColor Green
    exit 0
}

Write-Host "[2] Imagen NO existe - necesita ser compilada" -ForegroundColor Yellow
Write-Host "     Pasos necesarios:" -ForegroundColor Yellow
Write-Host "     a) ECR repository" -ForegroundColor Yellow
Write-Host "     b) CodeBuild project" -ForegroundColor Yellow
Write-Host "     c) Ejecutar build" -ForegroundColor Yellow
Write-Host "     d) Esperar a que complete" -ForegroundColor Yellow

exit 1
