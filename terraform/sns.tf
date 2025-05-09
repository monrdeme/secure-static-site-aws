resource "aws_sns_topic" "security_alerts" {
  name = "${var.project}-security-alerts"
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.email
}
