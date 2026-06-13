output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.loki.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.loki.arn
}

output "region" {
  description = "AWS region for the S3 bucket"
  value       = var.region
}

output "iam_user_name" {
  description = "Name of the IAM user"
  value       = aws_iam_user.loki.name
}

output "iam_user_arn" {
  description = "ARN of the IAM user"
  value       = aws_iam_user.loki.arn
}

output "access_key_id" {
  description = "AWS Access Key ID for Loki"
  value       = aws_iam_access_key.loki.id
}

output "secret_access_key" {
  description = "AWS Secret Access Key for Loki"
  value       = aws_iam_access_key.loki.secret
  sensitive   = true
}

output "env_config" {
  description = "Copy these values into your .env file"

  value = <<EOT
AWS_ACCESS_KEY_ID=${aws_iam_access_key.loki.id}
AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.loki.secret}
AWS_REGION=${var.region}
LOKI_BUCKET=${aws_s3_bucket.loki.id}
EOT

  sensitive = true
}
