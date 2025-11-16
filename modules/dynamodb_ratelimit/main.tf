# DynamoDB table for rate limiting
resource "aws_dynamodb_table" "ratelimit" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = "ip"
  range_key    = "minute_bucket"

  # Attributes
  attribute {
    name = "ip"
    type = "S"
  }

  attribute {
    name = "minute_bucket"
    type = "S"
  }

  # Capacity (only used if billing_mode is PROVISIONED)
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # TTL for automatic cleanup
  ttl {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_attribute
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  tags = {
    Name        = var.table_name
    Purpose     = "Rate limiting"
  }
}

