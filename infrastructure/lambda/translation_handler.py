"""
BhashaLens Translation Handler Lambda Function
Processes translation requests using Amazon Bedrock
"""

import json
import boto3
import os
import time
import logging
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
cloudwatch = boto3.client('cloudwatch', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

# Environment variables
TRANSLATION_HISTORY_TABLE = os.environ.get('TRANSLATION_HISTORY_TABLE')
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
MAX_RESPONSE_TIME_MS = 5000  # 5 second timeout

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for translation requests
    
    Expected input:
    {
        "source_text": str,
        "source_lang": str,
        "target_lang": str,
        "user_id": str (optional)
    }
    
    Returns:
    {
        "translated_text": str,
        "confidence": float,
        "model": str,
        "processing_time_ms": int
    }
    """
    start_time = time.time()
    request_id = context.request_id if hasattr(context, 'request_id') else 'unknown'
    
    logger.info(f"[{request_id}] Translation request received")
    
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', event)
        
        # Validate required fields
        source_text = body.get('source_text')
        source_lang = body.get('source_lang')
        target_lang = body.get('target_lang')
        user_id = body.get('user_id')
        
        logger.info(f"[{request_id}] Request params - source_lang: {source_lang}, target_lang: {target_lang}, text_length: {len(source_text) if source_text else 0}")
        
        if not all([source_text, source_lang, target_lang]):
            logger.warning(f"[{request_id}] Missing required fields")
            return create_response(400, {
                'error': 'Missing required fields: source_text, source_lang, target_lang'
            })
        
        # Validate text length (max 5000 characters for performance)
        if len(source_text) > 5000:
            logger.warning(f"[{request_id}] Text too long: {len(source_text)} characters")
            return create_response(400, {
                'error': 'Text too long. Maximum 5000 characters allowed.'
            })
        
        # Translate using Bedrock
        bedrock_start = time.time()
        translated_text, confidence = translate_with_bedrock(
            source_text, source_lang, target_lang
        )
        bedrock_time_ms = int((time.time() - bedrock_start) * 1000)
        
        logger.info(f"[{request_id}] Bedrock translation completed in {bedrock_time_ms}ms")
        
        # Calculate processing time
        processing_time_ms = int((time.time() - start_time) * 1000)
        
        # Check if we exceeded target response time
        if processing_time_ms > MAX_RESPONSE_TIME_MS:
            logger.warning(f"[{request_id}] Response time exceeded target: {processing_time_ms}ms > {MAX_RESPONSE_TIME_MS}ms")
        
        # Save to DynamoDB if user_id provided (async, don't block response)
        if user_id and TRANSLATION_HISTORY_TABLE:
            try:
                save_translation_history(
                    user_id, source_text, translated_text,
                    source_lang, target_lang, processing_time_ms
                )
            except Exception as e:
                logger.error(f"[{request_id}] Failed to save history: {str(e)}")
        
        # Send metrics to CloudWatch (async, don't block response)
        try:
            send_metrics('Translation', processing_time_ms, True, bedrock_time_ms)
        except Exception as e:
            logger.error(f"[{request_id}] Failed to send metrics: {str(e)}")
        
        # Return response
        response_body = {
            'translated_text': translated_text,
            'confidence': confidence,
            'model': BEDROCK_MODEL_ID,
            'processing_time_ms': processing_time_ms
        }
        
        logger.info(f"[{request_id}] Translation request completed successfully in {processing_time_ms}ms")
        return create_response(200, response_body)
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        logger.error(f"[{request_id}] Error processing translation: {str(e)}", exc_info=True)
        
        try:
            send_metrics('Translation', processing_time_ms, False, 0)
        except Exception as metric_error:
            logger.error(f"[{request_id}] Failed to send error metrics: {str(metric_error)}")
        
        return create_response(500, {
            'error': 'Internal server error',
            'message': str(e) if os.environ.get('DEBUG') == 'true' else 'Translation failed'
        })

def translate_with_bedrock(source_text: str, source_lang: str, target_lang: str) -> tuple:
    """
    Translate text using Amazon Bedrock Claude model
    Optimized for <5s response time
    
    Returns: (translated_text, confidence)
    """
    # Map language codes to full names
    lang_map = {
        'hi': 'Hindi',
        'mr': 'Marathi',
        'en': 'English'
    }
    
    source_language = lang_map.get(source_lang, source_lang)
    target_language = lang_map.get(target_lang, target_lang)
    
    # Create concise prompt for faster processing
    prompt = f"""Translate from {source_language} to {target_language}. Output only the translation.

{source_text}"""
    
    # Prepare request body for Claude with optimized settings
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": min(2048, len(source_text) * 3),  # Dynamic token limit
        "temperature": 0.3,
        "top_p": 0.9,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    }
    
    try:
        # Invoke Bedrock model with timeout handling
        response = bedrock_runtime.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body)
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        translated_text = response_body['content'][0]['text'].strip()
        
        # Calculate confidence based on response metadata
        stop_reason = response_body.get('stop_reason', 'end_turn')
        confidence = 0.90 if stop_reason == 'end_turn' else 0.75
        
        return translated_text, confidence
        
    except Exception as e:
        logger.error(f"Bedrock invocation failed: {str(e)}")
        raise

def save_translation_history(
    user_id: str, source_text: str, translated_text: str,
    source_lang: str, target_lang: str, processing_time_ms: int
) -> None:
    """Save translation to DynamoDB history table"""
    try:
        table = dynamodb.Table(TRANSLATION_HISTORY_TABLE)
        timestamp = int(time.time() * 1000)
        
        table.put_item(
            Item={
                'user_id': user_id,
                'timestamp': timestamp,
                'source_text': source_text,
                'translated_text': translated_text,
                'source_lang': source_lang,
                'target_lang': target_lang,
                'mode': 'cloud',
                'backend': 'aws_bedrock',
                'processing_time_ms': processing_time_ms
            }
        )
    except Exception as e:
        print(f"Error saving translation history: {str(e)}")

def send_metrics(operation: str, processing_time_ms: int, success: bool, bedrock_time_ms: int = 0) -> None:
    """Send custom metrics to CloudWatch"""
    try:
        metric_data = [
            {
                'MetricName': 'ProcessingTime',
                'Value': processing_time_ms,
                'Unit': 'Milliseconds',
                'Dimensions': [
                    {'Name': 'Operation', 'Value': operation},
                    {'Name': 'Success', 'Value': str(success)}
                ]
            },
            {
                'MetricName': 'RequestCount',
                'Value': 1,
                'Unit': 'Count',
                'Dimensions': [
                    {'Name': 'Operation', 'Value': operation},
                    {'Name': 'Success', 'Value': str(success)}
                ]
            }
        ]
        
        # Add Bedrock-specific timing if available
        if bedrock_time_ms > 0:
            metric_data.append({
                'MetricName': 'BedrockLatency',
                'Value': bedrock_time_ms,
                'Unit': 'Milliseconds',
                'Dimensions': [
                    {'Name': 'Operation', 'Value': operation}
                ]
            })
        
        # Add performance target compliance metric
        target_met = processing_time_ms <= MAX_RESPONSE_TIME_MS
        metric_data.append({
            'MetricName': 'PerformanceTargetMet',
            'Value': 1 if target_met else 0,
            'Unit': 'Count',
            'Dimensions': [
                {'Name': 'Operation', 'Value': operation}
            ]
        })
        
        cloudwatch.put_metric_data(
            Namespace='BhashaLens',
            MetricData=metric_data
        )
    except Exception as e:
        logger.error(f"Error sending metrics: {str(e)}")

def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """Create API Gateway response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps(body)
    }
