resource "aws_cloudwatch_metric_alarm" "demo_resource_count" {
  alarm_name                = "demo-resource-count"
  namespace                 = "AWS/Usage"
  metric_name               = "ResourceCount"
  evaluation_periods        = "1"
  period                    = "60"
  statistic                 = "Minimum"
  comparison_operator       = "LessThanThreshold"
  threshold                 = "1"
  alarm_actions             = [aws_sns_topic.alarm_notifier_topic.arn]
  ok_actions                = [aws_sns_topic.alarm_notifier_topic.arn]

  dimensions = {
    Service  = "EC2"
    Type     = "Resource"
    Resource = "vCPU"
    Class    = "Standard/OnDemand"
  }
}

resource "aws_cloudwatch_metric_alarm" "demo_status_check" {
  alarm_name                = "demo-status-check"
  namespace                 = "AWS/EC2"
  metric_name               = "StatusCheckFailed"
  evaluation_periods        = "1"
  period                    = "60"
  statistic                 = "Maximum"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = "1"
  alarm_actions             = [aws_sns_topic.alarm_notifier_topic.arn]
  ok_actions                = [aws_sns_topic.alarm_notifier_topic.arn]

  depends_on = [
    aws_instance.demo_server,
    aws_sns_topic.alarm_notifier_topic
  ]

  dimensions = {
    InstanceId = aws_instance.demo_server.id
  }
}

resource "aws_cloudwatch_metric_alarm" "demo_cpu_usage" {
  alarm_name                = "demo-cpu-utilization"
  namespace                 = "AWS/EC2"
  metric_name               = "CPUUtilization"
  evaluation_periods        = "5"
  period                    = "60"
  statistic                 = "Average"
comparison_operator         = "GreaterThanOrEqualToThreshold"
  threshold                 = "80"
  alarm_actions             = [aws_sns_topic.alarm_notifier_topic.arn]
  ok_actions                = [aws_sns_topic.alarm_notifier_topic.arn]

  depends_on = [
    aws_instance.demo_server,
    aws_sns_topic.alarm_notifier_topic
  ]

  dimensions = {
    InstanceId = aws_instance.demo_server.id
  }
}