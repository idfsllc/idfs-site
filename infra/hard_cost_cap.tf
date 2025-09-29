# Hard Cost Cap - Automatic Service Shutdown
# This Lambda function monitors costs and automatically shuts down services at $20

# Lambda function for cost monitoring and automatic shutdown
resource "aws_lambda_function" "cost_monitor" {
  filename         = "${path.module}/cost_monitor_lambda.zip"
  function_name    = "idfs-cost-monitor"
  role            = aws_iam_role.cost_monitor_role.arn
  handler         = "cost_monitor.lambda_handler"
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 128

  environment {
    variables = {
      SHUTDOWN_THRESHOLD = "20"  # Hard cap at $20
      ALERT_THRESHOLD    = "10"  # Alert at $10
      NOTIFICATION_EMAIL = var.to_email
      PROJECT_TAG        = "static-site"
    }
  }

  tags = local.common_tags
}

# Create the cost monitor Lambda deployment package
data "archive_file" "cost_monitor_lambda" {
  type        = "zip"
  output_path = "${path.module}/cost_monitor_lambda.zip"
  
  source {
    content = <<EOF
import json
import boto3
import os
from datetime import datetime, timedelta

def lambda_handler(event, context):
    """
    Monitor AWS costs and automatically shut down services if threshold exceeded
    """
    
    # Initialize AWS clients
    ce_client = boto3.client('ce')
    lambda_client = boto3.client('lambda')
    cloudfront_client = boto3.client('cloudfront')
    s3_client = boto3.client('s3')
    ses_client = boto3.client('ses')
    
    # Get thresholds from environment
    shutdown_threshold = float(os.environ['SHUTDOWN_THRESHOLD'])
    alert_threshold = float(os.environ['ALERT_THRESHOLD'])
    notification_email = os.environ['NOTIFICATION_EMAIL']
    project_tag = os.environ['PROJECT_TAG']
    
    try:
        # Get current month's costs
        end_date = datetime.now().strftime('%Y-%m-%d')
        start_date = datetime.now().replace(day=1).strftime('%Y-%m-%d')
        
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date,
                'End': end_date
            },
            Granularity='MONTHLY',
            Metrics=['BlendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ]
        )
        
        # Calculate total cost
        total_cost = 0.0
        service_costs = {}
        
        for result in response['ResultsByTime']:
            for group in result['Groups']:
                service = group['Keys'][0]
                cost = float(group['Metrics']['BlendedCost']['Amount'])
                total_cost += cost
                service_costs[service] = cost
        
        print("Total cost for current month: $" + str(round(total_cost, 2)))
        
        # Send alert if approaching threshold
        if total_cost >= alert_threshold and total_cost < shutdown_threshold:
            send_alert_email(
                ses_client, 
                notification_email, 
                "Cost Alert: $" + str(round(total_cost, 2)) + " (Threshold: " + str(alert_threshold) + ")",
                "Current AWS costs are at $" + str(round(total_cost, 2)) + ", approaching shutdown threshold of " + str(shutdown_threshold) + "."
            )
        
        # Hard shutdown if threshold exceeded
        if total_cost >= shutdown_threshold:
            print("COST THRESHOLD EXCEEDED: $" + str(round(total_cost, 2)) + " >= " + str(shutdown_threshold))
            
            # Send business-friendly shutdown notification
            send_alert_email(
                ses_client,
                notification_email,
                "BUSINESS ALERT: Contact Form Disabled - Cost: $" + str(round(total_cost, 2)),
                "Cost threshold of " + str(shutdown_threshold) + " exceeded. Contact form has been disabled to reduce costs, but your website remains fully accessible. No DNS changes needed."
            )
            
            # Shutdown services
            shutdown_services(
                lambda_client,
                cloudfront_client, 
                s3_client,
                project_tag
            )
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Contact form disabled due to cost threshold: $' + str(round(total_cost, 2)) + ' - Website remains accessible',
                    'total_cost': total_cost,
                    'threshold': shutdown_threshold,
                    'business_impact': 'Website accessible, contact form disabled'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Cost monitoring completed',
                'total_cost': total_cost,
                'threshold': shutdown_threshold,
                'service_costs': service_costs
            })
        }
        
    except Exception as e:
        print("Error in cost monitoring: " + str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }

