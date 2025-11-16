# Testing Guide

Guide for testing the MTA chat backend API using Postman or curl.

## Import Postman Collection

1. Open Postman
2. Click **Import** button
3. Select `postman_collection.json` from this repository
4. Update the collection variables:
   - `dev_api_endpoint`: Your dev API endpoint from `terraform output api_endpoint`
   - `prod_api_endpoint`: Your prod API endpoint (when deployed)

## Test Scenarios

### 1. Basic Chat Request

**Request:**
```bash
curl -X POST https://YOUR-API-URL/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What aesthetic services do you offer?"
  }'
```

**Expected Response (200 OK):**
```json
{
  "response": "At Medical Tech Aesthetic, we offer...",
  "model": "openai.gpt-oss-120b-1:0"
}
```

**Check response headers:**
- `X-RateLimit-Limit`: 10 (or your configured limit)
- `X-RateLimit-Remaining`: 9 (decrements with each request)
- `X-RateLimit-Window`: 60

---

### 2. Rate Limiting Test

Run this script to trigger rate limiting:

```bash
# Send 12 requests rapidly (limit is 10/minute)
API_URL="https://YOUR-API-URL/chat"

for i in {1..12}; do
  echo "=== Request $i ==="
  curl -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"message":"test"}' \
    -i -s | grep -E "(HTTP|X-RateLimit|error)" | head -5
  echo ""
  sleep 0.5
done
```

**Expected Results:**
- Requests 1-10: `200 OK` with decreasing `X-RateLimit-Remaining`
- Requests 11-12: `429 Too Many Requests`

**429 Response:**
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Maximum 10 requests per 60 seconds.",
  "retry_after": 60
}
```

---

### 3. Custom System Prompt

**Request:**
```bash
curl -X POST https://YOUR-API-URL/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Tell me about botox",
    "system_prompt": "You are a medical aesthetics expert. Be concise and professional."
  }'
```

**Use Case:** Override the default system prompt for specific conversation contexts.

---

### 4. Error Handling Tests

#### Missing Message Field
```bash
curl -X POST https://YOUR-API-URL/chat \
  -H "Content-Type: application/json" \
  -d '{"foo":"bar"}'
```

**Expected (400 Bad Request):**
```json
{
  "error": "Missing message",
  "message": "Request must include a \"message\" field"
}
```

#### Empty Message
```bash
curl -X POST https://YOUR-API-URL/chat \
  -H "Content-Type: application/json" \
  -d '{"message":""}'
```

**Expected (400 Bad Request):**
```json
{
  "error": "Missing message",
  "message": "Request must include a \"message\" field"
}
```

#### Malformed JSON
```bash
curl -X POST https://YOUR-API-URL/chat \
  -H "Content-Type: application/json" \
  -d '{invalid json'
```

**Expected (400 Bad Request):**
```json
{
  "error": "Invalid JSON",
  "message": "Request body must be valid JSON"
}
```

---

### 5. CORS Preflight (Browser)

**Preflight Request:**
```bash
curl -X OPTIONS https://YOUR-API-URL/chat \
  -H "Origin: https://medical-tech-aesthetic.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -i
```

**Expected Headers:**
- `Access-Control-Allow-Origin`: * (dev) or https://medical-tech-aesthetic.com (prod)
- `Access-Control-Allow-Methods`: POST, OPTIONS
- `Access-Control-Allow-Headers`: content-type, x-request-id

---

## Performance Testing

### Measure Response Time

```bash
curl -X POST https://YOUR-API-URL/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello"}' \
  -w "\nTotal time: %{time_total}s\n" \
  -o /dev/null -s
```

**Expected Times:**
- Cold start: 3-8 seconds (first request after idle)
- Warm: 1-3 seconds (Bedrock inference time)

### Warm Up Lambda

```bash
# Use the diagnostic script
./scripts/diag.sh warmup dev
```

---

## Load Testing (Optional)

Use Apache Bench or similar tools for load testing:

```bash
# 100 requests, 10 concurrent
ab -n 100 -c 10 -T 'application/json' \
  -p test_payload.json \
  https://YOUR-API-URL/chat
