variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ratelimit_table_arn" {
  description = "ARN of the DynamoDB rate limit table"
  type        = string
}

variable "conversations_table_arn" {
  description = "ARN of the DynamoDB conversations table"
  type        = string
}

variable "bedrock_model_id" {
  description = "Bedrock model ID to allow access to"
  type        = string
}

