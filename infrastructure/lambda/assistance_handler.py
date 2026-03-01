"""
BhashaLens Assistance Handler Lambda Function
Processes assistance requests (grammar, Q&A, conversation) using Amazon Bedrock
"""

import json
import boto3
import os
import time
import logging
from typing import Dict, Any, List

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
    Main Lambda handler for assistance requests
    
    Expected input:
    {
        "request_type": str,  # "grammar", "qa", "conversation"
        "text": str,
        "language": str,
        "context": str (optional),
        "conversation_history": list (optional)
    }
    
    Returns:
    {
        "response": str,
        "metadata": dict,
        "processing_time_ms": int
    }
    """
    start_time = time.time()
    request_id = context.request_id if hasattr(context, 'request_id') else 'unknown'
    
    logger.info(f"[{request_id}] Assistance request received")
    
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', event)
        
        # Validate required fields
        request_type = body.get('request_type')
        text = body.get('text')
        language = body.get('language')
        context_text = body.get('context')
        conversation_history = body.get('conversation_history', [])
        
        logger.info(f"[{request_id}] Request type: {request_type}, language: {language}, text_length: {len(text) if text else 0}")
        
        if not all([request_type, text, language]):
            logger.warning(f"[{request_id}] Missing required fields")
            return create_response(400, {
                'error': 'Missing required fields: request_type, text, language'
            })
        
        # Validate request type
        valid_types = ['grammar', 'qa', 'conversation']
        if request_type not in valid_types:
            logger.warning(f"[{request_id}] Invalid request type: {request_type}")
            return create_response(400, {
                'error': f'Invalid request_type: {request_type}. Must be one of: {", ".join(valid_types)}'
            })
        
        # Process based on request type
        bedrock_start = time.time()
        if request_type == 'grammar':
            response_data = process_grammar_check(text, language)
        elif request_type == 'qa':
            response_data = process_question_answer(text, language, context_text)
        elif request_type == 'conversation':
            response_data = process_conversation(text, language, conversation_history)
        
        bedrock_time_ms = int((time.time() - bedrock_start) * 1000)
        logger.info(f"[{request_id}] Bedrock processing completed in {bedrock_time_ms}ms")
        
        # Calculate processing time
        processing_time_ms = int((time.time() - start_time) * 1000)
        
        # Check if we exceeded target response time
        if processing_time_ms > MAX_RESPONSE_TIME_MS:
            logger.warning(f"[{request_id}] Response time exceeded target: {processing_time_ms}ms > {MAX_RESPONSE_TIME_MS}ms")
        
        # Send metrics to CloudWatch (async, don't block response)
        try:
            send_metrics(f'Assistance_{request_type}', processing_time_ms, True, bedrock_time_ms)
        except Exception as e:
            logger.error(f"[{request_id}] Failed to send metrics: {str(e)}")
        
        # Return response
        response_body = {
            'response': response_data['response'],
            'metadata': response_data.get('metadata', {}),
            'processing_time_ms': processing_time_ms
        }
        
        logger.info(f"[{request_id}] Assistance request completed successfully in {processing_time_ms}ms")
        return create_response(200, response_body)
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        logger.error(f"[{request_id}] Error processing assistance request: {str(e)}", exc_info=True)
        
        try:
            send_metrics('Assistance_Error', processing_time_ms, False, 0)
        except Exception as metric_error:
            logger.error(f"[{request_id}] Failed to send error metrics: {str(metric_error)}")
        
        return create_response(500, {
            'error': 'Internal server error',
            'message': str(e) if os.environ.get('DEBUG') == 'true' else 'Assistance request failed'
        })

def process_grammar_check(text: str, language: str) -> Dict[str, Any]:
    """Process grammar checking request"""
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    language_name = lang_map.get(language, language)
    
    prompt = f"""You are a {language_name} language expert. Check the following text for grammatical errors and provide corrections with explanations.

Text to check:
{text}

Provide your response in JSON format with the following structure:
{{
    "corrected_text": "the corrected version of the text",
    "corrections": [
        {{
            "original": "original text segment",
            "corrected": "corrected text segment",
            "explanation": "explanation of the correction"
        }}
    ]
}}

Response:"""
    
    response_text = invoke_bedrock(prompt)
    
    # Parse JSON response
    try:
        parsed_response = json.loads(response_text)
    except json.JSONDecodeError:
        # Fallback if response is not valid JSON
        parsed_response = {
            "corrected_text": response_text,
            "corrections": []
        }
    
    return {
        'response': parsed_response.get('corrected_text', text),
        'metadata': {
            'corrections': parsed_response.get('corrections', [])
        }
    }

def process_question_answer(text: str, language: str, context: str = None) -> Dict[str, Any]:
    """Process question answering request"""
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    language_name = lang_map.get(language, language)
    
    prompt = f"""You are a helpful language assistant. Answer the following question in {language_name}.

Question: {text}"""
    
    if context:
        prompt += f"\n\nContext: {context}"
    
    prompt += "\n\nProvide a clear and concise answer:"
    
    response_text = invoke_bedrock(prompt)
    
    return {
        'response': response_text,
        'metadata': {
            'language': language_name
        }
    }

def process_conversation(text: str, language: str, conversation_history: List[Dict]) -> Dict[str, Any]:
    """Process conversation practice request"""
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    language_name = lang_map.get(language, language)
    
    # Build conversation context
    messages = []
    
    # Add system message
    system_prompt = f"""You are a friendly language practice partner helping someone learn {language_name}. 
Respond naturally in {language_name} and help them practice the language. 
Keep responses conversational and encouraging."""
    
    messages.append({
        "role": "user",
        "content": system_prompt
    })
    
    messages.append({
        "role": "assistant",
        "content": "I understand. I'll help with language practice."
    })
    
    # Add conversation history (last 10 exchanges)
    for msg in conversation_history[-10:]:
        messages.append({
            "role": msg.get('role', 'user'),
            "content": msg.get('content', '')
        })
    
    # Add current message
    messages.append({
        "role": "user",
        "content": text
    })
    
    # Invoke Bedrock with conversation context
    response_text = invoke_bedrock_with_messages(messages)
    
    return {
        'response': response_text,
        'metadata': {
            'language': language_name,
            'conversation_length': len(conversation_history) + 1
        }
    }

def invoke_bedrock(prompt: str, max_tokens: int = 2048) -> str:
    """Invoke Bedrock model with a simple prompt - optimized for performance"""
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": max_tokens,
        "temperature": 0.7,
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

def invoke_bedrock_with_messages(messages: List[Dict]) -> str:
    """Invoke Bedrock model with conversation messages"""
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 2048,
        "temperature": 0.7,
        "messages": messages
    }
    
    response = bedrock_runtime.invoke_model(
        modelId=BEDROCK_MODEL_ID,
        body=json.dumps(request_body)
    )
    
    response_body = json.loads(response['body'].read())
    return response_body['content'][0]['text'].strip()

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
