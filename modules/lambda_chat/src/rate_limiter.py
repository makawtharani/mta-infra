"""
Rate limiting logic using DynamoDB.
"""

import os
import time
import boto3
from botocore.exceptions import ClientError

# Environment variables
RATELIMIT_TABLE_NAME = os.environ['RATELIMIT_TABLE_NAME']
RATE_LIMIT_WINDOW = int(os.environ.get('RATE_LIMIT_WINDOW', '60'))
RATE_LIMIT_MAX = int(os.environ.get('RATE_LIMIT_MAX', '10'))

# DynamoDB client
dynamodb = boto3.resource('dynamodb')
ratelimit_table = dynamodb.Table(RATELIMIT_TABLE_NAME)


def check_rate_limit(ip_address):
    """
    Check and update rate limit for given IP.
    
    Args:
        ip_address: Client IP address
        
    Returns:
        Tuple of (allowed: bool, remaining: int)
    """
    # Calculate current time bucket
    now = int(time.time())
    minute_bucket = now // RATE_LIMIT_WINDOW
    
    # Keys for DynamoDB
    pk = ip_address
    sk = str(minute_bucket)
    
    # TTL: expire records after 5 minutes
    ttl = now + (RATE_LIMIT_WINDOW * 5)
    
    try:
        # Atomic increment with condition
        response = ratelimit_table.update_item(
            Key={'ip': pk, 'minute_bucket': sk},
            UpdateExpression='ADD request_count :inc SET expires_at = :ttl',
            ExpressionAttributeValues={
                ':inc': 1,
                ':ttl': ttl,
                ':max': RATE_LIMIT_MAX
            },
            ConditionExpression='attribute_not_exists(request_count) OR request_count < :max',
            ReturnValues='ALL_NEW'
        )
        
        count = int(response['Attributes']['request_count'])
        remaining = max(0, RATE_LIMIT_MAX - count)
        return True, remaining
        
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
            # Rate limit exceeded
            return False, 0
        
        # Other DynamoDB errors - fail open for availability
        print(f"Rate limit check error: {str(e)}")
        return True, RATE_LIMIT_MAX


def get_rate_limit_config():
    """
    Get current rate limit configuration.
    
    Returns:
        Dict with 'window' and 'max' keys
    """
    return {
        'window': RATE_LIMIT_WINDOW,
        'max': RATE_LIMIT_MAX
    }

