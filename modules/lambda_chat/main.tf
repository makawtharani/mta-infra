# CloudWatch log group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 7
}

# Create deployment package from src directory
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_package.zip"
}

# Lambda function
resource "aws_lambda_function" "chat" {
  filename         = data.archive_file.lambda_package.output_path
  function_name    = var.function_name
  role             = var.execution_role_arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  runtime          = var.runtime
  memory_size      = var.memory_size
  timeout          = var.timeout
  
  reserved_concurrent_executions = var.reserved_concurrency

  # Use Klayers for boto3 (latest version)
  layers = [
    "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p312-boto3:23"
  ]

  environment {
    variables = {
      BEDROCK_MODEL_ID        = var.bedrock_model_id
      RATELIMIT_TABLE_NAME    = var.ratelimit_table_name
      CONVERSATIONS_TABLE_NAME = var.conversations_table_name
      RATE_LIMIT_WINDOW       = tostring(var.rate_limit_window)
      RATE_LIMIT_MAX          = tostring(var.rate_limit_max)
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

