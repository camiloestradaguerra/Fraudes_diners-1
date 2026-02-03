# Terraform Backend - S3 (opcional, comentado para local state)

# terraform {
#   backend "s3" {
#     bucket         = "fraud-detection-terraform-state"
#     key            = "prod/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#   }
# }

# Para usar estado remoto:
# 1. Crear bucket S3: aws s3 mb s3://fraud-detection-terraform-state --region us-east-1
# 2. Habilitar versionado: aws s3api put-bucket-versioning --bucket fraud-detection-terraform-state --versioning-configuration Status=Enabled
# 3. Encriptar por defecto: aws s3api put-bucket-encryption --bucket fraud-detection-terraform-state --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
# 4. Descommentar backend arriba
