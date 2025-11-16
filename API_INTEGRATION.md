# MTA Chat API - Frontend Integration

## Endpoint
```
POST https://h7ngqrb274.execute-api.us-east-1.amazonaws.com/dev/chat
```

---

## Request

### Basic
```json
{
  "message": "User's question"
}
```

### With Conversation Memory
```json
{
  "message": "User's question",
  "session_id": "unique-user-id",
  "conversation_history": [
    {"role": "user", "content": "Previous question"},
    {"role": "assistant", "content": "Previous answer"}
  ]
}
```

**Notes:**
- `session_id` - Optional. Defaults to IP address if not provided
- `conversation_history` - Optional. Include last 5 messages for context
- Backend automatically stores conversations when `session_id` is provided

---

## Response

### Success (200)
```json
{
  "response": "AI assistant's reply",
  "model": "openai.gpt-oss-120b-1:0"
}
```

**Headers:**
- `X-RateLimit-Limit: 10`
- `X-RateLimit-Remaining: 9`
- `X-RateLimit-Window: 60`

### Rate Limited (429)
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Maximum 10 requests per 60 seconds.",
  "retry_after": 60
}
```

### Error (400/500)
```json
{
  "error": "Error type",
  "message": "Error description"
}
```

---

## Implementation

### JavaScript
```javascript
async function sendMessage(message, sessionId) {
  const response = await fetch('https://h7ngqrb274.execute-api.us-east-1.amazonaws.com/dev/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message, session_id: sessionId })
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }

  return await response.json();
}

// Usage
const result = await sendMessage('What devices do you offer?', 'user-123');
console.log(result.response);
```

### React Hook (with Memory)
```javascript
import { useState, useEffect } from 'react';

function useChatAPI() {
  const [history, setHistory] = useState([]);
  const [sessionId, setSessionId] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setSessionId(`session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`);
  }, []);

  const sendMessage = async (message) => {
    setLoading(true);
    
    try {
      const response = await fetch('https://h7ngqrb274.execute-api.us-east-1.amazonaws.com/dev/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message,
          session_id: sessionId,
          conversation_history: history.slice(-5)
        })
      });

      const data = await response.json();
      
      if (!response.ok) throw new Error(data.message);

      setHistory(prev => [
        ...prev,
        { role: 'user', content: message },
        { role: 'assistant', content: data.response }
      ]);

      return data.response;
    } finally {
      setLoading(false);
    }
  };

  return { sendMessage, history, loading };
}
```

---

## Rate Limiting

- **10 requests per minute** per IP
- Check `X-RateLimit-Remaining` header
- Handle 429 responses gracefully

```javascript
const remaining = response.headers.get('X-RateLimit-Remaining');
if (remaining <= 2) {
  // Warn user or disable send button
}
```

---

## CORS

✅ Enabled for all origins in dev  
🔒 Production: `https://medical-tech-aesthetic.com` only

---

## Important Notes

1. **Language**: AI responds in same language as user (Arabic/English)
2. **Response Time**: 1-3 seconds
3. **Session ID**: Use user ID if available, otherwise generate random ID
4. **Memory**: Last 5 messages provide conversation context
5. **Storage**: Conversations auto-delete after 30 days

---

## Quick Test

```bash
curl -X POST https://h7ngqrb274.execute-api.us-east-1.amazonaws.com/dev/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What devices do you offer?"}'
```

---

## Error Handling

```javascript
try {
  const result = await sendMessage(userMessage, sessionId);
  // Handle success
} catch (error) {
  if (error.message.includes('Rate limit')) {
    // Show rate limit message
  } else if (error.message.includes('Network')) {
    // Show connection error
  } else {
    // Show generic error
  }
}
```

---

**Questions?** Check CloudWatch logs or contact backend team.
