"""
Response formatting utilities.
"""

import json
import os
from bedrock_client import get_model_id
from rate_limiter import get_rate_limit_config


def success_response(response_text, rate_limit_remaining):
    """
    Format successful response.
    
    Args:
        response_text: AI response text
        rate_limit_remaining: Remaining requests in current window
        
    Returns:
        API Gateway response dict
    """
    config = get_rate_limit_config()
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'X-RateLimit-Limit': str(config['max']),
            'X-RateLimit-Remaining': str(rate_limit_remaining),
            'X-RateLimit-Window': str(config['window'])
        },
        'body': json.dumps({
            'response': response_text,
            'model': get_model_id()
        })
    }


def error_response(status_code, error_type, message):
    """
    Format error response.
    
    Args:
        status_code: HTTP status code
        error_type: Error type string
        message: Human-readable error message
        
    Returns:
        API Gateway response dict
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'error': error_type,
            'message': message
        })
    }


def rate_limit_response():
    """
    Format rate limit exceeded response.
    
    Returns:
        API Gateway response dict
    """
    config = get_rate_limit_config()
    
    return {
        'statusCode': 429,
        'headers': {
            'Content-Type': 'application/json',
            'X-RateLimit-Limit': str(config['max']),
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Window': str(config['window'])
        },
        'body': json.dumps({
            'error': 'Rate limit exceeded',
            'message': f'Too many requests. Maximum {config["max"]} requests per {config["window"]} seconds.',
            'retry_after': config['window']
        })
    }

