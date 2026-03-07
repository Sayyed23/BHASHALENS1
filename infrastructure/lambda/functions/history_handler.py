"""
BhashaLens History Handler Lambda Function
Handles GET and DELETE operations for Translation History
"""

import json
import boto3
import os
import time
from boto3.dynamodb.conditions import Key, Attr

# Shared layer imports
from shared.logging_utils import setup_logger, send_metrics
from shared.error_handling import create_response, handle_error
from shared.validation import safe_parse_body

logger = setup_logger()

aws_region = os.environ.get('AWS_REGION', 'us-east-1')
dynamodb = boto3.resource('dynamodb', region_name=aws_region)

TRANSLATION_HISTORY_TABLE = os.environ.get('TRANSLATION_HISTORY_TABLE')
if not TRANSLATION_HISTORY_TABLE:
    raise ValueError("TRANSLATION_HISTORY_TABLE environment variable missing")

def lambda_handler(event, context):
    start_time = time.time()
    request_id = getattr(context, 'aws_request_id', 'unknown')
    logger.info(f"[{request_id}] History request received")
    
    # Get user_id from Custom Authorizer context
    authorizer = event.get('requestContext', {}).get('authorizer', {})
    user_id = authorizer.get('userId')
    
    # Fallback to query param if testing without authorizer (should be guarded in prod)
    if not user_id and os.environ.get('ALLOW_INSECURE_QUERY_USERID') == 'true':
        logger.warning("ALLOW_INSECURE_QUERY_USERID is enabled. Accepting userId from query parameters.")
        user_id = event.get('queryStringParameters', {}).get('userId')
        
    if not user_id:
        return create_response(401, {'error': 'Unauthorized: Missing userId'})
        
    http_method = event.get('httpMethod', 'GET')
    path_parameters = event.get('pathParameters') or {}
    query_params = event.get('queryStringParameters') or {}
    
    try:
        if http_method == 'GET':
            response = handle_get(user_id, query_params)
            
        elif http_method == 'POST':
            # Support for manual history insertion (syncing)
            body, err = safe_parse_body(event)
            if err:
                return create_response(400, {'error': err})
            response = handle_post(user_id, body)
            
        elif http_method == 'DELETE':
            # Check if deleting specific item or all history
            timestamp = path_parameters.get('timestamp')
            
            if timestamp:
                try:
                    ts_val = int(timestamp)
                except ValueError:
                    return create_response(400, {'error': 'Invalid timestamp'})
                response = handle_delete_single(user_id, ts_val)
            else:
                response = handle_delete_all(user_id)
        else:
            return create_response(405, {'error': f'Method {http_method} not allowed'})
            
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('History_Success', processing_time_ms, True)
        return create_response(200, response)
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('History_Error', processing_time_ms, False)
        if isinstance(e, ValueError):
            return create_response(400, {'error': str(e)})
        return handle_error(e, context, "History request failed")

def handle_get(user_id, query_params):
    table = dynamodb.Table(TRANSLATION_HISTORY_TABLE)
    
    limit = int(query_params.get('pageSize', 20))
    limit = min(max(limit, 1), 100)  # Restrict 1-100
    
    start_date = query_params.get('startDate')
    end_date = query_params.get('endDate')
    last_evaluated_key_str = query_params.get('lastEvaluatedKey')
    
    # Base expression: partition key
    key_cond = Key('userId').eq(user_id)
    
    # Add sort key conditions if dates provided
    try:
        if start_date and end_date:
            key_cond = key_cond & Key('timestamp').between(int(start_date), int(end_date))
        elif start_date:
            key_cond = key_cond & Key('timestamp').gte(int(start_date))
        elif end_date:
            key_cond = key_cond & Key('timestamp').lte(int(end_date))
    except (ValueError, TypeError):
        raise ValueError("Invalid startDate or endDate")
        
    query_kwargs = {
        'KeyConditionExpression': key_cond,
        'Limit': limit,
        'ScanIndexForward': False  # Descending order, newest first
    }
    
    if last_evaluated_key_str:
        try:
            lek = json.loads(last_evaluated_key_str)
            query_kwargs['ExclusiveStartKey'] = lek
        except:
            pass # Ignore invalid lek
            
    response = table.query(**query_kwargs)
    items = response.get('Items', [])
    
    return {
        'items': items,
        'count': len(items),
        'lastEvaluatedKey': json.dumps(response.get('LastEvaluatedKey')) if 'LastEvaluatedKey' in response else None,
        'hasMore': 'LastEvaluatedKey' in response
    }

def handle_delete_single(user_id, timestamp):
    table = dynamodb.Table(TRANSLATION_HISTORY_TABLE)
    table.delete_item(
        Key={
            'userId': user_id,
            'timestamp': timestamp
        }
    )
    return {'message': 'History item deleted'}

def handle_delete_all(user_id):
    """Note: This can be expensive on DynamoDB. A realistic approach uses TTL or batch delete."""
    table = dynamodb.Table(TRANSLATION_HISTORY_TABLE)
    
    # Query all items for user
    response = table.query(
        KeyConditionExpression=Key('userId').eq(user_id),
        ProjectionExpression='userId, #ts',
        ExpressionAttributeNames={'#ts': 'timestamp'}
    )
    
    items = response.get('Items', [])
    total_deleted = 0
    with table.batch_writer() as batch:
        for item in items:
            batch.delete_item(
                Key={
                    'userId': item['userId'],
                    'timestamp': item['timestamp']
                }
            )
        total_deleted += len(items)
            
    # Handle pagination if many items
    while 'LastEvaluatedKey' in response:
        response = table.query(
            KeyConditionExpression=Key('userId').eq(user_id),
            ProjectionExpression='userId, #ts',
            ExpressionAttributeNames={'#ts': 'timestamp'},
            ExclusiveStartKey=response['LastEvaluatedKey']
        )
        page_items = response.get('Items', [])
        with table.batch_writer() as batch:
            for item in page_items:
                batch.delete_item(
                    Key={
                        'userId': item['userId'],
                        'timestamp': item['timestamp']
                    }
                )
        total_deleted += len(page_items)
    
    return {'message': f'Deleted all {total_deleted} history items for user'}

def handle_post(user_id, body):
    """
    Manually create a history item. Used for syncing offline translations.
    """
    table = dynamodb.Table(TRANSLATION_HISTORY_TABLE)
    
    # Required fields for history
    required_fields = ['sourceText', 'targetText', 'sourceLang', 'targetLang']
    for field in required_fields:
        if field not in body:
            raise ValueError(f"Missing required field: {field}")
            
    # Timestamp can be provided or generated
    timestamp = body.get('timestamp')
    if not timestamp:
        timestamp = int(time.time() * 1000)
    else:
        try:
            timestamp = int(timestamp)
        except ValueError:
            raise ValueError("Invalid timestamp")
            
    item = {
        'userId': user_id,
        'timestamp': timestamp,
        'sourceText': body['sourceText'],
        'targetText': body['targetText'],
        'sourceLang': body['sourceLang'],
        'targetLang': body['targetLang'],
        'backend': body.get('backend', 'offline'), # Default to offline if syncing
        'processingTime': body.get('processingTime', 0),
        'type': body.get('type', 'translation')
    }
    
    table.put_item(Item=item)
    return {'message': 'History item created', 'item': item}
