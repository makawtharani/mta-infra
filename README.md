# MTA Chat Backend Infrastructure

Production-ready Terraform infrastructure for an AI-powered chatbot backend using AWS Lambda, API Gateway, and Amazon Bedrock. Designed for **public access without authentication** with robust rate limiting to prevent abuse.

## 🏗️ Architecture

```
┌─────────────┐
│  Web Widget │
└──────┬──────┘
       │ HTTPS POST /chat
       ↓
┌─────────────────────────────────┐
│  API Gateway HTTP API           │
│  • CORS enabled                 │
│  • Stage throttling (burst/rate)│
└──────┬──────────────────────────┘
       │
       ↓
┌─────────────────────────────────┐
│  Lambda Function (Python)       │
│  1. Per-IP rate limit check     │
│  2. Call Bedrock Claude model   │
│  3. Return response              │
└──────┬──────────────────────────┘
       │
       ├─────→ DynamoDB (rate limit table)
       │       • PK: ip, SK: minute_bucket
       │       • TTL: auto-cleanup
       │
       └─────→ Amazon Bedrock
               • OpenAI GPT-OSS-120B
```

## 🔒 Rate Limiting Strategy

Two-layer defense against abuse:

### Layer 1: API Gateway Stage Throttling (coarse)
- **Burst limit**: 5 requests (dev), 10 (prod)
- **Rate limit**: 1 req/s (dev), 2 req/s (prod)
- Applied at the API Gateway level before Lambda invocation
- Cost-effective first line of defense

### Layer 2: Lambda + DynamoDB (fine-grained)
- **Per-IP rate limit**: 10 requests/min (dev), 15 requests/min (prod)
- DynamoDB conditional writes for atomic counting
- Minute-bucket time windows for precise control
- Automatic cleanup via TTL (expires after 5 minutes)

**Rate limit response**:
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Maximum 10 requests per 60 seconds.",
  "retry_after": 60
}
```

Headers returned on all responses:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Requests remaining in current window
- `X-RateLimit-Window`: Time window in seconds

## 📁 Project Structure

```
mta-infra/
├── envs/                       # Environment-specific configs
│   ├── dev/
│   │   ├── backend.tf         # S3 + DynamoDB state backend
│   │   ├── main.tf            # Module composition
│   │   └── terraform.tfvars   # Dev values
│   └── prod/
│       ├── backend.tf
│       ├── main.tf
│       └── terraform.tfvars
│
├── modules/                    # Reusable Terraform modules
│   ├── apigw_http_public/     # HTTP API Gateway
│   ├── lambda_chat/           # Chat Lambda function (modular Python code)
│   │   ├── handler.py         # Main Lambda handler (minimal)
│   │   ├── rate_limiter.py    # Rate limiting logic
│   │   ├── bedrock_client.py  # AI model interaction
│   │   ├── request_utils.py   # Request parsing/validation
│   │   ├── responses.py       # Response formatting
│   │   └── README.md          # Lambda architecture docs
│   ├── dynamodb_ratelimit/    # Rate limit table
│   ├── iam/                   # IAM roles & policies
│   └── observability/         # CloudWatch logs & alarms
│
├── policies/                   # IAM policy documents
│   ├── lambda_bedrock.json
│   └── lambda_dynamodb_rw.json
│
├── scripts/                    # Helper scripts
│   ├── build_lambda.sh        # (Deprecated - Terraform handles packaging)
│   └── diag.sh                # Diagnostics & testing
│
└── README.md
```

## 🚀 Getting Started

### Prerequisites

1. **AWS Account** with:
   - Bedrock access (OpenAI GPT-OSS-120B model enabled)
   - Appropriate IAM permissions for creating resources
   
2. **Tools installed**:
   - [Terraform](https://www.terraform.io/downloads) >= 1.5.0
   - [AWS CLI](https://aws.amazon.com/cli/) configured
   - Python 3.12+ (for Lambda function)
   - `jq` (for diagnostic scripts)

3. **S3 Backend** (for Terraform state):
   ```bash
   # Create S3 bucket for state
   aws s3 mb s3://mta-terraform-state-dev --region us-east-1
   
   # Enable versioning
   aws s3api put-bucket-versioning \
     --bucket mta-terraform-state-dev \
     --versioning-configuration Status=Enabled
   
   # Create DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name mta-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

### Initial Setup

1. **Clone and configure**:
   ```bash
   cd mta-infra
   
   # Update backend.tf files with your bucket names
   # Edit envs/dev/backend.tf and envs/prod/backend.tf
   ```

2. **Initialize Terraform** (dev environment):
   ```bash
   cd envs/dev
   terraform init
   ```

4. **Plan and apply**:
   ```bash
   terraform plan
   terraform apply
   ```