```

**test_payload.json:**
```json
{"message":"test"}
```

**Watch for:**
- Throttling at API Gateway level (burst limit)
- Lambda concurrent execution limits
- DynamoDB throttling (unlikely with PAY_PER_REQUEST)

---

## Monitoring During Tests

### Watch Logs in Real-Time

```bash
./scripts/diag.sh logs dev
```

### Check CloudWatch Metrics

1. Go to AWS Console → CloudWatch → Dashboards
2. Open `mta-chat-dev` dashboard
3. Watch metrics during testing:
   - API Gateway: Count, 4XX, 5XX
   - Lambda: Invocations, Duration, Errors
   - Rate Limit Hits (custom metric)

### Query DynamoDB Rate Limit Table

```bash
aws dynamodb scan \
  --table-name mta-chat-ratelimit-dev \
  --max-items 10

# Or get specific IP
aws dynamodb query \
  --table-name mta-chat-ratelimit-dev \
  --key-condition-expression "ip = :ip" \
  --expression-attribute-values '{":ip":{"S":"YOUR_IP"}}'
```

---

## Troubleshooting

### API Returns 403 Forbidden
- Check API Gateway stage configuration
- Verify Lambda has correct permissions
- Check CloudWatch logs for detailed error

### API Returns 500 Internal Server Error
- Check Lambda logs: `./scripts/diag.sh logs dev`
- Verify Bedrock model access is enabled
- Check IAM permissions for Lambda role

### Rate Limiting Not Working
- Verify DynamoDB table exists and is accessible
- Check Lambda has DynamoDB permissions
- Look for errors in CloudWatch logs

### Slow Responses (>5 seconds)
- Lambda cold start (first request after idle period)
- Bedrock model inference time
- Check Lambda memory allocation (increase if needed)

---

## Postman Test Scripts

Add these to your Postman tests for automated validation:

### Basic Success Test
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has required fields", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('response');
    pm.expect(jsonData).to.have.property('model');
});

pm.test("Rate limit headers present", function () {
    pm.response.to.have.header("X-RateLimit-Limit");
    pm.response.to.have.header("X-RateLimit-Remaining");
    pm.response.to.have.header("X-RateLimit-Window");
});
```

### Rate Limit Test
```javascript
pm.test("Rate limit triggered", function () {
    pm.response.to.have.status(429);
});

pm.test("Rate limit error message", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.error).to.eql("Rate limit exceeded");
    pm.expect(jsonData).to.have.property('retry_after');
});
```

---

## Security Testing

### Test IP-based Rate Limiting from Different IPs

Use a VPN or different network to verify rate limits are per-IP:

1. Send 10 requests from IP A → Should work
2. Send 1 more from IP A → Should be rate limited
3. Send request from IP B → Should work (different IP, different limit)

### Test Injection Attacks

The Lambda function should safely handle:

```bash
# SQL-like injection attempt
curl -X POST https://YOUR-API-URL/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"test; DROP TABLE users--"}'
```

Should return a normal response (no injection possible, Bedrock handles safely).

---

## Next Steps

After successful testing:

1. ✅ Verify all test scenarios pass
2. ✅ Confirm rate limiting works as expected
3. ✅ Check CloudWatch dashboard shows correct metrics
4. ✅ Document any custom test cases for your use case
5. ✅ Set up automated tests if desired (e.g., Postman Monitor)
6. ✅ Deploy to production and retest with prod endpoint

---

**Quick Reference:**

Get API endpoint:
```bash
./scripts/diag.sh url dev
```

Quick test:
```bash
./scripts/diag.sh test dev
```

Watch logs:
```bash
./scripts/diag.sh logs dev
```

