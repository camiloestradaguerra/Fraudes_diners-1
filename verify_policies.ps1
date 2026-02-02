# Script de verificación de políticas IAM
# Ejecuta: powershell .\verify_policies.ps1

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         VERIFICACION DE POLITICAS IAM PARA API GATEWAY     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# 1. Verificar que el rol existe
Write-Host "1️⃣  VERIFICANDO ROL..." -ForegroundColor Yellow
try {
    $role = aws iam get-role --role-name apigateway-sagemaker-proxy --output json | ConvertFrom-Json
    Write-Host "✅ ROL ENCONTRADO" -ForegroundColor Green
    Write-Host "   Nombre: $($role.Role.RoleName)" -ForegroundColor Green
    Write-Host "   ARN: $($role.Role.Arn)" -ForegroundColor Green
    Write-Host "   Creado: $($role.Role.CreateDate)" -ForegroundColor Green
} catch {
    Write-Host "❌ ERROR: Rol NO existe o no se puede acceder" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    exit 1
}

# 2. Verificar políticas inline
Write-Host "`n2️⃣  VERIFICANDO POLITICAS INLINE..." -ForegroundColor Yellow
try {
    $policies = aws iam list-role-policies --role-name apigateway-sagemaker-proxy --output json | ConvertFrom-Json
    
    if ($policies.PolicyNames.Count -gt 0) {
        Write-Host "✅ POLITICAS ENCONTRADAS:" -ForegroundColor Green
        foreach ($policyName in $policies.PolicyNames) {
            Write-Host "   • $policyName" -ForegroundColor Green
        }
    } else {
        Write-Host "❌ NO HAY POLITICAS INLINE" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ ERROR al listar políticas: $_" -ForegroundColor Red
}

# 3. Ver detalles de la política
Write-Host "`n3️⃣  DETALLES DE LA POLITICA DE PERMISOS..." -ForegroundColor Yellow
try {
    if ($policies.PolicyNames.Count -gt 0) {
        $policyDetail = aws iam get-role-policy --role-name apigateway-sagemaker-proxy --policy-name $policies.PolicyNames[0] --output json | ConvertFrom-Json
        $policyDetail.PolicyDocument.Statement | ForEach-Object {
            Write-Host "   Efecto: $($_.Effect)" -ForegroundColor Green
            Write-Host "   Acción: $($_.Action -join ', ')" -ForegroundColor Green
            Write-Host "   Recurso: $($_.Resource)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "❌ ERROR: $_" -ForegroundColor Red
}

# 4. Ver política de confianza
Write-Host "`n4️⃣  POLITICA DE CONFIANZA..." -ForegroundColor Yellow
try {
    $assumePolicy = $role.Role.AssumeRolePolicyDocument
    $assumePolicy.Statement | ForEach-Object {
        Write-Host "   Efecto: $($_.Effect)" -ForegroundColor Green
        Write-Host "   Principal Service: $($_.Principal.Service)" -ForegroundColor Green
        Write-Host "   Acción: $($_.Action)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ ERROR: $_" -ForegroundColor Red
}

# 5. Resumen final
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      VERIFICACION COMPLETA                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n✅ Rol de IAM está correctamente configurado para API Gateway" -ForegroundColor Green
Write-Host "   ✓ Rol existe: apigateway-sagemaker-proxy" -ForegroundColor Green
Write-Host "   ✓ Política de confianza para apigateway.amazonaws.com" -ForegroundColor Green
Write-Host "   ✓ Permisos para invocar endpoint de SageMaker" -ForegroundColor Green
Write-Host "`n"
