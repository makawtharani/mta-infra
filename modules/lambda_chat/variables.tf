variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
  type        = string
}

variable "bedrock_model_id" {
  description = "Bedrock model ID to use for chat"
  type        = string
}

variable "ratelimit_table_name" {
  description = "DynamoDB table name for rate limiting"
  type        = string
}

variable "conversations_table_name" {
  description = "DynamoDB table name for conversation history"
  type        = string
  default     = ""
}

variable "rate_limit_window" {
  description = "Rate limit window in seconds"
  type        = number
  default     = 60
}

variable "rate_limit_max" {
  description = "Maximum requests per IP per window"
  type        = number
  default     = 10
}

variable "reserved_concurrency" {
  description = "Reserved concurrent executions for the function"
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Memory size in MB"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 30
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

