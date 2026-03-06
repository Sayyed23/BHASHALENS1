# S3 Module - Two Buckets
# BhashaLens AWS Infrastructure

# ─────────────────────────────────────────────
# Translation Export Bucket
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "translation_exports" {
  bucket = "${var.project_name}-translation-exports-${var.account_id}"

  tags = {
    Name = "${var.project_name}-translation-exports"
  }
}

resource "aws_s3_bucket_versioning" "translation_exports" {
  bucket = aws_s3_bucket.translation_exports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "translation_exports" {
  bucket = aws_s3_bucket.translation_exports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "translation_exports" {
  bucket = aws_s3_bucket.translation_exports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 7-day lifecycle for export files
resource "aws_s3_bucket_lifecycle_configuration" "translation_exports" {
  bucket = aws_s3_bucket.translation_exports.id

  rule {
    id     = "delete-exports-after-7-days"
    status = "Enabled"
    filter {}

    expiration {
      days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# CORS for Amplify domain access
resource "aws_s3_bucket_cors_configuration" "translation_exports" {
  bucket = aws_s3_bucket.translation_exports.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag", "Content-Length"]
    max_age_seconds = 3600
  }
}

# ─────────────────────────────────────────────
# Static Assets Bucket
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-static-assets-${var.account_id}"

  tags = {
    Name = "${var.project_name}-static-assets"
  }
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
# Public read for static assets via bucket policy
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_assets_public_read" {
  bucket = aws_s3_bucket.static_assets.id

  depends_on = [aws_s3_bucket_public_access_block.static_assets]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_assets.arn}/*"
      }
    ]
  })
}

# Lifecycle: transition old versions to Glacier after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
