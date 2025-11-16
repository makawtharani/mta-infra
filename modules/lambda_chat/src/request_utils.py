"""
Request parsing and validation utilities.
"""

import json


def get_client_ip(event):
    """
    Extract client IP from API Gateway event.
    
    Args:
        event: API Gateway event dict
        
    Returns:
        Client IP address string
    """
    headers = event.get('headers', {})
    
    # API Gateway HTTP API format
    request_context = event.get('requestContext', {})
    http_context = request_context.get('http', {})
    source_ip = http_context.get('sourceIp')
    if source_ip:
        return source_ip
    
    # Fallback to X-Forwarded-For header
    x_forwarded_for = headers.get('x-forwarded-for')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0].strip()
    
    # Last resort
    return request_context.get('identity', {}).get('sourceIp', 'unknown')


def parse_request_body(event):
    """
    Parse JSON request body from API Gateway event.
    
    Args:
        event: API Gateway event dict
        
    Returns:
        Tuple of (body: dict or None, error: dict or None)
    """
    try:
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})
        return body, None
        
    except json.JSONDecodeError:
        from responses import error_response
        return None, error_response(
            status_code=400,
            error_type='Invalid JSON',
            message='Request body must be valid JSON'
        )


def validate_message(body):
    """
    Validate that message field exists and is not empty.
    
    Args:
        body: Parsed request body dict
        
    Returns:
        Tuple of (message: str or None, error: dict or None)
    """
    message = body.get('message', '').strip()
    
    if not message:
        from responses import error_response
        return None, error_response(
            status_code=400,
            error_type='Missing message',
            message='Request must include a "message" field'
        )
    
    return message, None

