# Lambda Function Architecture

## Request Flow

```
API Gateway Event
       │
       ↓
┌──────────────────────────────────────────┐
│  handler.py (Orchestrator)               │
│  • lambda_handler(event, context)        │
└──────────────────────────────────────────┘
       │
       ├─→ request_utils.get_client_ip()
       │       └─→ Extract IP from event
       │
       ├─→ rate_limiter.check_rate_limit(ip)
       │       ├─→ DynamoDB atomic update
       │       └─→ Returns (allowed, remaining)
       │
       │   [If rate limited]
       ├─→ responses.rate_limit_response()
       │       └─→ Return 429 with headers
       │
       ├─→ request_utils.parse_request_body()
       │       └─→ Parse JSON body
       │
       ├─→ request_utils.validate_message()
       │       └─→ Validate required fields
       │
       ├─→ bedrock_client.get_ai_response()
       │       ├─→ call_bedrock()
       │       │   ├─→ Format OpenAI request
       │       │   ├─→ Invoke Bedrock model
       │       │   └─→ Parse response
       │       └─→ Handle errors
       │
       └─→ responses.success_response()
               └─→ Return 200 with AI response

```

## Module Dependencies

```
handler.py
  ├── rate_limiter
  │     └── boto3 (DynamoDB)
  ├── bedrock_client
  │     ├── boto3 (Bedrock)
  │     └── responses (for errors)
  ├── request_utils
  │     └── responses (for errors)
  └── responses
        ├── bedrock_client (get_model_id)
        └── rate_limiter (get_rate_limit_config)
```

## Data Flow

### Success Path
```
Request → Extract IP → Check Rate Limit (✓) → Parse Body (✓) 
   → Validate Message (✓) → Call Bedrock (✓) → Format Response 
   → Return 200 OK
```

### Rate Limit Path
```
Request → Extract IP → Check Rate Limit (✗) → Return 429
```

### Validation Error Path
```
Request → Extract IP → Check Rate Limit (✓) → Parse Body (✗) 
   → Return 400
```

### AI Service Error Path
```
Request → Extract IP → Check Rate Limit (✓) → Parse Body (✓) 
   → Validate Message (✓) → Call Bedrock (✗) → Return 500
```

## Error Handling Strategy

Each module handles its own errors and returns tuples of `(result, error)`:

```python
# Success case
result, None

# Error case  
None, error_response_dict
```

This allows the handler to be simple:

```python
result, error = some_function()
if error:
    return error
# Use result...
```

## Environment Variables

Used by modules:

| Variable | Module | Purpose |
|----------|--------|---------|
| `BEDROCK_MODEL_ID` | bedrock_client | Model to invoke |
| `RATELIMIT_TABLE_NAME` | rate_limiter | DynamoDB table |
| `RATE_LIMIT_WINDOW` | rate_limiter | Time window (seconds) |
| `RATE_LIMIT_MAX` | rate_limiter | Max requests per window |

## Testing Strategy

### Unit Tests
Each module can be tested independently:

```python
# test_rate_limiter.py
def test_check_rate_limit_success():
    allowed, remaining = check_rate_limit('test-ip')
    assert allowed is True
    assert remaining >= 0

# test_bedrock_client.py  
def test_get_ai_response():
    response, error = get_ai_response('Hello', None)
    assert error is None
    assert isinstance(response, str)

# test_request_utils.py
def test_parse_valid_json():
    event = {'body': '{"message": "test"}'}
    body, error = parse_request_body(event)
    assert error is None
    assert body['message'] == 'test'
```

### Integration Tests
Test the full handler:

```python
def test_lambda_handler_success():
    event = create_mock_event('Hello')
    response = lambda_handler(event, None)
    assert response['statusCode'] == 200
```

## Extending the Function

### Adding Conversation History

1. Create `conversation_store.py`:
```python
def save_message(user_id, role, message):
    # Save to DynamoDB
    pass

def get_history(user_id, limit=10):
    # Retrieve from DynamoDB
    return messages
```

2. Update `handler.py`:
```python
from conversation_store import save_message, get_history

# In lambda_handler, before calling Bedrock:
history = get_history(client_ip)
response_text, error = get_ai_response(message, system_prompt, history)

# After getting response:
save_message(client_ip, 'user', message)
save_message(client_ip, 'assistant', response_text)
```

3. Update `bedrock_client.py`:
```python
def get_ai_response(message, system_prompt=None, history=None):
    messages = build_messages_with_history(message, system_prompt, history)
    # ... rest of logic
```

### Adding Custom Metrics

1. Create `metrics.py`:
```python
import boto3
cloudwatch = boto3.client('cloudwatch')

def record_response_time(duration_ms):
    cloudwatch.put_metric_data(...)

def record_rate_limit_hit():
    cloudwatch.put_metric_data(...)
```

2. Update `handler.py`:
```python
import time
from metrics import record_response_time, record_rate_limit_hit

start = time.time()
# ... process request
duration = (time.time() - start) * 1000
record_response_time(duration)
```

## Performance Considerations

- **Cold Start**: ~800ms (imports + AWS SDK initialization)
- **Warm Execution**: ~1-3s (mostly Bedrock inference time)
- **Memory Usage**: 512MB is sufficient for this workload
- **Concurrency**: Limited by reserved concurrency setting

## Security Considerations

- Rate limiting prevents abuse
- No sensitive data logged
- IP addresses stored temporarily (TTL cleanup)
- System prompt validated
- All errors sanitized before returning to client

