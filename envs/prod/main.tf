variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "mta-chat"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bedrock_model_id" {
  description = "Bedrock model ID"
  type        = string
}

variable "rate_limit_window" {
  description = "Rate limit window in seconds"
  type        = number
}

variable "rate_limit_max" {
  description = "Maximum requests per IP per window"
  type        = number
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit"
  type        = number
}

variable "lambda_reserved_concurrency" {
  description = "Lambda reserved concurrent executions"
  type        = number
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
}

variable "cors_allow_origins" {
  description = "CORS allowed origins"
  type        = list(string)
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
}

variable "alarm_4xx_threshold" {
  description = "4xx error alarm threshold"
  type        = number
}

variable "alarm_5xx_threshold" {
  description = "5xx error alarm threshold"
  type        = number
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
}

# DynamoDB rate limit table
module "dynamodb_ratelimit" {
  source = "../../modules/dynamodb_ratelimit"
  
  table_name   = "${var.project_name}-ratelimit-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  ttl_enabled  = true
  ttl_attribute = "expires_at"
}

# DynamoDB conversations table
module "dynamodb_conversations" {
  source = "../../modules/dynamodb_conversations"
  
  table_name   = "${var.project_name}-conversations-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  ttl_enabled  = true
  ttl_attribute = "expires_at"
}

# IAM roles and policies
module "iam" {
  source = "../../modules/iam"
  
  project_name            = var.project_name
  environment             = var.environment
  ratelimit_table_arn     = module.dynamodb_ratelimit.table_arn
  conversations_table_arn = module.dynamodb_conversations.table_arn
  bedrock_model_id        = var.bedrock_model_id
}

# Lambda chat function
module "lambda_chat" {
  source = "../../modules/lambda_chat"
  
  function_name           = "${var.project_name}-chat-${var.environment}"
  execution_role_arn      = module.iam.lambda_execution_role_arn
  bedrock_model_id        = var.bedrock_model_id
  ratelimit_table_name    = module.dynamodb_ratelimit.table_name
  conversations_table_name = module.dynamodb_conversations.table_name
  rate_limit_window       = var.rate_limit_window
  rate_limit_max          = var.rate_limit_max
  reserved_concurrency    = var.lambda_reserved_concurrency
  memory_size             = var.lambda_memory_size
  timeout                 = var.lambda_timeout
}

# API Gateway HTTP
module "apigw_http_public" {
  source = "../../modules/apigw_http_public"
  
  api_name              = "${var.project_name}-api-${var.environment}"
  stage_name            = var.environment
  lambda_function_arn   = module.lambda_chat.function_arn
  lambda_function_name  = module.lambda_chat.function_name
  cors_allow_origins    = var.cors_allow_origins
  throttle_burst_limit  = var.api_throttle_burst_limit
  throttle_rate_limit   = var.api_throttle_rate_limit
  enable_access_logs    = true
  log_retention_days    = var.log_retention_days
}

# Observability
module "observability" {
  source = "../../modules/observability"
  
  project_name          = var.project_name
  environment           = var.environment
  lambda_function_name  = module.lambda_chat.function_name
  api_id                = module.apigw_http_public.api_id
  api_stage             = var.environment
  log_retention_days    = var.log_retention_days
  alarm_4xx_threshold   = var.alarm_4xx_threshold
  alarm_5xx_threshold   = var.alarm_5xx_threshold
  alarm_sns_topic_arn   = var.alarm_sns_topic_arn
}

# Outputs
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.apigw_http_public.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda_chat.function_name
}

output "ratelimit_table_name" {
  description = "DynamoDB rate limit table name"
  value       = module.dynamodb_ratelimit.table_name
}