5. **Get your API endpoint**:
   ```bash
   terraform output api_endpoint
   # or
   cd ../.. && ./scripts/diag.sh url dev
   ```

## 🧪 Testing

### Using the diagnostic script

```bash
# Get API URL
./scripts/diag.sh url dev

# Test the endpoint
./scripts/diag.sh test dev

# Watch logs in real-time
./scripts/diag.sh logs dev

# Warm up the Lambda function (reduce cold start)
./scripts/diag.sh warmup dev
```

### Manual testing with curl

```bash
curl -X POST https://your-api-id.execute-api.us-east-1.amazonaws.com/dev/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What aesthetic services do you offer?"
  }'
```

**Expected response**:
```json
{
  "response": "At Medical Tech Aesthetic...",
  "model": "anthropic.claude-3-5-sonnet-20241022-v2:0"
}
```

### Test rate limiting

```bash
# Hit the endpoint repeatedly to trigger rate limit
for i in {1..12}; do
  echo "Request $i:"
  curl -X POST https://your-api-url/chat \
    -H "Content-Type: application/json" \
    -d '{"message":"test"}' \
    -i | grep -E "(HTTP|X-RateLimit|error)"
  echo ""
done
```

## 📊 Monitoring & Observability

### CloudWatch Dashboard

A dashboard is automatically created with:
- API Gateway request count, 4xx, 5xx errors
- Lambda invocations, errors, throttles, duration
- Rate limit hit metrics

Access: AWS Console → CloudWatch → Dashboards → `mta-chat-{env}`

### Alarms

Five CloudWatch alarms are configured:
1. **High rate limit hits** (> 50 in 5 min)
2. **Lambda errors** (> 5 in 5 min)
3. **Lambda throttles** (> 5 in 5 min)
4. **API 4xx errors** (> 10 in 5 min)
5. **API 5xx errors** (> 5 in 5 min)

To enable notifications:
1. Create an SNS topic
2. Add email subscriptions
3. Update `alarm_sns_topic_arn` in `terraform.tfvars`
4. Run `terraform apply`

### Viewing Logs

```bash
# Tail Lambda logs
aws logs tail /aws/lambda/mta-chat-chat-dev --follow

# Or use the script
./scripts/diag.sh logs dev

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/mta-chat-chat-dev \
  --filter-pattern "ERROR"
```

## 💰 Cost Optimization

This infrastructure is designed to be **cost-effective** for moderate traffic:

### Estimated costs (dev, ~1000 requests/day):

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| API Gateway | 30K requests | $0.03 |
| Lambda | 30K invocations, 512 MB, 2s avg | $0.60 |
| DynamoDB | PAY_PER_REQUEST, ~60K writes | $0.75 |
| Bedrock | 30K requests, ~500 tokens each | **$45-90** |
| CloudWatch | Logs & alarms | $1.50 |
| **Total** | | **~$48-93/month** |

> **Note**: Bedrock is the primary cost driver. Monitor usage and adjust rate limits accordingly.

### Cost-saving tips:
- Use reserved Lambda concurrency to cap max cost
- Enable CloudWatch log export to S3 for long-term retention (cheaper)
- Consider provisioned DynamoDB capacity if traffic is predictable
- Set up billing alarms

## 🏗️ Lambda Architecture

The Lambda function uses a **modular architecture** for maintainability and testability:

```
handler.py (orchestrator)
  ├── rate_limiter.py      # DynamoDB rate limiting
  ├── bedrock_client.py    # AI model interaction
  ├── request_utils.py     # Request parsing/validation
  └── responses.py         # Response formatting
```

**Benefits**:
- 🧪 Each module is independently testable
- 📖 Clear separation of concerns
- 🔧 Easy to maintain and extend
- ♻️ Reusable components

See [Lambda Architecture Docs](modules/lambda_chat/README.md) for details.

## 🔐 Security Considerations

### No Authentication Trade-offs

This setup prioritizes **ease of access for leads** over strict security:

✅ **Good for**:
- Lead generation
- Public-facing sales chatbot
- Low-sensitivity information sharing

⚠️ **Not suitable for**:
- Handling PII or medical records
- Personalized user sessions
- Compliance-heavy industries (HIPAA, etc.)

### Security measures in place:
- ✅ Rate limiting (API Gateway + DynamoDB)
- ✅ Reserved Lambda concurrency (DoS protection)
- ✅ CORS restrictions (production)
- ✅ CloudWatch monitoring & alarms
- ✅ Encrypted state in S3
- ✅ Least-privilege IAM roles

### Optional security enhancements:
- Add WAF rules for additional protection
- Implement CAPTCHA on the frontend
- Add API key authentication (simple but better than nothing)
- Use AWS Shield for DDoS protection

## 🚀 CI/CD Pipeline

GitHub Actions workflows automate Terraform deployments:

### Workflows

