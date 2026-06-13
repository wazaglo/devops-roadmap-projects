# =============================================================================
# S3 BUCKET
# =============================================================================

resource "aws_s3_bucket" "loki" {
  bucket = var.bucket_name

  tags = {
    Name        = "Loki Log Storage"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# =============================================================================
# S3 SERVER-SIDE ENCRYPTION (SSE-S3)
# =============================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# =============================================================================
# S3 PUBLIC ACCESS BLOCK
# =============================================================================

resource "aws_s3_bucket_public_access_block" "loki" {
  bucket = aws_s3_bucket.loki.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# IAM USER
# =============================================================================

resource "aws_iam_user" "loki" {
  name = "loki-${var.environment}"
  path = "/"

  tags = {
    Purpose     = "Loki S3 access"
    Environment = var.environment
  }
}

# =============================================================================
# IAM ACCESS KEY
# =============================================================================

resource "aws_iam_access_key" "loki" {
  user = aws_iam_user.loki.name
}

# =============================================================================
# IAM POLICY (scoped to ONLY this S3 bucket)
# =============================================================================

data "aws_iam_policy_document" "loki_s3" {
  statement {
    sid    = "LokiS3ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.loki.arn,
    ]
  }

  statement {
    sid    = "LokiS3ObjectOperations"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${aws_s3_bucket.loki.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "loki_s3" {
  name        = "loki-s3-${var.environment}"
  description = "Allow Loki to manage objects in the S3 log storage bucket"
  policy      = data.aws_iam_policy_document.loki_s3.json

  tags = {
    Environment = var.environment
  }
}

# =============================================================================
# ATTACH POLICY TO USER
# =============================================================================

resource "aws_iam_user_policy_attachment" "loki_s3" {
  user       = aws_iam_user.loki.name
  policy_arn = aws_iam_policy.loki_s3.arn
}
