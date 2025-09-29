# API Gateway HTTP API configuration
# Creates HTTP API with Lambda proxy integration for contact form

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "api" {
  name          = "static-site-api"
  protocol_type = "HTTP"
  description   = "HTTP API for contact form submissions"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type"]
    allow_methods     = ["POST", "OPTIONS"]
    allow_origins     = ["*"]  # Allow all origins for testing
    expose_headers    = []
    max_age           = 86400
  }

  tags = local.common_tags
}

# API Gateway stage
resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = 100
    throttling_burst_limit = 200
  }

  tags = local.common_tags
}

# API Gateway route for contact form
resource "aws_apigatewayv2_route" "contact" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /contact"
  target    = "integrations/${aws_apigatewayv2_integration.contact.id}"
}

# API Gateway route for OPTIONS preflight
resource "aws_apigatewayv2_route" "contact_options" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "OPTIONS /contact"
  target    = "integrations/${aws_apigatewayv2_integration.contact_options.id}"
}

# Lambda integration for contact form
resource "aws_apigatewayv2_integration" "contact" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  integration_method = "POST"
  integration_uri     = aws_lambda_function.contact.invoke_arn
}

# Lambda integration for OPTIONS preflight
resource "aws_apigatewayv2_integration" "contact_options" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  integration_method = "POST"
  integration_uri     = aws_lambda_function.contact_options.invoke_arn
}

# Lambda permission for API Gateway to invoke contact function
resource "aws_lambda_permission" "api_gateway_contact" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Lambda permission for API Gateway to invoke OPTIONS function
resource "aws_lambda_permission" "api_gateway_contact_options" {
  statement_id  = "AllowExecutionFromAPIGatewayOptions"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_options.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
