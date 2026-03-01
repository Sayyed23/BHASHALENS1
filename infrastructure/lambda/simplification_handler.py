"""
BhashaLens Simplification Handler Lambda Function
Processes text simplification and explanation requests using Amazon Bedrock
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
cloudwatch = boto3.client('cloudwatch', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

# Environment variables
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
MAX_RESPONSE_TIME_MS = 5000  # 5 second timeout

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for simplification requests
    
    Expected input:
    {
        "text": str,
        "target_complexity": str,  # "simple", "moderate", "complex"
        "language": str,
        "explain": bool
    }
    
    Returns:
    {
        "simplified_text": str,
        "explanation": str (optional),
        "complexity_reduction": float,
        "processing_time_ms": int
    }
    """
    start_time = time.time()
    request_id = context.request_id if hasattr(context, 'request_id') else 'unknown'
    
    logger.info(f"[{request_id}] Simplification request received")
    
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', event)
        
        # Validate required fields
        text = body.get('text')
        target_complexity = body.get('target_complexity', 'simple')
        language = body.get('language')
        explain = body.get('explain', False)
        
        logger.info(f"[{request_id}] Request params - language: {language}, complexity: {target_complexity}, explain: {explain}, text_length: {len(text) if text else 0}")
        
        if not all([text, language]):
            logger.warning(f"[{request_id}] Missing required fields")
            return create_response(400, {
                'error': 'Missing required fields: text, language'
            })
        
        # Validate complexity level
        valid_complexity = ['simple', 'moderate', 'complex']
        if target_complexity not in valid_complexity:
            logger.warning(f"[{request_id}] Invalid complexity level: {target_complexity}")
            return create_response(400, {
                'error': f'Invalid target_complexity: {target_complexity}. Must be one of: {", ".join(valid_complexity)}'
            })
        
        # Simplify text using Bedrock
        bedrock_start = time.time()
        simplified_text = simplify_text(text, target_complexity, language)
        
        # Generate explanation if requested
        explanation = None
        if explain:
            explanation = generate_explanation(text, simplified_text, language)
        
        bedrock_time_ms = int((time.time() - bedrock_start) * 1000)
        logger.info(f"[{request_id}] Bedrock processing completed in {bedrock_time_ms}ms")
        
        # Calculate complexity reduction (simplified metric)
        complexity_reduction = calculate_complexity_reduction(text, simplified_text)
        
        # Calculate processing time
        processing_time_ms = int((time.time() - start_time) * 1000)
        
        # Check if we exceeded target response time
        if processing_time_ms > MAX_RESPONSE_TIME_MS:
            logger.warning(f"[{request_id}] Response time exceeded target: {processing_time_ms}ms > {MAX_RESPONSE_TIME_MS}ms")
        
        # Send metrics to CloudWatch (async, don't block response)
        try:
            send_metrics('Simplification', processing_time_ms, True, bedrock_time_ms)
        except Exception as e:
            logger.error(f"[{request_id}] Failed to send metrics: {str(e)}")
        
        # Return response
        response_body = {
            'simplified_text': simplified_text,
            'explanation': explanation,
            'complexity_reduction': complexity_reduction,
            'processing_time_ms': processing_time_ms
        }
        
        logger.info(f"[{request_id}] Simplification request completed successfully in {processing_time_ms}ms")
        return create_response(200, response_body)
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        logger.error(f"[{request_id}] Error processing simplification request: {str(e)}", exc_info=True)
        
        try:
            send_metrics('Simplification', processing_time_ms, False, 0)
        except Exception as metric_error:
            logger.error(f"[{request_id}] Failed to send error metrics: {str(metric_error)}")
        
        return create_response(500, {
            'error': 'Internal server error',
            'message': str(e) if os.environ.get('DEBUG') == 'true' else 'Simplification request failed'
        })

def simplify_text(text: str, target_complexity: str, language: str) -> str:
    """Simplify text using Amazon Bedrock"""
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    language_name = lang_map.get(language, language)
    
    # Map complexity levels to instructions
    complexity_instructions = {
        'simple': 'very simple language suitable for beginners',
        'moderate': 'moderately simple language',
        'complex': 'slightly simplified language while maintaining detail'
    }
    
    instruction = complexity_instructions.get(target_complexity, complexity_instructions['simple'])
    
    prompt = f"""You are a language simplification expert. Rewrite the following {language_name} text using {instruction}.

Important guidelines:
1. Preserve the original meaning and key information
2. Use shorter sentences and simpler words
3. Break down complex concepts into easier-to-understand parts
4. Maintain factual accuracy
5. Keep the same language ({language_name})

Original text:
{text}

Simplified text:"""
    
    simplified_text = invoke_bedrock(prompt)
    return simplified_text

def generate_explanation(original_text: str, simplified_text: str, language: str) -> str:
    """Generate educational explanation of the text"""
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    language_name = lang_map.get(language, language)
    
    prompt = f"""Provide a brief educational explanation of the following text in {language_name}. 
Explain the key concepts and why they are important.

Original text:
{original_text}

Simplified version:
{simplified_text}

Educational explanation:"""
    
    explanation = invoke_bedrock(prompt)
    return explanation

def calculate_complexity_reduction(original_text: str, simplified_text: str) -> float:
    """
    Calculate complexity reduction metric
    This is a simplified calculation based on text length and word count
    """
    # Count words
    original_words = len(original_text.split())
    simplified_words = len(simplified_text.split())
    
    # Calculate average word length
    original_avg_word_len = len(original_text.replace(' ', '')) / max(original_words, 1)
    simplified_avg_word_len = len(simplified_text.replace(' ', '')) / max(simplified_words, 1)
    
    # Calculate reduction (0.0 to 1.0)
    word_count_factor = min(1.0, (original_words - simplified_words) / max(original_words, 1))
    word_length_factor = (original_avg_word_len - simplified_avg_word_len) / max(original_avg_word_len, 1)
    
    # Combine factors (weighted average)
    complexity_reduction = max(0.0, min(1.0, (word_count_factor * 0.4 + word_length_factor * 0.6)))
    
    return round(complexity_reduction, 2)

def invoke_bedrock(prompt: str, max_tokens: int = 2048) -> str:
    """Invoke Bedrock model with a prompt - optimized for performance"""
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": max_tokens,
        "temperature": 0.5,
        "top_p": 0.9,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    }
    
    try:
        response = bedrock_runtime.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body)
        )
        
        response_body = json.loads(response['body'].read())
        return response_body['content'][0]['text'].strip()
    except Exception as e:
        logger.error(f"Bedrock invocation failed: {str(e)}")
        raise

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
