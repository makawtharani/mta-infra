terraform {
  backend "s3" {
    # TODO: Replace with your actual S3 bucket name
    bucket         = "mta-terraform-state-dev"
    key            = "chat-backend/dev/terraform.tfstate"
    region         = "us-east-1"
    
    # TODO: Replace with your actual DynamoDB table name
    dynamodb_table = "mta-terraform-locks"
    encrypt        = true
  }
  
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "mta-chat-backend"
      ManagedBy   = "terraform"
    }
  }
}

