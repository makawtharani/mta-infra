# AWS Configuration
aws_region   = "us-east-1"
project_name = "mta-chat"
environment  = "prod"

# Bedrock Model Configuration
bedrock_model_id = "openai.gpt-oss-120b-1:0"

# Rate Limiting Configuration (Lambda-level)
rate_limit_window = 60  # seconds (1 minute)
rate_limit_max    = 15  # max requests per IP per window (slightly higher for prod)

# API Gateway Throttling (coarse first-line defense)
api_throttle_burst_limit = 10  # burst capacity
api_throttle_rate_limit  = 2   # sustained requests per second

# Lambda Configuration
lambda_reserved_concurrency = 50    # higher limit for production
lambda_memory_size          = 1024  # MB
lambda_timeout              = 30    # seconds

# CORS Configuration
cors_allow_origins = ["https://medical-tech-aesthetic.com"]  # Production domain only

# Logging Configuration
log_retention_days = 30  # CloudWatch log retention

# Alarms Configuration
alarm_4xx_threshold = 20  # trigger alarm after 20 4xx errors in 5 min
alarm_5xx_threshold = 10  # trigger alarm after 10 5xx errors in 5 min
alarm_sns_topic_arn = ""  # TODO: Add SNS topic ARN for alarm notifications

