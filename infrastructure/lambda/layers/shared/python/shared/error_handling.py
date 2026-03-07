"""
Shared Error Handling utility
"""
import json
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """Create API Gateway standardized response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(body)
    }

def handle_error(e: Exception, context: Any, message: str = "Internal server error") -> Dict[str, Any]:
    """Standardized error handler block"""
    request_id = getattr(context, 'aws_request_id', 'unknown')
    logger.error(f"[{request_id}] Error: {str(e)}", exc_info=True)
    
    return create_response(500, {
        'error': message,
        'details': str(e),
        'requestId': request_id
    })
