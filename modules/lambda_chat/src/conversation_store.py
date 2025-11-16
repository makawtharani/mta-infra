"""
Conversation history storage using DynamoDB.
"""

import os
import time
import boto3
from botocore.exceptions import ClientError

# Environment variables
CONVERSATIONS_TABLE_NAME = os.environ.get('CONVERSATIONS_TABLE_NAME', '')

# DynamoDB client
dynamodb = boto3.resource('dynamodb')
conversations_table = dynamodb.Table(CONVERSATIONS_TABLE_NAME) if CONVERSATIONS_TABLE_NAME else None


def save_conversation(session_id, role, message):
    """
    Save a conversation message to DynamoDB.
    
    Args:
        session_id: Unique session identifier (e.g., user IP or custom ID)
        role: Message role ('user' or 'assistant')
        message: Message content
    """
    if not conversations_table:
        print("Warning: Conversations table not configured")
        return False
    
    try:
        # TTL: 30 days from now
        ttl = int(time.time()) + (30 * 24 * 60 * 60)
        
        conversations_table.put_item(
            Item={
                'session_id': session_id,
                'timestamp': int(time.time() * 1000),  # milliseconds for sorting
                'role': role,
                'message': message,
                'expires_at': ttl
            }
        )
        return True
        
    except ClientError as e:
        print(f"Error saving conversation: {str(e)}")
        return False
    except Exception as e:
        print(f"Unexpected error saving conversation: {str(e)}")
        return False


def get_conversation_history(session_id, limit=5):
    """
    Get recent conversation history for a session.
    
    Args:
        session_id: Session identifier
        limit: Maximum number of messages to retrieve
        
    Returns:
        List of messages in format: [{"role": "user", "content": "..."}]
    """
    if not conversations_table:
        return []
    
    try:
        response = conversations_table.query(
            KeyConditionExpression='session_id = :sid',
            ExpressionAttributeValues={
                ':sid': session_id
            },
            ScanIndexForward=False,  # Get most recent first
            Limit=limit
        )
        
        # Convert to message format and reverse (oldest first)
        messages = [
            {
                'role': item['role'],
                'content': item['message']
            }
            for item in reversed(response.get('Items', []))
        ]
        
        return messages
        
    except ClientError as e:
        print(f"Error retrieving conversation history: {str(e)}")
        return []
    except Exception as e:
        print(f"Unexpected error retrieving history: {str(e)}")
        return []

