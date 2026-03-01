# S3 Buckets for BhashaLens

# Language Packs and Models Bucket
resource "aws_s3_bucket" "language_packs" {
  bucket = "${var.project_name}-models-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name = "${var.project_name}-models"
  }
}

# Enable versioning for language packs bucket
resource "aws_s3_bucket_versioning" "language_packs_versioning" {
  bucket = aws_s3_bucket.language_packs.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption with AES-256
resource "aws_s3_bucket_server_side_encryption_configuration" "language_packs_encryption" {
  bucket = aws_s3_bucket.language_packs.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "language_packs_public_access_block" {
  bucket = aws_s3_bucket.language_packs.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "language_packs_lifecycle" {
  bucket = aws_s3_bucket.language_packs.id
  
  rule {
    id     = "archive-old-versions"
    status = "Enabled"
    
    noncurrent_version_transition {
      noncurrent_days = var.s3_lifecycle_glacier_days
      storage_class   = "GLACIER"
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
  
  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# CORS configuration for direct uploads from mobile app
resource "aws_s3_bucket_cors_configuration" "language_packs_cors" {
  bucket = aws_s3_bucket.language_packs.id
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Bucket policy for Lambda access
resource "aws_s3_bucket_policy" "language_packs_policy" {
  bucket = aws_s3_bucket.language_packs.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_execution_role.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.language_packs.arn,
          "${aws_s3_bucket.language_packs.arn}/*"
        ]
      }
    ]
  })
}

# CloudWatch Logs Bucket (for API Gateway and Lambda logs archival)
resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name = "${var.project_name}-logs"
  }
}

# Enable versioning for logs bucket
resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = aws_s3_bucket.logs.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access for logs bucket
resource "aws_s3_bucket_public_access_block" "logs_public_access_block" {
  bucket = aws_s3_bucket.logs.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs.id
  
  rule {
    id     = "archive-old-logs"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = var.s3_lifecycle_glacier_days
      storage_class = "GLACIER"
    }
    
    expiration {
      days = 365
    }
  }
}

# Outputs
output "language_packs_bucket_name" {
  description = "Name of the language packs S3 bucket"
  value       = aws_s3_bucket.language_packs.bucket
}

output "language_packs_bucket_arn" {
  description = "ARN of the language packs S3 bucket"
  value       = aws_s3_bucket.language_packs.arn
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = aws_s3_bucket.logs.arn
}
