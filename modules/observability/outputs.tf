output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alarm_arns" {
  description = "ARNs of CloudWatch alarms"
  value = {
    rate_limit_hits = aws_cloudwatch_metric_alarm.high_rate_limit_hits.arn
    lambda_errors   = aws_cloudwatch_metric_alarm.lambda_errors.arn
    lambda_throttles = aws_cloudwatch_metric_alarm.lambda_throttles.arn
    api_4xx_errors  = aws_cloudwatch_metric_alarm.api_4xx_errors.arn
    api_5xx_errors  = aws_cloudwatch_metric_alarm.api_5xx_errors.arn
  }
}

