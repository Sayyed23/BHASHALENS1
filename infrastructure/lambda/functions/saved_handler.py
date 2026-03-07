"""
BhashaLens Saved Translations Handler
Handles GET, POST, PUT, DELETE operations for Saved Translations
Enforces 500 limit per user.
"""

import json
import boto3
import os
import time
import copy
import uuid
from boto3.dynamodb.conditions import Key

from shared.logging_utils import setup_logger, send_metrics
from shared.error_handling import create_response, handle_error
from shared.validation import safe_parse_body, validate_required_fields

logger = setup_logger()

aws_region = os.environ.get('AWS_REGION', 'us-east-1')
dynamodb = boto3.resource('dynamodb', region_name=aws_region)

SAVED_TRANSLATIONS_TABLE = os.environ.get('SAVED_TRANSLATIONS_TABLE')
if not SAVED_TRANSLATIONS_TABLE:
    raise EnvironmentError("SAVED_TRANSLATIONS_TABLE environment variable is required")
MAX_SAVED = 500
def lambda_handler(event, context):
    start_time = time.time()
    request_id = getattr(context, 'aws_request_id', 'unknown')
    logger.info(f"[{request_id}] Saved request received")
    
    authorizer = event.get('requestContext', {}).get('authorizer', {})
    user_id = authorizer.get('userId')
    if not user_id:
        return create_response(401, {'error': 'Unauthorized'})
        
    http_method = event.get('httpMethod', 'GET')
    path_parameters = event.get('pathParameters') or {}
    query_params = event.get('queryStringParameters') or {}
    
    try:
        if http_method == 'GET':
            response = handle_get(user_id, query_params)
            
        elif http_method == 'POST':
            body, err = safe_parse_body(event)
            if err: return create_response(400, {'error': err})
            response = handle_post(user_id, body)
            
        elif http_method == 'PUT':
            translation_id = path_parameters.get('translationId')
            if not translation_id: return create_response(400, {'error': 'Missing translationId path parameter'})
            body, err = safe_parse_body(event)
            if err: return create_response(400, {'error': err})
            response = handle_put(user_id, translation_id, body)
            
        elif http_method == 'DELETE':
            translation_id = path_parameters.get('translationId')
            if not translation_id: return create_response(400, {'error': 'Missing translationId path parameter'})
            response = handle_delete(user_id, translation_id)
            
        else:
            return create_response(405, {'error': f'Method {http_method} not allowed'})
            
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('Saved_Success', processing_time_ms, True)
        return create_response(200, response)
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('Saved_Error', processing_time_ms, False)
        
        # Check for 400 bad request error from handle_post limit
        if str(e).startswith('Limit exceeded'):
            return create_response(400, {'error': str(e)})
        if str(e) == 'Translation not found':
            return create_response(404, {'error': str(e)})
            
        return handle_error(e, context, "Saved request failed")
    pass # Removed get_user_saved_count
def handle_get(user_id, query_params):
    table = dynamodb.Table(SAVED_TRANSLATIONS_TABLE)
    
    # Query all (saved limits to 500, so we can fetch all and filter in python, or use ScanIndexForward for pagination)
    response = table.query(
        KeyConditionExpression=Key('userId').eq(user_id)
    )
    items = response.get('Items', [])
    
    # Optional naive search filtering (better handled with ElasticSearch or indexing on tags)
    search_term = query_params.get('search', '').lower()
    if search_term:
        filtered = []
        for item in items:
            tags = item.get('tags') or []
            text = f"{item.get('sourceText','')} {item.get('targetText','')} {' '.join(tags)}".lower()
            if search_term in text:
                filtered.append(item)
        items = filtered
    
    return {
        'items': items,
        'count': len(items)
    }

