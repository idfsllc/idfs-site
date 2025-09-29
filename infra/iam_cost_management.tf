# IAM policies for cost management and budget monitoring
# This file creates the necessary IAM roles and policies for cost controls

# IAM role for cost management
resource "aws_iam_role" "cost_management_role" {
  name = "idfs-cost-management-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "budgets.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for cost management permissions
resource "aws_iam_policy" "cost_management_policy" {
  name        = "idfs-cost-management-policy"
  description = "Policy for cost management and budget monitoring"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "budgets:ViewBudget",
          "budgets:ModifyBudget",
          "budgets:CreateBudget",
          "budgets:DeleteBudget",
          "budgets:DescribeBudgets",
          "budgets:DescribeBudgetPerformanceHistory",
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetReservationCoverage",
          "ce:GetReservationPurchaseRecommendation",
          "ce:GetReservationUtilization",
          "ce:GetUsageReport",
          "ce:ListCostCategoryDefinitions",
          "ce:GetCostCategories",
          "ce:GetAnomalyMonitors",
          "ce:GetAnomalySubscriptions",
          "ce:GetAnomalies",
          "ce:CreateAnomalyMonitor",
          "ce:CreateAnomalySubscription",
          "ce:UpdateAnomalyMonitor",
          "ce:UpdateAnomalySubscription",
          "ce:DeleteAnomalyMonitor",
          "ce:DeleteAnomalySubscription",
          "sns:Publish",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListSubscriptions",
          "sns:ListTopics",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "cost_management_policy_attachment" {
  role       = aws_iam_role.cost_management_role.name
  policy_arn = aws_iam_policy.cost_management_policy.arn
}

# IAM policy for Lambda to access cost information (if needed)
resource "aws_iam_policy" "lambda_cost_policy" {
  name        = "idfs-lambda-cost-policy"
  description = "Policy for Lambda to access cost information"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetUsageReport"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach cost policy to Lambda role (if needed)
resource "aws_iam_role_policy_attachment" "lambda_cost_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_cost_policy.arn
}
