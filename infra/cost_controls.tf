# Simplified Cost Controls
# This file sets up basic AWS Budgets to monitor costs

# Create a simple budget to monitor total costs
resource "aws_budgets_budget" "monthly_budget" {
  name         = "idfs-monthly-budget"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  # Alert when 80% of budget is reached ($8)
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

  tags = local.common_tags
}

# Additional budget for hard cap monitoring at $20
resource "aws_budgets_budget" "hard_cap_budget" {
  name         = "idfs-hard-cap-budget"
  budget_type  = "COST"
  limit_amount = "20"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

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

# SNS topic for cost alerts
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

# Output budget information
output "budget_alerts" {
  description = "Budget alert configuration"
  value = {
    monthly_budget_arn = aws_budgets_budget.monthly_budget.arn
    sns_topic_arn      = aws_sns_topic.cost_alerts.arn
  }
}