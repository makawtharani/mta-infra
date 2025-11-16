"""
Lambda handler - minimal orchestration only.
"""

import json
import os
from rate_limiter import check_rate_limit
from bedrock_client import get_ai_response
from request_utils import get_client_ip, parse_request_body, validate_message
from responses import success_response, error_response, rate_limit_response
from conversation_store import save_conversation, get_conversation_history


def lambda_handler(event, context):
    """
    Main Lambda handler - orchestrates the request flow.
    """
    print(f"Event: {json.dumps(event)}")
    
    # Extract client IP
    client_ip = get_client_ip(event)
    print(f"Client IP: {client_ip}")
    
    # Check rate limit
    allowed, remaining = check_rate_limit(client_ip)
    if not allowed:
        return rate_limit_response()
    
    # Parse and validate request
    body, error = parse_request_body(event)
    if error:
        return error
    
    message, error = validate_message(body)
    if error:
        return error
    
    # Get optional parameters
    system_prompt = body.get('system_prompt')
    conversation_history = body.get('conversation_history', [])
    session_id = body.get('session_id', client_ip)  # Use IP as fallback session ID
    
    # Get stored conversation history if not provided
    if not conversation_history and os.environ.get('CONVERSATIONS_TABLE_NAME'):
        stored_history = get_conversation_history(session_id, limit=5)
        if stored_history:
            conversation_history = stored_history
    
    # Call AI service
    response_text, error = get_ai_response(message, system_prompt, conversation_history)
    if error:
        return error
    
    # Save conversation to history
    if os.environ.get('CONVERSATIONS_TABLE_NAME'):
        save_conversation(session_id, 'user', message)
        save_conversation(session_id, 'assistant', response_text)
    
    # Return success
    return success_response(response_text, remaining)
