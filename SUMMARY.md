# MTA Chat Backend - Project Summary

Complete Terraform infrastructure for an AI chatbot backend using AWS serverless architecture.

## 🎯 What This Project Provides

A **production-ready, cost-effective AI chatbot backend** for https://medical-tech-aesthetic.com/ with:

- 🚫 **No authentication required** - Public API for lead generation
- 🛡️ **Built-in abuse protection** - Two-layer rate limiting (API Gateway + DynamoDB)
- 🤖 **AI-powered responses** - OpenAI GPT-OSS-120B via Amazon Bedrock
- 💰 **Cost optimized** - Serverless, pay-per-use pricing (~$50-100/month for moderate traffic)
- 📊 **Full observability** - CloudWatch dashboard, alarms, structured logging
- 🏗️ **Modular code** - Clean, testable, maintainable Lambda functions
- 🌍 **Multi-environment** - Separate dev/prod configurations

## 📦 What's Included

### Infrastructure as Code (Terraform)
```
✅ API Gateway HTTP API (public, CORS-enabled)
✅ Lambda function (Python 3.12, modular architecture)
✅ DynamoDB table (rate limiting with TTL)
✅ IAM roles & policies (least-privilege)
✅ CloudWatch logs, metrics, alarms
✅ CloudWatch dashboard
```

### Lambda Function (Modular Python)
```
✅ handler.py         - Minimal orchestration (44 lines)
✅ rate_limiter.py    - DynamoDB rate limiting logic
✅ bedrock_client.py  - AI model interaction
✅ request_utils.py   - Request parsing/validation
✅ responses.py       - Response formatting
```

### Documentation
```
✅ README.md          - Complete setup guide
✅ QUICKSTART.md      - 15-minute quick start
✅ TESTING.md         - Testing guide with examples
✅ ARCHITECTURE.md    - Lambda architecture details
✅ REFACTORING.md     - Before/after comparison
```

### Tools & Scripts
```
✅ build_lambda.sh    - Build Lambda deployment package
✅ diag.sh            - Diagnostics (logs, test, warmup)
✅ postman_collection.json - API testing collection
```

## 🏛️ Architecture

```
User Request
    ↓
API Gateway (throttling, CORS)
    ↓
Lambda Function
    ├─→ Rate Limiter (DynamoDB)
    └─→ Bedrock (OpenAI GPT-OSS-120B)
    ↓
Response (JSON)
```

### Rate Limiting Strategy

**Layer 1: API Gateway (coarse)**
- Burst: 5 requests (dev), 10 (prod)
- Rate: 1 req/s (dev), 2 req/s (prod)

**Layer 2: Lambda + DynamoDB (fine-grained)**
- Per-IP: 10 requests/min (dev), 15 (prod)
- Atomic DynamoDB operations
- Automatic cleanup via TTL

## 🚀 Quick Start

```bash
# 1. Set up backend (S3 + DynamoDB)
aws s3 mb s3://mta-terraform-state-dev
aws dynamodb create-table --table-name mta-terraform-locks ...

# 2. Deploy (Terraform handles Lambda packaging automatically)
cd envs/dev
terraform init
terraform apply

# 4. Test
../../scripts/diag.sh test dev
```

See [QUICKSTART.md](QUICKSTART.md) for detailed steps.

## 🧪 Testing

### Postman
1. Import `postman_collection.json`
2. Set `dev_api_endpoint` variable
3. Run test requests

### Command Line
```bash
# Quick test
./scripts/diag.sh test dev

# Watch logs
./scripts/diag.sh logs dev

# Get URL
./scripts/diag.sh url dev
```

### Rate Limit Testing
```bash
# Send 12 requests rapidly (limit is 10)
for i in {1..12}; do
  curl -X POST $API_URL -d '{"message":"test"}'
done
# Requests 11-12 should return 429
```

See [TESTING.md](TESTING.md) for comprehensive test scenarios.

## 💡 Key Design Decisions

### Why No Authentication?
- **Goal**: Maximize lead capture, minimize friction
- **Protection**: Rate limiting prevents abuse
- **Trade-off**: Suitable for public information, not PII

