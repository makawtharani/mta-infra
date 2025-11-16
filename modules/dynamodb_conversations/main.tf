# DynamoDB table for conversation history
resource "aws_dynamodb_table" "conversations" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = "session_id"
  range_key    = "timestamp"

  # Attributes
  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  # TTL for automatic cleanup (30 days)
  ttl {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_attribute
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = false
  }

  tags = {
    Name    = var.table_name
    Purpose = "Conversation history"
  }
}

