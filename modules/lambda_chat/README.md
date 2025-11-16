# Lambda Function Structure

This Lambda function is modularized for maintainability and testability.

## File Structure

```
modules/lambda_chat/
├── main.tf              # Terraform configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── requirements.txt     # Empty (using Lambda layer for boto3)
├── src/                 # Lambda source code
│   ├── handler.py       # Main Lambda handler (minimal orchestration)
│   ├── rate_limiter.py  # Rate limiting logic with DynamoDB
│   ├── bedrock_client.py # Bedrock AI model interaction
│   ├── request_utils.py # Request parsing and validation
│   ├── responses.py     # Response formatting
│   └── __init__.py      # Package initialization
└── README.md            # This file
```

**Note**: Terraform automatically packages the `src/` directory using the `archive_file` data source. No manual build step required!

## Module Responsibilities

### `handler.py`
- **Purpose**: Minimal orchestration only
- **Functions**: 
  - `lambda_handler(event, context)` - Main entry point
- **Responsibilities**:
  - Extract client IP
  - Check rate limit
  - Parse request
  - Call AI service
  - Return response

### `rate_limiter.py`
- **Purpose**: IP-based rate limiting using DynamoDB
- **Functions**:
  - `check_rate_limit(ip_address)` - Check/update rate limit
  - `get_rate_limit_config()` - Get current config
- **Responsibilities**:
  - Atomic DynamoDB operations
  - Time-bucket calculations
  - TTL management

### `bedrock_client.py`
- **Purpose**: AI model interaction
- **Functions**:
  - `get_ai_response(message, system_prompt)` - High-level API
  - `call_bedrock(message, system_prompt)` - Low-level Bedrock call
  - `get_model_id()` - Get current model ID
- **Responsibilities**:
  - Format requests for OpenAI API
  - Parse AI responses
  - Handle Bedrock errors
  - System prompt management

### `request_utils.py`
- **Purpose**: Request parsing and validation
- **Functions**:
  - `get_client_ip(event)` - Extract IP from event
  - `parse_request_body(event)` - Parse JSON body
  - `validate_message(body)` - Validate message field
- **Responsibilities**:
  - API Gateway event parsing
  - Input validation
  - Error handling for malformed requests

### `responses.py`
- **Purpose**: Response formatting
- **Functions**:
  - `success_response(text, remaining)` - 200 OK response
  - `error_response(code, type, msg)` - Error responses
  - `rate_limit_response()` - 429 rate limit response
- **Responsibilities**:
  - Consistent response format
  - Header management
  - Rate limit headers

## Benefits of This Structure

1. **Testability**: Each module can be unit tested independently
2. **Maintainability**: Changes to one concern don't affect others
3. **Readability**: Handler is minimal and easy to understand
4. **Reusability**: Modules can be reused in other Lambda functions
5. **Separation of Concerns**: Each file has a single responsibility

## Testing

```python
# Test rate limiter independently
from rate_limiter import check_rate_limit
allowed, remaining = check_rate_limit('192.168.1.1')

# Test bedrock client independently
from bedrock_client import get_ai_response
response, error = get_ai_response('Hello', None)

# Test request parsing independently
from request_utils import parse_request_body
body, error = parse_request_body(mock_event)
```

## Adding New Features

### Example: Add conversation history

1. Create `conversation_history.py`:
```python
def store_conversation(user_id, message, response):
    # Store in DynamoDB
    pass

def get_conversation_history(user_id, limit=10):
    # Retrieve from DynamoDB
    pass
```

2. Update `handler.py`:
```python
from conversation_history import store_conversation

# After getting AI response
store_conversation(client_ip, message, response_text)
```

3. No changes needed to other modules!

## Local Development

```bash
# Terraform handles packaging automatically
# To manually test the code:
cd modules/lambda_chat/src
python -m pytest tests/  # if tests are added

# To manually create package (for testing):
cd modules/lambda_chat/src
zip -r ../lambda_package.zip .
```

