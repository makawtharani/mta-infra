# AWS Configuration
aws_region   = "us-east-1"
project_name = "mta-chat"
environment  = "dev"

# Bedrock Model Configuration
bedrock_model_id = "openai.gpt-oss-120b-1:0"

# Rate Limiting Configuration (Lambda-level)
rate_limit_window = 60  # seconds (1 minute)
rate_limit_max    = 10  # max requests per IP per window

# API Gateway Throttling (coarse first-line defense)
api_throttle_burst_limit = 5   # burst capacity
api_throttle_rate_limit  = 1   # sustained requests per second

# Lambda Configuration
lambda_reserved_concurrency = -1    # -1 means unreserved (use account default)
lambda_memory_size          = 512   # MB
lambda_timeout              = 30    # seconds

# CORS Configuration
cors_allow_origins = ["*"]  # TODO: Replace with your actual domain in prod

# Logging Configuration
log_retention_days = 7  # CloudWatch log retention

# Alarms Configuration
alarm_4xx_threshold = 10  # trigger alarm after 10 4xx errors in 5 min
alarm_5xx_threshold = 5   # trigger alarm after 5 5xx errors in 5 min
alarm_sns_topic_arn = ""  # TODO: Add SNS topic ARN for alarm notifications

