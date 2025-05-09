data "aws_caller_identity" "current" {}

resource "aws_iam_user" "user" {
  name = "${var.project}-user"
}

resource "aws_iam_access_key" "user_access_key" {
  user = aws_iam_user.user.name
}

resource "aws_iam_role" "admin_role" {
  name = "${var.project}-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.user.name}"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "admin_policy" {
  name = "admin-policy"
  role = aws_iam_role.admin_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "assume_admin_role" {
  name = "${var.project}-assume-admin-role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-admin"
    }]
  })
}

resource "aws_iam_policy_attachment" "attach_assume_admin_role" {
  name       = "${var.project}-attach-assume-admin-role"
  users      = [aws_iam_user.user.name]
  policy_arn = aws_iam_policy.assume_admin_role.arn
}

resource "aws_iam_role" "write_only_role" {
  name = "${var.project}-write-only"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.user.name}"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "write_only_policy" {
  name = "write-only-policy"
  role = aws_iam_role.write_only_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      Resource = "arn:aws:s3:::${var.project}/*"
    }]
  })
}

resource "aws_iam_policy" "assume_write_only_role" {
  name = "${var.project}-assume-write-only-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-write-only"
    }]
  })
}

resource "aws_iam_policy_attachment" "attach_assume_write_only_role" {
  name       = "${var.project}-attach-assume-write-only-role"
  users      = [aws_iam_user.user.name]
  policy_arn = aws_iam_policy.assume_write_only_role.arn
}

resource "aws_iam_role" "read_only_role" {
  name = "${var.project}-read-only"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.user.name}"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "read_only_policy" {
  name = "read-only-policy"
  role = aws_iam_role.read_only_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.project}",
        "arn:aws:s3:::${var.project}/*"
      ]
    }]
  })
}

resource "aws_iam_policy" "assume_read_only_role" {
  name = "${var.project}-assume-read-only-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-read-only"
    }]
  })
}

resource "aws_iam_policy_attachment" "attach_assume_read_only_role" {
  name       = "${var.project}-attach-assume-read-only-role"
  users      = [aws_iam_user.user.name]
  policy_arn = aws_iam_policy.assume_read_only_role.arn
}

resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.project}-cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "${var.project}-cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "${aws_cloudwatch_log_group.trail.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role" "eventbridge_sns_role" {
  name = "${var.project}-eventbridge-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_sns_policy" {
  name = "${var.project}-eventbridge-sns-policy"
  role = aws_iam_role.eventbridge_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = "${aws_sns_topic.security_alerts.arn}"
      }
    ]
  })
}
