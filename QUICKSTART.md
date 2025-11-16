# Quick Start Guide

Get the MTA chat backend running in 15 minutes.

## Prerequisites Check

```bash
# Verify tools are installed
terraform --version    # Need >= 1.5.0
aws --version         # Need AWS CLI v2
python3 --version     # Need >= 3.12
jq --version          # For diagnostic scripts

# Verify AWS credentials
aws sts get-caller-identity
```

## Step 1: Set up Terraform Backend (5 min)

```bash
# Set your AWS region
export AWS_REGION=us-east-1

# Create S3 bucket for Terraform state
aws s3 mb s3://mta-terraform-state-dev --region $AWS_REGION

# Enable versioning (important for state safety)
aws s3api put-bucket-versioning \
  --bucket mta-terraform-state-dev \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket mta-terraform-state-dev \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name mta-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $AWS_REGION

echo "✓ Backend resources created!"
```

## Step 2: Configure Backend (2 min)

Edit `envs/dev/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "mta-terraform-state-dev"    # ← Your bucket name
    key            = "chat-backend/dev/terraform.tfstate"
    region         = "us-east-1"                  # ← Your region
    dynamodb_table = "mta-terraform-locks"        # ← Your table name
    encrypt        = true
  }
  # ... rest stays the same
}
```

## Step 3: Enable Bedrock Access (2 min)

1. Go to AWS Console → Bedrock → Model access
2. Request access to **OpenAI GPT-OSS-120B**
3. Wait for approval (usually instant)

Or use CLI:
```bash
aws bedrock get-foundation-model \
  --model-identifier openai.gpt-oss-120b-1:0 \
  --region us-east-1
```

## Step 4: Prepare Scripts (1 min)

```bash
# Make diagnostic script executable
chmod +x scripts/diag.sh

# Note: Lambda packaging is handled automatically by Terraform
# No manual build step needed!
```

## Step 5: Deploy Infrastructure (3 min)

```bash
cd envs/dev

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create resources (approve when prompted)
terraform apply

# Save the API endpoint
terraform output api_endpoint
```

## Step 6: Test It! (2 min)

```bash
# Go back to project root
cd ../..

# Test the endpoint
./scripts/diag.sh test dev

# Should see a JSON response from Claude!
```

## Step 7: Monitor (optional)

```bash
# Tail live logs
./scripts/diag.sh logs dev

# Open CloudWatch Dashboard
# AWS Console → CloudWatch → Dashboards → mta-chat-dev
```

## 🎉 You're Done!

Your API endpoint is ready. Example integration:

```javascript
// Frontend integration
const response = await fetch('YOUR_API_ENDPOINT', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    message: 'What services do you offer?'
  })
});

const data = await response.json();
console.log(data.response); // Claude's answer
```

## Next Steps

- [ ] Update CORS origins in `terraform.tfvars` to your domain
- [ ] Set up CloudWatch alarms with SNS (add `alarm_sns_topic_arn`)
- [ ] Adjust rate limits based on expected traffic
- [ ] Test rate limiting: `for i in {1..12}; do curl -X POST ...; done`
- [ ] Deploy to production using `envs/prod/`

## Troubleshooting

**"Access denied" when applying:**
- Check IAM permissions (need Lambda, API Gateway, DynamoDB, Bedrock)

**"Model not found" error:**
- Enable Bedrock model access (Step 3)
- Check region supports Bedrock

**Lambda package not found:**
- Run `./scripts/build_lambda.sh` first

**CORS errors in browser:**
- Update `cors_allow_origins` in `terraform.tfvars`

## Cost Estimate

Dev environment with light testing: **~$1-5/month**

See [README.md](README.md) for detailed cost breakdown.

---

Need help? Check the full [README.md](README.md) for detailed documentation.

