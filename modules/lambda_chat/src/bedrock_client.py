"""
Bedrock AI client - handles all AI model interactions.
"""

import os
import json
import boto3
from botocore.exceptions import ClientError
from system_prompt import DEFAULT_SYSTEM_PROMPT

# Environment variables
BEDROCK_MODEL_ID = os.environ['BEDROCK_MODEL_ID']

# Bedrock client
bedrock = boto3.client('bedrock-runtime')


def get_ai_response(message, system_prompt=None, conversation_history=None):
    """
    Get AI response from Bedrock.
    
    Args:
        message: User message text
        system_prompt: Optional system prompt override
        conversation_history: Optional list of previous messages
        
    Returns:
        Tuple of (response_text: str or None, error: dict or None)
    """
    try:
        response_text = call_bedrock(message, system_prompt, conversation_history)
        return response_text, None
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        print(f"Bedrock error: {error_code} - {error_msg}")
        
        from responses import error_response
        return None, error_response(
            status_code=500,
            error_type='AI service error',
            message='Unable to process your request. Please try again later.'
        )
        
    except Exception as e:
        print(f"Unexpected error calling Bedrock: {str(e)}")
        from responses import error_response
        return None, error_response(
            status_code=500,
            error_type='Internal server error',
            message='An unexpected error occurred'
        )


def call_bedrock(message, system_prompt=None, conversation_history=None):
    """
    Call Bedrock API with OpenAI format.
    
    Args:
        message: User message
        system_prompt: Optional system prompt override
        conversation_history: Optional list of previous messages
        
    Returns:
        Response text from the model
    """
    # Use default if not provided
    if system_prompt is None:
        system_prompt = DEFAULT_SYSTEM_PROMPT
    
    # Build messages in OpenAI format
    messages = [
        {
            "role": "system",
            "content": system_prompt
        }
    ]
    
    # Add conversation history if provided
    if conversation_history and isinstance(conversation_history, list):
        for msg in conversation_history[-5:]:  # Last 5 messages only
            if isinstance(msg, dict) and 'role' in msg and 'content' in msg:
                messages.append({
                    "role": msg['role'],
                    "content": msg['content']
                })
    
    # Add current user message
    messages.append({
        "role": "user",
        "content": message
    })
    
    # Build request body
    request_body = {
        "messages": messages,
        "max_completion_tokens": 1024,
        "temperature": 0.7,
        "top_p": 0.9
    }
    
    # Call Bedrock
    response = bedrock.invoke_model(
        modelId=BEDROCK_MODEL_ID,
        body=json.dumps(request_body)
    )
    
    # Parse response
    response_body = json.loads(response['body'].read())
    
    # Extract text from choices
    assistant_message = ""
    for choice in response_body.get('choices', []):
        assistant_message += choice.get('message', {}).get('content', '')
    
    return assistant_message


def get_model_id():
    """
    Get the current model ID.
    
    Returns:
        Model ID string
    """
    return BEDROCK_MODEL_ID

