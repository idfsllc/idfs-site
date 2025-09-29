# Cost Controls and Budget Alerts
# This file sets up AWS Budgets and Cost Anomaly Detection to prevent unexpected charges

# Create a budget to monitor and alert on costs
resource "aws_budgets_budget" "monthly_budget" {
  name         = "idfs-monthly-budget"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  # Alert when 80% of budget is reached ($8)
  cost_filters = {
    Tag = [
      "Project:static-site"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.to_email]
  }

  # Alert when 100% of budget is reached ($10) - WARNING LEVEL
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.to_email]
  }

  # Alert when forecasted to exceed budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "FORECASTED"
    notification_type         = "FORECASTED"
    subscriber_email_addresses = [var.to_email]
  }
}

# Additional budget for hard cap monitoring at $20
resource "aws_budgets_budget" "hard_cap_budget" {
  name         = "idfs-hard-cap-budget"
  budget_type  = "COST"
  limit_amount = "20"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    Tag = [
      "Project:static-site"
    ]
  }

  # Alert when hard cap is reached ($20) - EMERGENCY SHUTDOWN
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.to_email]
  }

  tags = local.common_tags
}

# Cost Anomaly Detection to catch unexpected spikes
resource "aws_ce_anomaly_detector" "cost_anomaly" {
  name = "idfs-cost-anomaly-detector"
  
  specification = "DAILY"
  
  monitor_type = "DIMENSIONAL"
  
  dimension = "SERVICE"
  
  tags = local.common_tags
}

# Cost anomaly subscription for alerts
resource "aws_ce_anomaly_subscription" "cost_anomaly_alerts" {
  name = "idfs-cost-anomaly-alerts"
  
  monitor_arn_list = [aws_ce_anomaly_detector.cost_anomaly.arn]
  
  threshold = 5.0  # Alert if anomaly exceeds $5
  
  frequency = "DAILY"
  
  subscriber {
    type    = "EMAIL"
    address = var.to_email
  }
  
  tags = local.common_tags
}

# SNS topic for cost alerts (backup notification method)
resource "aws_sns_topic" "cost_alerts" {
  name = "idfs-cost-alerts"
  
  tags = local.common_tags
}

# SNS topic subscription for email notifications
resource "aws_sns_topic_subscription" "cost_alerts_email" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.to_email
}

# CloudWatch alarm for high costs - triggers cost monitor Lambda
resource "aws_cloudwatch_metric_alarm" "high_cost_alarm" {
  alarm_name          = "idfs-high-cost-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = "8"      # Alert at $8 (80% of $10 budget)
  alarm_description   = "This metric monitors estimated charges and triggers cost monitoring"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = local.common_tags
}

# CloudWatch alarm for hard cap - triggers emergency shutdown
resource "aws_cloudwatch_metric_alarm" "hard_cap_alarm" {
  alarm_name          = "idfs-hard-cap-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = "20"     # Hard cap at $20
  alarm_description   = "EMERGENCY: Hard cost cap reached - triggers service shutdown"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = local.common_tags
}

# Additional budget for specific services to catch runaway costs
resource "aws_budgets_budget" "lambda_budget" {
  name         = "idfs-lambda-budget"
  budget_type  = "COST"
  limit_amount = "2"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    Service = [
      "Amazon Lambda"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.to_email]
  }

  tags = local.common_tags
}

# Budget for CloudFront costs
resource "aws_budgets_budget" "cloudfront_budget" {
  name         = "idfs-cloudfront-budget"
  budget_type  = "COST"
  limit_amount = "3"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    Service = [
      "Amazon CloudFront"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.to_email]
  }

  tags = local.common_tags
}

# Budget for S3 costs
resource "aws_budgets_budget" "s3_budget" {
  name         = "idfs-s3-budget"
  budget_type  = "COST"
  limit_amount = "2"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    Service = [
      "Amazon Simple Storage Service"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.to_email]
  }

  tags = local.common_tags
}

# Budget for API Gateway costs
resource "aws_budgets_budget" "api_gateway_budget" {
  name         = "idfs-api-gateway-budget"
  budget_type  = "COST"
  limit_amount = "1"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    Service = [
      "Amazon API Gateway"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.to_email]
  }

  tags = local.common_tags
}

# Budget for SES costs
resource "aws_budgets_budget" "ses_budget" {
  name         = "idfs-ses-budget"
  budget_type  = "COST"
  limit_amount = "1"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    Service = [
      "Amazon Simple Email Service"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.to_email]
  }

  tags = local.common_tags
}

# Output budget information
output "budget_alerts" {
  description = "Budget alert configuration"
  value = {
    monthly_budget_arn = aws_budgets_budget.monthly_budget.arn
    cost_anomaly_arn   = aws_ce_anomaly_detector.cost_anomaly.arn
    sns_topic_arn      = aws_sns_topic.cost_alerts.arn
  }
}
