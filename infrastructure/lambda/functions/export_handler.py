"""
BhashaLens Export Handler
Generates JSON/CSV exports from History/Saved tables
Uploads to S3 and returns pre-signed URL
"""

import json
import csv
import boto3
import os
import time
import uuid
from decimal import Decimal
from io import StringIO
from boto3.dynamodb.conditions import Key

from shared.logging_utils import setup_logger, send_metrics
from shared.error_handling import create_response, handle_error
from shared.validation import safe_parse_body, validate_required_fields

logger = setup_logger()

aws_region = os.environ.get('AWS_REGION', 'us-east-1')
dynamodb = boto3.resource('dynamodb', region_name=aws_region)
s3_client = boto3.client('s3', region_name=aws_region)

TRANSLATION_HISTORY_TABLE = os.environ.get('TRANSLATION_HISTORY_TABLE')
SAVED_TRANSLATIONS_TABLE = os.environ.get('SAVED_TRANSLATIONS_TABLE')
EXPORT_BUCKET = os.environ.get('EXPORT_BUCKET')

def lambda_handler(event, context):
    start_time = time.time()
    request_id = getattr(context, 'aws_request_id', 'unknown')
    logger.info(f"[{request_id}] Export request received")
    
    authorizer = event.get('requestContext', {}).get('authorizer', {})
    user_id = authorizer.get('userId')
    
    if not user_id:
        return create_response(401, {'error': 'Unauthorized'})
        
    if event.get('httpMethod', 'POST') != 'POST':
        return create_response(405, {'error': 'Method not allowed'})
        
    try:
        body, err = safe_parse_body(event)
        if err: return create_response(400, {'error': err})
        
        is_valid, err_msg = validate_required_fields(body, ['exportType', 'format'])
        if not is_valid: return create_response(400, {'error': err_msg})
        
        export_type = body['exportType']  # history, saved, both
        export_format = body['format'].lower()  # json, csv
        
        if export_type not in ['history', 'saved', 'both']:
            return create_response(400, {'error': 'Invalid exportType'})
        if export_format not in ['json', 'csv']:
            return create_response(400, {'error': 'Invalid format'})
            
        start_date = body.get('startDate')
        end_date = body.get('endDate')
        
        data = gather_export_data(user_id, export_type, start_date, end_date)
        
        if not data:
            return create_response(404, {'error': 'No data found to export'})
            
        file_content, content_type, extension = format_data(data, export_format)
        
        file_key = f"exports/{user_id}/{int(time.time()*1000)}_{uuid.uuid4().hex[:8]}.{extension}"
        
        # Upload to S3
        s3_client.put_object(
            Bucket=EXPORT_BUCKET,
            Key=file_key,
            Body=file_content,
            ContentType=content_type,
            ServerSideEncryption='aws:kms'
        )
        
        # Generate presigned URL (1 hour)
        url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': EXPORT_BUCKET, 'Key': file_key},
            ExpiresIn=3600
        )
        
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('Export_Success', processing_time_ms, True)
        
        return create_response(200, {
            'downloadUrl': url,
            'expiresAt': int(time.time() * 1000) + 3600000,
            'recordCount': len(data),
            'exportDate': int(time.time() * 1000)
        })
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('Export_Error', processing_time_ms, False)
        return handle_error(e, context, "Export request failed")

def gather_export_data(user_id, export_type, start_date=None, end_date=None):
    results = []
    
    if export_type in ['history', 'both']:
        table = dynamodb.Table(TRANSLATION_HISTORY_TABLE)
        key_cond = Key('userId').eq(user_id)
        if start_date and end_date:
            key_cond = key_cond & Key('timestamp').between(int(start_date), int(end_date))
            
        # Simplification: scans all history for this user
        resp = table.query(KeyConditionExpression=key_cond)
        h_items = resp.get('Items', [])
        while 'LastEvaluatedKey' in resp:
            resp = table.query(KeyConditionExpression=key_cond, ExclusiveStartKey=resp['LastEvaluatedKey'])
            h_items.extend(resp.get('Items', []))
            
        for item in h_items:
            item['_type'] = 'history'
        results.extend(h_items)
        
    if export_type in ['saved', 'both']:
        table = dynamodb.Table(SAVED_TRANSLATIONS_TABLE)
        key_cond = Key('userId').eq(user_id)
        if start_date and end_date:
            try:
                start_date_iso = int(start_date)
                end_date_iso = int(end_date)
                key_cond = key_cond & Key('savedAt').between(start_date_iso, end_date_iso)
            except ValueError:
                pass
        resp = table.query(KeyConditionExpression=key_cond)
        s_items = resp.get('Items', [])
        while 'LastEvaluatedKey' in resp:
            resp = table.query(KeyConditionExpression=key_cond, ExclusiveStartKey=resp['LastEvaluatedKey'])
            s_items.extend(resp.get('Items', []))
            
        for item in s_items:
            item['_type'] = 'saved'
        results.extend(s_items)
        
    # Sort unified results by timestamp/savedAt descending
    def get_time(x):
        try:
            return float(x.get('timestamp') or x.get('savedAt') or 0)
        except (ValueError, TypeError):
            return 0
        
    results.sort(key=get_time, reverse=True)
    return results

def format_data(data, format_type):
    if format_type == 'json':
        return json.dumps(data, indent=2, default=lambda o: float(o) if isinstance(o, Decimal) else str(o)), 'application/json', 'json'
    else:
        # CSV
        output = StringIO()
        writer = csv.writer(output)
        writer.writerow(['Type', 'Date', 'Source Language', 'Target Language', 'Original Text', 'Translated Text', 'Tags', 'Notes'])
        
        for item in data:
            dt = item.get('timestamp') or item.get('savedAt', 0)
            try:
                dt_val = float(dt)
                date_str = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(dt_val/1000)) if dt else ''
            except (ValueError, TypeError):
                date_str = ''
            
            tags = ','.join(item.get('tags', [])) if 'tags' in item else ''
            
            writer.writerow([
                item.get('_type', ''),
                date_str,
                item.get('sourceLang', ''),
                item.get('targetLang', ''),
                item.get('sourceText', ''),
                item.get('targetText', ''),
                tags,
                item.get('notes', '')
            ])
            
        return output.getvalue(), 'text/csv', 'csv'
