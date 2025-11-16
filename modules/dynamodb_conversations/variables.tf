variable "table_name" {
  description = "Name of the DynamoDB table for conversations"
  type        = string
}

variable "billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "ttl_enabled" {
  description = "Enable TTL for automatic cleanup"
  type        = bool
  default     = true
}

variable "ttl_attribute" {
  description = "TTL attribute name"
  type        = string
  default     = "expires_at"
}

