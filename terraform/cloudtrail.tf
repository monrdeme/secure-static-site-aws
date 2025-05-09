resource "aws_cloudtrail" "cloudtrail_config" {
  name                          = "${var.project}-trail"
  s3_bucket_name                = aws_s3_bucket.logging.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn

  depends_on = [
    aws_cloudwatch_log_group.trail,
    aws_iam_role.cloudtrail_cloudwatch_role,
    aws_iam_role_policy.cloudtrail_cloudwatch_policy
  ]
}
