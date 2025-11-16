output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.ratelimit.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.ratelimit.arn
}

output "table_id" {
  description = "DynamoDB table ID"
  value       = aws_dynamodb_table.ratelimit.id
}

