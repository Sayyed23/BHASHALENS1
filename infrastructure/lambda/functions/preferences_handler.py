"""
BhashaLens User Preferences Handler
Handles GET and PUT operations for user preferences
Includes version-based conflict resolution (Optimistic Concurrency Control)
"""

import json
import boto3
import os
import time

from shared.logging_utils import setup_logger, send_metrics
from shared.error_handling import create_response, handle_error
from shared.validation import safe_parse_body

logger = setup_logger()

aws_region = os.environ.get('AWS_REGION', 'us-east-1')
dynamodb = boto3.resource('dynamodb', region_name=aws_region)

USER_PREFERENCES_TABLE = os.environ.get('USER_PREFERENCES_TABLE')
if not USER_PREFERENCES_TABLE:
    raise EnvironmentError("USER_PREFERENCES_TABLE environment variable is required")
DEFAULT_PREFERENCES = {
    'theme': 'system',
    'defaultSourceLang': 'en',
    'defaultTargetLang': 'hi',
    'dataUsagePolicy': 'standard',
    'accessibilitySettings': {
        'highContrast': False,
        'largeText': False,
        'reduceMotion': False
    },
    'notificationSettings': {
        'dailyReminders': False,
        'appUpdates': True
    },
    'version': 1
}

def lambda_handler(event, context):
    start_time = time.time()
    request_id = getattr(context, 'aws_request_id', 'unknown')
    logger.info(f"[{request_id}] Preferences request received")
    
    authorizer = event.get('requestContext', {}).get('authorizer', {})
    user_id = authorizer.get('userId')
    if not user_id:
        return create_response(401, {'error': 'Unauthorized'})        
        return create_response(401, {'error': 'Unauthorized'})
        
    http_method = event.get('httpMethod', 'GET')
    
    try:
        if http_method == 'GET':
            response = handle_get(user_id)
            
        elif http_method == 'PUT':
            body, err = safe_parse_body(event)
            if err: return create_response(400, {'error': err})
            response = handle_put(user_id, body)
            
        else:
            return create_response(405, {'error': f'Method {http_method} not allowed'})
            
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('Preferences_Success', processing_time_ms, True)
        return create_response(200, response)
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('Preferences_Error', processing_time_ms, False)
        
        # Check for ConditionalCheckFailedException (version conflict)
        if e.__class__.__name__ == 'ConditionalCheckFailedException':
            return create_response(409, {
                'error': 'Version conflict', 
                'message': 'The provided version does not match the current server version.'
            })
            
        return handle_error(e, context, "Preferences request failed")

def handle_get(user_id):
    table = dynamodb.Table(USER_PREFERENCES_TABLE)
    response = table.get_item(Key={'userId': user_id})
    
    if 'Item' in response:
        return response['Item']
        
    # If no preferences exist, return defaults
    prefs = dict(DEFAULT_PREFERENCES)
    prefs['userId'] = user_id
    prefs['version'] = 0  # Signal that preferences haven't been persisted yet
    prefs['createdAt'] = int(time.time() * 1000)
    prefs['updatedAt'] = prefs['createdAt']
    return prefs
def handle_put(user_id, body):
    table = dynamodb.Table(USER_PREFERENCES_TABLE)
    now = int(time.time() * 1000)
    
    # Extract client version to check
    client_version = body.get('version', 0)
    
    # Build complete new item based on defaults merged with body
    new_item = dict(DEFAULT_PREFERENCES)
    
    # Override with provided values
    allowed_keys = ['theme', 'defaultSourceLang', 'defaultTargetLang', 'dataUsagePolicy']
    for k in allowed_keys:
        if k in body: new_item[k] = body[k]
        
    if 'accessibilitySettings' in body:
        new_item['accessibilitySettings'].update(body['accessibilitySettings'])
        
    if 'notificationSettings' in body:
        new_item['notificationSettings'].update(body['notificationSettings'])
        
    new_item['userId'] = user_id
    new_item['updatedAt'] = now
    new_item['lastSyncedAt'] = now
    
    # Optimistic concurrency:
    # If client version is 0 or missing, we assume this is the first write.
    if client_version == 0:
        new_item['version'] = 1
        new_item['createdAt'] = now
        try:
            table.put_item(
                Item=new_item,
                ConditionExpression='attribute_not_exists(userId)'
            )
        except boto3.client('dynamodb').exceptions.ConditionalCheckFailedException:
            # Item actually exists but client didn't know the version
            raise
        if client_version == 0:
            new_item['version'] = 1
            new_item['createdAt'] = now
            table.put_item(
                Item=new_item,
                ConditionExpression='attribute_not_exists(userId)'
            )
        else:    else:
        new_item['version'] = client_version + 1
        # Fetch original's createdAt to preserve it
        existing = table.get_item(Key={'userId': user_id})
        if 'Item' in existing:
            new_item['createdAt'] = existing['Item'].get('createdAt', now)
        else:
            new_item['createdAt'] = now
        table.put_item(
            Item=new_item,
            ConditionExpression='version = :cv',
            ExpressionAttributeValues={':cv': client_version}
        )