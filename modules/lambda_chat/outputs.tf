output "function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.chat.arn
}

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.chat.function_name
}

output "function_invoke_arn" {
  description = "Lambda function invoke ARN"
  value       = aws_lambda_function.chat.invoke_arn
}

