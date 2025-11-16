output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.http_api.id
}

output "api_endpoint" {
  description = "API Gateway invoke URL"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/chat"
}

output "stage_arn" {
  description = "API Gateway stage ARN"
  value       = aws_apigatewayv2_stage.default.arn
}

output "execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_apigatewayv2_api.http_api.execution_arn
}