def send_alert_email(ses_client, email, subject, body):
    """Send alert email via SES"""
    try:
        ses_client.send_email(
            Source=email,
            Destination={'ToAddresses': [email]},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Text': {'Data': body}}
            }
        )
        print("Alert email sent to " + email)
    except Exception as e:
        print("Failed to send email: " + str(e))

def shutdown_services(lambda_client, cloudfront_client, s3_client, project_tag):
    """Business-friendly cost control - disable only non-critical services"""
    
    try:
        # ONLY disable the contact form Lambda (non-critical for business)
        # Keep the website running but disable contact functionality
        try:
            lambda_client.put_function_concurrency(
                FunctionName='static-site-contact',
                ReservedConcurrencyLimit=0
            )
            print("Disabled contact form Lambda - website still accessible")
        except Exception as e:
            print("Failed to disable contact Lambda: " + str(e))
        
        # Disable OPTIONS Lambda (contact form related)
        try:
            lambda_client.put_function_concurrency(
                FunctionName='static-site-contact-options',
                ReservedConcurrencyLimit=0
            )
            print("Disabled contact OPTIONS Lambda")
        except Exception as e:
            print("Failed to disable OPTIONS Lambda: " + str(e))
        
        # CRITICAL: DO NOT disable CloudFront - keep website running!
        # CRITICAL: DO NOT disable S3 - keep website content accessible!
        # CRITICAL: DO NOT disable API Gateway - just the Lambda functions
        
        print("Business-friendly cost control applied - website remains accessible")
        print("Only contact form disabled to reduce costs")
        
    except Exception as e:
        print("Error during business-friendly shutdown: " + str(e))

EOF
    filename = "cost_monitor.py"
  }
}

# IAM role for cost monitor Lambda
resource "aws_iam_role" "cost_monitor_role" {
  name = "idfs-cost-monitor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for cost monitor Lambda
resource "aws_iam_role_policy" "cost_monitor_policy" {
  name = "idfs-cost-monitor-policy"
  role = aws_iam_role.cost_monitor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetUsageReport"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:PutFunctionConcurrency",
          "lambda:GetFunction",
          "lambda:ListFunctions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:ListDistributions",
          "cloudfront:GetDistributionConfig",
          "cloudfront:UpdateDistribution"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Events rule to trigger cost monitoring daily
resource "aws_cloudwatch_event_rule" "cost_monitor_schedule" {
  name                = "idfs-cost-monitor-schedule"
  description         = "Trigger cost monitoring daily"
  schedule_expression = "rate(1 day)"

  tags = local.common_tags
}

# CloudWatch Events target for cost monitor Lambda
resource "aws_cloudwatch_event_target" "cost_monitor_target" {
  rule      = aws_cloudwatch_event_rule.cost_monitor_schedule.name
  target_id = "CostMonitorTarget"
  arn       = aws_lambda_function.cost_monitor.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch_cost_monitor" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_monitor_schedule.arn
}

# CloudWatch log group for cost monitor Lambda
resource "aws_cloudwatch_log_group" "cost_monitor_lambda" {
  name              = "/aws/lambda/idfs-cost-monitor"
  retention_in_days = 7  # Short retention for cost savings

  tags = local.common_tags
}

# Output cost monitoring information
output "cost_monitoring" {
  description = "Cost monitoring configuration"
  value = {
    cost_monitor_function = aws_lambda_function.cost_monitor.function_name
    alert_threshold       = "10"
    shutdown_threshold    = "20"
    monitoring_schedule    = "Daily"
  }
}