### Why Modular Lambda?
- **Testability**: Each module independently testable
- **Maintainability**: Clear separation of concerns
- **Extensibility**: Easy to add features (conversation history, caching, etc.)

### Why DynamoDB for Rate Limiting?
- **Atomic operations**: Conditional updates prevent race conditions
- **Serverless**: No infrastructure to manage
- **TTL**: Automatic cleanup, no maintenance

### Why OpenAI GPT-OSS-120B?
- **Open source**: No vendor lock-in
- **Performance**: 120B parameters for high-quality responses
- **Context**: 128K token context window
- **Cost**: Competitive pricing via Bedrock

## 📊 Cost Breakdown

### Estimated Monthly Costs (1000 requests/day)

| Service | Cost |
|---------|------|
| API Gateway | $0.03 |
| Lambda | $0.60 |
| DynamoDB | $0.75 |
| **Bedrock** | **$45-90** |
| CloudWatch | $1.50 |
| **Total** | **~$48-93/month** |

> Bedrock is the primary cost driver. Monitor usage and adjust rate limits accordingly.

## 🔒 Security Features

✅ IP-based rate limiting  
✅ Reserved Lambda concurrency (DoS protection)  
✅ CORS configuration  
✅ CloudWatch monitoring & alarms  
✅ Encrypted Terraform state  
✅ Least-privilege IAM roles  
✅ No credentials in code  

## 📈 Monitoring

### CloudWatch Dashboard
- API Gateway requests, errors
- Lambda invocations, duration, errors
- Rate limit hits (custom metric)

### Alarms
- High rate limit hits (> 50 in 5 min)
- Lambda errors (> 5 in 5 min)
- Lambda throttles (> 5 in 5 min)
- API 4xx errors (> 10 in 5 min)
- API 5xx errors (> 5 in 5 min)

## 🛠️ Maintenance

### Regular Tasks
- Monitor CloudWatch dashboard
- Review alarm notifications
- Check Bedrock costs
- Update dependencies (`requirements.txt`)

### Updates
```bash
# Update Lambda code
cd modules/lambda_chat/src
# Edit Python files

# Apply changes (Terraform auto-packages)
cd ../../envs/dev
terraform apply
```

### Scaling
- Adjust rate limits in `terraform.tfvars`
- Increase Lambda memory/concurrency
- Enable DynamoDB auto-scaling (if needed)

## 📚 Documentation Structure

```
README.md              # Main documentation
QUICKSTART.md          # 15-minute setup guide
TESTING.md             # Testing guide
SUMMARY.md             # This file

modules/lambda_chat/
├── README.md          # Lambda module docs
├── ARCHITECTURE.md    # Detailed architecture
└── REFACTORING.md     # Before/after refactoring
```

## 🎓 Learning Resources

- [Amazon Bedrock Docs](https://docs.aws.amazon.com/bedrock/)
- [API Gateway HTTP API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Support

### Troubleshooting
1. Check CloudWatch logs: `./scripts/diag.sh logs dev`
2. Review Terraform state: `terraform show`
3. Verify IAM permissions
4. Confirm Bedrock model access

### Common Issues

**"Model not found"**
→ Enable OpenAI GPT-OSS-120B in Bedrock console

**"Rate limit not working"**
→ Check DynamoDB table exists and Lambda has permissions

**"CORS errors"**
→ Update `cors_allow_origins` in `terraform.tfvars`

**"High costs"**
→ Review Bedrock usage, adjust rate limits

## 🎯 Next Steps

After deployment:

1. ✅ Test all endpoints with Postman
2. ✅ Verify rate limiting works
3. ✅ Check CloudWatch dashboard
4. ✅ Set up SNS topic for alarms
5. ✅ Update CORS for production domain
6. ✅ Monitor costs for first week
7. ✅ Deploy to production environment

## 📝 License

This infrastructure code is provided for the Medical Tech Aesthetic project.

---

**Project Status**: ✅ Production Ready

**Last Updated**: October 2025

**Terraform Version**: >= 1.5.0

**AWS Provider**: ~> 5.0

