output "access_key_id" {
  value       = aws_iam_access_key.user_access_key.id
  description = "Access key ID for IAM user"
  sensitive   = true
}

output "secret_access_key" {
  value       = aws_iam_access_key.user_access_key.secret
  description = "Secret access key for IAM user"
  sensitive   = true
}

output "website_url" {
  value       = "http://${aws_s3_bucket.website.bucket}.s3-website-${var.region}.amazonaws.com"
  description = "website url"
}