def handle_post(user_id, body):
    is_valid, err = validate_required_fields(body, ['sourceText', 'targetText', 'sourceLang', 'targetLang'])
    if not is_valid: raise ValueError(err)
        
    table = dynamodb.Table(SAVED_TRANSLATIONS_TABLE)
    now = int(time.time() * 1000)
    translation_id = str(uuid.uuid4())
    
    item = {
        'userId': user_id,
        'translationId': translation_id,
        'sourceText': body['sourceText'],
        'targetText': body['targetText'],
        'sourceLang': body['sourceLang'],
        'targetLang': body['targetLang'],
        'tags': body.get('tags', []),
        'notes': body.get('notes', ''),
        'savedAt': now,
        'updatedAt': now,
        'usageCount': 1,
        'lastAccessedAt': now
    }
    
    from boto3.dynamodb.types import TypeSerializer
    serializer = TypeSerializer()
    dynamodb_item = {k: serializer.serialize(v) for k, v in item.items()}
    
    try:
        table.meta.client.transact_write_items(
            TransactItems=[
                {
                    'Update': {
                        'TableName': SAVED_TRANSLATIONS_TABLE,
                        'Key': {'userId': {'S': user_id}, 'translationId': {'S': 'METADATA#COUNT'}},
                        'UpdateExpression': 'ADD savedCount :inc',
                        'ConditionExpression': 'attribute_not_exists(savedCount) OR savedCount < :max',
                        'ExpressionAttributeValues': {':inc': {'N': '1'}, ':max': {'N': str(MAX_SAVED)}}
                    }
                },
                {
                    'Put': {
                        'TableName': SAVED_TRANSLATIONS_TABLE,
                        'Item': dynamodb_item
                    }
                }
            ]
        )
    except table.meta.client.exceptions.TransactionCanceledException as e:
        if 'ConditionalCheckFailed' in str(e):
            raise Exception(f'Limit exceeded: Maximum {MAX_SAVED} saved translations allowed per user')
        raise
        
    return {'message': 'Translation saved', 'item': item}

def handle_put(user_id, translation_id, body):
    table = dynamodb.Table(SAVED_TRANSLATIONS_TABLE)
    now = int(time.time() * 1000)
    
    update_expr = []
    expr_attrs = {':now': now}
    expr_names = {}
    
    if 'tags' in body:
        update_expr.append('#t = :tags')
        expr_attrs[':tags'] = body['tags']
        expr_names['#t'] = 'tags'
        
    if 'notes' in body:
        update_expr.append('#n = :notes')
        expr_attrs[':notes'] = body['notes']
        expr_names['#n'] = 'notes'
        
    # Always update lastAccessed and count
    update_expr.append('lastAccessedAt = :now')
    update_expr.append('updatedAt = :now')
    
    # Also optionally handle incrementing usage count. Assuming we increment usage when we request PUT
    update_expr.append('usageCount = usageCount + :inc')
    expr_attrs[':inc'] = 1
    
    if not update_expr:
        return {'message': 'Nothing to update'}
        
    update_cmd = 'SET ' + ', '.join(update_expr)
    
    expr_names['#translationId'] = 'translationId'
    kwargs = {
        'Key': {'userId': user_id, 'translationId': translation_id},
        'UpdateExpression': update_cmd,
        'ConditionExpression': 'attribute_exists(#translationId)',
        'ExpressionAttributeValues': expr_attrs,
        'ReturnValues': 'ALL_NEW'
    }
    if expr_names: kwargs['ExpressionAttributeNames'] = expr_names
    
    try:
        response = table.update_item(**kwargs)
        return {'message': 'Translation updated', 'item': response.get('Attributes')}
    except table.meta.client.exceptions.ConditionalCheckFailedException:
        raise ValueError('Translation not found')

def handle_delete(user_id, translation_id):
    table = dynamodb.Table(SAVED_TRANSLATIONS_TABLE)
    try:
        table.meta.client.transact_write_items(
            TransactItems=[
                {
                    'Update': {
                        'TableName': SAVED_TRANSLATIONS_TABLE,
                        'Key': {'userId': {'S': user_id}, 'translationId': {'S': 'METADATA#COUNT'}},
                        'UpdateExpression': 'ADD savedCount :dec',
                        'ExpressionAttributeValues': {':dec': {'N': '-1'}}
                    }
                },
                {
                    'Delete': {
                        'TableName': SAVED_TRANSLATIONS_TABLE,
                        'Key': {'userId': {'S': user_id}, 'translationId': {'S': translation_id}}
                    }
                }
            ]
        )
    except Exception as e:
        # Fallback if transaction fails
        table.delete_item(Key={'userId': user_id, 'translationId': translation_id})
    return {'message': 'Translation unsaved'}
