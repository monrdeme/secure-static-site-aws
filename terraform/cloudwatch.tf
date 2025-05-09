resource "aws_cloudwatch_log_group" "trail" {
  name              = "/aws/cloudtrail/${var.project}-trail"
  retention_in_days = 30
}

resource "aws_cloudwatch_event_rule" "cloudtrail_rule" {
  name        = "${var.project}-cloudtrail-rule"
  description = "Captures certain CloudTrail events"
  event_pattern = jsonencode({
    "source" : ["aws.iam", "aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["iam.amazonaws.com", "s3.amazonaws.com"],
      "eventName" : [
        "CreateUser",
        "CreateBucket",
        "DeleteBucket",
        "PutObject",
        "PutBucketPolicy"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cloudtrail_sns_alert" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_rule.name
  target_id = "cloudtrail-sns-alert"
  arn       = aws_sns_topic.security_alerts.arn
  role_arn  = aws_iam_role.eventbridge_sns_role.arn
}

resource "aws_cloudwatch_event_rule" "guardduty_rule" {
  name        = "${var.project}-guardduty_rule"
  description = "Captures high severity GuardDuty findings"
  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"],
    "detail" : {
      "severity" : [8.0, 9.0, 10.0]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_sns_alert" {
  rule      = aws_cloudwatch_event_rule.guardduty_rule.name
  target_id = "guardduty-sns-alert"
  arn       = aws_sns_topic.security_alerts.arn
  role_arn  = aws_iam_role.eventbridge_sns_role.arn
}
