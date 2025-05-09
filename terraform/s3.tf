resource "aws_s3_bucket" "website" {
  bucket = var.project
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_encryption" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "website_versioning" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "website_access" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*"
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
      {
        Sid    = "AllowAdminRoleAccess",
        Effect = "Allow",
        Principal = {
          AWS = "${aws_iam_role.admin_role.arn}"
        },
        Action = "s3:*",
        Resource = [
          "${aws_s3_bucket.website.arn}",
          "${aws_s3_bucket.website.arn}/*"
        ]
      },
      {
        Sid    = "AllowWriteOnlyRoleAccess",
        Effect = "Allow",
        Principal = {
          AWS = "${aws_iam_role.write_only_role.arn}"
        },
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "${aws_s3_bucket.website.arn}/*"
      },
      {
        Sid    = "AllowReadOnlyAccess",
        Effect = "Allow",
        Principal = {
          AWS = "${aws_iam_role.read_only_role.arn}"
        },
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.website.arn}",
          "${aws_s3_bucket.website.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket" "logging" {
  bucket = "${var.project}-logging"
}

resource "aws_s3_bucket_versioning" "logging_versioning" {
  bucket = aws_s3_bucket.logging.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logging_policy" {
  bucket = aws_s3_bucket.logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudTrailS3AclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${aws_s3_bucket.logging.id}"
      },
      {
        Sid    = "CloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.logging.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
