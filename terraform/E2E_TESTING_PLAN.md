# Plan de Testing End-to-End (E2E)

## Objetivo
Verificar que todo el pipeline de Terraform funciona correctamente desde cero, sin errores en ninguno de los pasos.

## Prerequisitos
- CodeBuild debe completarse exitosamente y la imagen debe estar en ECR
- Todos los logs deben ser limpios (sin errores)

## Pasos del Testing E2E

### FASE 1: Verificación Post-Build
1. ✓ Esperar a que CodeBuild termine (Status = SUCCEEDED)
2. ✓ Verificar que la imagen está en ECR:
   ```
   aws ecr describe-images --repository-name fraud-detection-api --region us-east-1
   ```
3. ✓ Capturar logs de CodeBuild para verificar que el build fue limpio

### FASE 2: Limpieza Completa (Destroy)
4. Ejecutar terraform destroy -auto-approve para eliminar:
   - null_resource.trigger_codebuild
   - aws_codebuild_project.docker_build
   - aws_cloudwatch_log_stream.codebuild
   - aws_cloudwatch_log_group.codebuild
   - aws_iam_role_policy.codebuild_logs
   - aws_iam_role_policy.codebuild_ecr
   - aws_iam_role.codebuild_role
   - aws_ecr_repository.fraud_detection (si se destruye ECR)
   
5. Eliminar imagen de ECR manualmente (si no se destruyó con ECR):
   ```
   aws ecr batch-delete-image --repository-name fraud-detection-api \
     --image-ids imageTag=latest --region us-east-1
   ```

### FASE 3: Verificación de Limpieza
6. Verificar que ECR está vacío o no existe
7. Verificar que IAM roles fueron eliminados
8. Verificar que CodeBuild project fue eliminado
9. Verificar que logs fueron eliminados

### FASE 4: Re-ejecución desde Cero (terraform apply -auto-approve)
10. Ejecutar terraform apply -auto-approve
11. Verificar que se crean exactamente estos recursos:
    - aws_ecr_repository
    - aws_iam_role
    - aws_iam_role_policy (x2)
    - aws_cloudwatch_log_group
    - aws_cloudwatch_log_stream
    - aws_codebuild_project
    - null_resource.trigger_codebuild

### FASE 5: Verificación Final
12. Esperar a que CodeBuild se complete nuevamente
13. Verificar que la imagen se pusheó a ECR
14. Verificar que no hay errores en los logs
15. Confirmar que el pipeline es determinístico (resultado igual que la primera ejecución)

## Criterios de Éxito
- ✅ Todos los recursos se crean exitosamente en terraform apply
- ✅ CodeBuild se ejecuta sin errores
- ✅ Imagen se pushea a ECR correctamente
- ✅ Terraform destroy elimina todos los recursos
- ✅ Segunda ejecución produce resultado idéntico
- ✅ No hay estado corrupto ni recursos huérfanos

## Timeline Estimado
- Esperar CodeBuild (primera vez): 10-15 minutos
- Destroy: 2-5 minutos
- Apply (segunda vez): 5 minutos
- Esperar CodeBuild (segunda vez): 10-15 minutos
- TOTAL: 30-40 minutos
