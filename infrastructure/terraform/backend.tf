# Terraform Backend Configuration
# S3 backend with DynamoDB locking for state management
#
# To use: uncomment the backend block and configure with your bucket.
# First create the S3 bucket and DynamoDB table manually or via bootstrap script:
#
#   aws s3api create-bucket --bucket bhashalens-terraform-state --region us-east-1
#   aws dynamodb create-table --table-name bhashalens-terraform-locks \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST

# terraform {
#   backend "s3" {
#     bucket         = "bhashalens-terraform-state"
#     key            = "dev/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "bhashalens-terraform-locks"
#   }
# }
