#!/bin/bash
#
# Diagnostic and utility script for the chat backend
#
# Usage:
#   ./scripts/diag.sh logs [ENV]          # Tail Lambda logs
#   ./scripts/diag.sh url [ENV]           # Get API endpoint URL
#   ./scripts/diag.sh test [ENV]          # Test the API endpoint
#   ./scripts/diag.sh warmup [ENV]        # Warm up Lambda function
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ENV="${2:-dev}"
COMMAND="${1:-help}"

# Get outputs from Terraform
get_output() {
  local key=$1
  cd "$PROJECT_ROOT/envs/$ENV"
  terraform output -raw "$key" 2>/dev/null || echo ""
}

# Tail Lambda logs
tail_logs() {
  local function_name=$(get_output "lambda_function_name")
  
  if [ -z "$function_name" ]; then
    echo "Error: Could not find Lambda function name"
    echo "Have you run 'terraform apply' yet?"
    exit 1
  fi
  
  echo "==> Tailing logs for $function_name..."
  aws logs tail "/aws/lambda/$function_name" --follow --format short
}

# Get API endpoint URL
get_url() {
  local endpoint=$(get_output "api_endpoint")
  
  if [ -z "$endpoint" ]; then
    echo "Error: Could not find API endpoint"
    echo "Have you run 'terraform apply' yet?"
    exit 1
  fi
  
  echo "$endpoint"
}

# Test API endpoint
test_api() {
  local endpoint=$(get_url)
  
  echo "==> Testing API endpoint: $endpoint"
  echo ""
  
  # Test request
  echo "Sending test message..."
  response=$(curl -s -X POST "$endpoint" \
    -H "Content-Type: application/json" \
    -d '{
      "message": "Hello! Tell me about your aesthetic services."
    }')
  
  echo ""
  echo "Response:"
  echo "$response" | jq . || echo "$response"
}

# Warm up Lambda function
warmup() {
  echo "==> Warming up Lambda function..."
  test_api
  echo ""
  echo "==> Lambda function is now warm"
}

# Show help
show_help() {
  echo "Diagnostic and utility script for MTA chat backend"
  echo ""
  echo "Usage:"
  echo "  $0 logs [ENV]       Tail Lambda logs (default: dev)"
  echo "  $0 url [ENV]        Get API endpoint URL"
  echo "  $0 test [ENV]       Test the API endpoint"
  echo "  $0 warmup [ENV]     Warm up Lambda function"
  echo ""
  echo "Examples:"
  echo "  $0 logs dev         # Tail dev environment logs"
  echo "  $0 url prod         # Get prod API URL"
  echo "  $0 test dev         # Test dev endpoint"
}

# Main
case "$COMMAND" in
  logs)
    tail_logs
    ;;
  url)
    get_url
    ;;
  test)
    test_api
    ;;
  warmup)
    warmup
    ;;
  help|*)
    show_help
    ;;
esac