1. **`terraform-dev.yml`** - Auto-deploy to dev on push to main
   - Triggers on changes to `modules/`, `envs/dev/`, or `policies/`
   - Runs: `init` → `validate` → `plan` → `apply`
   - Perfect for rapid iteration

2. **`terraform-prod.yml`** - Manual production deployment
   - Triggered via GitHub Actions UI
   - Choose between `plan` (preview) or `apply` (deploy)
   - Requires manual approval via GitHub Environment protection

3. **`terraform-pr.yml`** - Validation on pull requests
   - Runs format check, validate, and plan
   - Comments plan output on PR
   - Validates both dev and prod configs

### Setup Required Secrets

Add these secrets in GitHub: Settings → Secrets and variables → Actions

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

### Setup GitHub Environments

1. Go to Settings → Environments
2. Create environments: `dev` and `production`
3. For `production`, add protection rules:
   - ✅ Required reviewers (add yourself)
   - ✅ Wait timer (optional)

### Usage

**Auto-deploy to dev:**
```bash
git push origin main
# GitHub Actions automatically deploys to dev
```

**Deploy to production:**
1. Go to Actions tab in GitHub
2. Select "Terraform Prod Deploy"
3. Click "Run workflow"
4. Choose action: `plan` (to preview) or `apply` (to deploy)
5. Approve the deployment if required reviewers are set

## 🚢 Deployment to Production

1. **Create production backend**:
   ```bash
   aws s3 mb s3://mta-terraform-state-prod --region us-east-1
   aws s3api put-bucket-versioning \
     --bucket mta-terraform-state-prod \
     --versioning-configuration Status=Enabled
   ```

2. **Update `envs/prod/terraform.tfvars`**:
   - Set `cors_allow_origins` to `["https://medical-tech-aesthetic.com"]`
   - Increase rate limits for production traffic
   - Configure SNS topic for alarms
   - Increase Lambda memory/concurrency

3. **Deploy via GitHub Actions** (preferred):
   - Push to main (triggers dev deploy)
   - Manually trigger prod workflow for production

4. **Or deploy manually**:
   ```bash
   cd envs/prod
   terraform init
   terraform plan
   terraform apply
   ```

5. **Update your website** with the new API endpoint

6. **Monitor** CloudWatch dashboard and alarms

## 🧹 Cleanup

To destroy the infrastructure:

```bash
cd envs/dev  # or prod
terraform destroy
```

**Note**: This will not delete:
- S3 state bucket (intentional safety)
- CloudWatch log groups (may have retention)

## 📝 API Reference

### POST /chat

**Request**:
```json
{
  "message": "Your question here",
  "system_prompt": "Optional: override default system prompt"
}
```

**Response** (200 OK):
```json
{
  "response": "AI assistant response",
  "model": "openai.gpt-oss-120b-1:0"
}
```

**Rate limited** (429 Too Many Requests):
```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Maximum 10 requests per 60 seconds.",
  "retry_after": 60
}
```

**Bad request** (400):
```json
{
  "error": "Missing message",
  "message": "Request must include a \"message\" field"
}
```

**Server error** (500):
```json
{
  "error": "Internal server error",
  "message": "An unexpected error occurred"
}
```

## 🤝 Contributing

### Making changes:

1. Edit Terraform modules or Lambda code
2. Rebuild Lambda package if needed: `./scripts/build_lambda.sh`
3. Test in dev: `cd envs/dev && terraform plan && terraform apply`
4. Verify: `../../scripts/diag.sh test dev`
5. Deploy to prod when ready

### Adding a new environment:

1. Copy `envs/dev` to `envs/{new-env}`
2. Update `backend.tf` and `terraform.tfvars`
3. Run `terraform init && terraform apply`

## 📚 Additional Resources

- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [API Gateway HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [DynamoDB On-Demand Pricing](https://aws.amazon.com/dynamodb/pricing/on-demand/)

## 🐛 Troubleshooting

### Lambda function not found
```bash
# Rebuild and redeploy
./scripts/build_lambda.sh
cd envs/dev
terraform apply
```

### Rate limit not working
```bash
# Check DynamoDB table
aws dynamodb scan --table-name mta-chat-ratelimit-dev --max-items 10

# Check Lambda logs
./scripts/diag.sh logs dev
```

### CORS errors in browser
- Update `cors_allow_origins` in `terraform.tfvars`
- Ensure your domain is included
- Apply changes: `terraform apply`

### High Bedrock costs
- Review CloudWatch metrics for request volume
- Lower rate limits in `terraform.tfvars`
- Consider adding more aggressive rate limiting

## 📄 License

This infrastructure code is provided as-is for the Medical Tech Aesthetic project.

---

**Questions or issues?** Check the Terraform plan output or CloudWatch logs for detailed error messages.

