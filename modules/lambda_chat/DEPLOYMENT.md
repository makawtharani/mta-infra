# Lambda Deployment Guide

## Architecture

The Lambda function code is separated from Terraform configuration:

```
modules/lambda_chat/
├── main.tf              ← Terraform configuration
├── variables.tf         ← Input variables
├── outputs.tf           ← Outputs
├── requirements.txt     ← Empty (using Lambda layer)
└── src/                 ← Lambda source code
    ├── handler.py
    ├── rate_limiter.py
    ├── bedrock_client.py
    ├── request_utils.py
    ├── responses.py
    └── __init__.py
```

## How It Works

### 1. Terraform Packages Automatically

Terraform uses the `archive_file` data source to automatically create `lambda_package.zip` from the `src/` directory:

```hcl
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_package.zip"
}
```

**Benefits**:
- ✅ No manual build script needed
- ✅ Automatic repackaging on code changes
- ✅ Source hash tracking for updates
- ✅ Simple workflow

### 2. Lambda Layer for Dependencies

Instead of packaging boto3, we use **Klayers** - a public Lambda layer:

```hcl
layers = [
  "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p312-boto3:23"
]
```

**Benefits**:
- ✅ No pip install needed
- ✅ Smaller deployment package
- ✅ Latest boto3 version (1.40.42)
- ✅ Faster deployments

**Layer Details**:
- Provider: Keith's Layers (Klayers)
- Package: boto3 1.40.42
- Python: 3.12
- Region: us-east-1

## Deployment Workflow

### First Deploy

```bash
cd envs/dev
terraform init
terraform apply
```

That's it! Terraform handles:
1. Zipping the `src/` directory
2. Uploading to Lambda
3. Attaching the boto3 layer

### Update Lambda Code

```bash
# Edit Python files
cd modules/lambda_chat/src
vim handler.py  # or any other file

# Deploy changes
cd ../../envs/dev
terraform apply
```

Terraform detects code changes via `source_code_hash` and automatically:
1. Re-zips the updated code
2. Updates the Lambda function

### Update Configuration

```bash
# Edit terraform.tfvars
vim envs/dev/terraform.tfvars

# Apply changes
terraform apply
```

## No Build Script Needed

The `scripts/build_lambda.sh` script is now **obsolete**. It just prints an info message.

**Old workflow** (not needed anymore):
```bash
./scripts/build_lambda.sh  # ❌ Not needed
cd envs/dev
terraform apply
```

**New workflow** (simpler):
```bash
cd envs/dev
terraform apply  # ✅ Just this!
```

## Manual Packaging (for testing)

If you want to manually test packaging:

```bash
cd modules/lambda_chat/src
zip -r ../lambda_package.zip .
```

Then inspect the zip:
```bash
unzip -l ../lambda_package.zip
```

## Lambda Layer Information

### Current Layer
- **ARN**: `arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p312-boto3:23`
- **boto3**: 1.40.42
- **Python**: 3.12

### Updating Layer Version

If a newer Klayers version is available:

1. Check [Klayers GitHub](https://github.com/keithrozario/Klayers) or API:
   ```bash
   curl https://api.klayers.cloud/api/v2/p3.12/layers/latest/us-east-1/boto3
   ```

2. Update `modules/lambda_chat/main.tf`:
   ```hcl
   layers = [
     "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p312-boto3:NEW_VERSION"
   ]
   ```

3. Apply:
   ```bash
   terraform apply
   ```

## Troubleshooting

### "No module named 'boto3'"
- Check layer ARN is correct
- Verify layer is for Python 3.12
- Ensure region is us-east-1

### "Cannot find module 'handler'"
- Check `handler` variable is set to `handler.lambda_handler`
- Verify `handler.py` exists in `src/`
- Check zip structure: `unzip -l lambda_package.zip`

### Code changes not deploying
- Terraform should detect changes automatically
- If not, you can force update:
  ```bash
  terraform taint module.lambda_chat.aws_lambda_function.chat
  terraform apply
  ```

### Need additional Python packages?

**Option 1**: Find a Klayers layer
```bash
# Check available layers
curl https://api.klayers.cloud/api/v2/p3.12/layers/latest/us-east-1/
```

**Option 2**: Create custom layer
```bash
mkdir python
pip install package-name -t python/
zip -r layer.zip python/
aws lambda publish-layer-version --layer-name my-layer --zip-file fileb://layer.zip
```

**Option 3**: Package with code (traditional)
- Uncomment dependencies in `requirements.txt`
- Use a build script to install and package
- Update Terraform to not use `archive_file` data source

## Best Practices

✅ **DO**:
- Keep `src/` clean (only Python code)
- Use layers for common dependencies
- Let Terraform handle packaging
- Test code locally before deploying

❌ **DON'T**:
- Put compiled files in `src/` (*.pyc, __pycache__)
- Include large files unnecessarily
- Manually create lambda_package.zip
- Commit lambda_package.zip to git (ignored)

## File Size Limits

- **Deployment package** (zip): 50 MB
- **Unzipped**: 250 MB
- **Layers**: 5 layers max, 250 MB total

Current package size: ~10 KB (just Python code, no dependencies)

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
- name: Deploy Lambda
  run: |
    cd envs/prod
    terraform init
    terraform apply -auto-approve
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

No build step needed! Terraform handles everything.

