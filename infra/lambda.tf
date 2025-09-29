# Lambda function configuration
# Creates Lambda functions for contact form processing and OPTIONS handling

# Archive file for contact Lambda function
data "archive_file" "contact_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/contact"
  output_path = "${path.module}/contact_lambda.zip"
}

# Archive file for OPTIONS Lambda function
data "archive_file" "contact_options_lambda" {
  type        = "zip"
  source_file = "${path.module}/contact_options.py"
  output_path = "${path.module}/contact_options_lambda.zip"
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "static-site-lambda-role"

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

# IAM policy for Lambda functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "static-site-lambda-policy"
  role = aws_iam_role.lambda_role.id

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
          "ses:SendEmail"
        ]
        Resource = "*"  # Allow sending to any verified email for testing
      }
    ]
  })
}

# CloudWatch log group for contact Lambda function
resource "aws_cloudwatch_log_group" "contact_lambda" {
  name              = "/aws/lambda/static-site-contact"
  retention_in_days = 14

  tags = local.common_tags
}

# CloudWatch log group for OPTIONS Lambda function
resource "aws_cloudwatch_log_group" "contact_options_lambda" {
  name              = "/aws/lambda/static-site-contact-options"
  retention_in_days = 14

  tags = local.common_tags
}

# Lambda function for contact form processing
resource "aws_lambda_function" "contact" {
  filename         = data.archive_file.contact_lambda.output_path
  function_name    = "static-site-contact"
  role            = aws_iam_role.lambda_role.arn
  handler         = "handler.lambda_handler"
  source_code_hash = data.archive_file.contact_lambda.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 128  # Reduced memory for cost optimization

  environment {
    variables = local.lambda_env_vars
  }

  depends_on = [
    aws_cloudwatch_log_group.contact_lambda,
    aws_iam_role_policy.lambda_policy
  ]

  tags = local.common_tags
}

# Lambda function for OPTIONS preflight requests
resource "aws_lambda_function" "contact_options" {
  filename         = data.archive_file.contact_options_lambda.output_path
  function_name    = "static-site-contact-options"
  role            = aws_iam_role.lambda_role.arn
  handler         = "contact_options.lambda_handler"
  source_code_hash = data.archive_file.contact_options_lambda.output_base64sha256
  runtime         = "python3.11"
  timeout         = 5

  depends_on = [
    aws_cloudwatch_log_group.contact_options_lambda,
    aws_iam_role_policy.lambda_policy
  ]

  tags = local.common_tags
}
