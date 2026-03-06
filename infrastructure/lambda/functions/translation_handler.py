"""
BhashaLens Translation Handler Lambda Function
Processes translation requests using Amazon Bedrock with Gemini fallback
"""

import json
import boto3
import os
import time
import google.generativeai as genai

# Shared layer imports
from shared.logging_utils import setup_logger, send_metrics
from shared.error_handling import create_response, handle_error
from shared.validation import safe_parse_body, validate_required_fields, validate_text_length
from shared.circuit_breaker import CircuitBreaker

logger = setup_logger()

# Initialize AWS clients
aws_region = os.environ.get('AWS_REGION', 'us-east-1')
bedrock_runtime = boto3.client('bedrock-runtime', region_name=aws_region)
dynamodb = boto3.resource('dynamodb', region_name=aws_region)

# Environment variables
TRANSLATION_HISTORY_TABLE = os.environ.get('TRANSLATION_HISTORY_TABLE')
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')
MAX_RESPONSE_TIME_MS = 5000

# Initialize Circuit Breaker and Gemini
bedrock_cb = CircuitBreaker(failure_threshold=3, recovery_timeout=60)
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    gemini_model = genai.GenerativeModel('gemini-1.5-flash')
else:
    gemini_model = None

def lambda_handler(event, context):
    start_time = time.time()
    request_id = getattr(context, 'aws_request_id', 'unknown')
    logger.info(f"[{request_id}] Translation request received")
    
    try:
        # Parse & Validate
        body, err = safe_parse_body(event)
        if err:
            return create_response(400, {'error': err})
            
        is_valid, err_msg = validate_required_fields(body, ['source_text', 'source_lang', 'target_lang'])
        if not is_valid:
            return create_response(400, {'error': err_msg})
            
        source_text = body['source_text']
        source_lang = body['source_lang']
        target_lang = body['target_lang']
        user_id = body.get('user_id')
        
        is_valid_len, err_msg = validate_text_length(source_text, 5000)
        if not is_valid_len:
            return create_response(400, {'error': err_msg})
            
        # Translation Logic with Circuit Breaker and Fallback
        translated_text = None
        confidence = 0.0
        used_model = ''
        bedrock_time_ms = 0
        bedrock_start = time.time()
        
        if bedrock_cb.is_allowed():
            try:
                translated_text, confidence = translate_with_bedrock(source_text, source_lang, target_lang)
                bedrock_cb.record_success()
                used_model = BEDROCK_MODEL_ID
                bedrock_time_ms = int((time.time() - bedrock_start) * 1000)
            except Exception as e:
                logger.warning(f"[{request_id}] Bedrock failed, recording failure: {str(e)}")
                bedrock_cb.record_failure()
                
        if not translated_text and gemini_model:
            logger.info(f"[{request_id}] Falling back to Gemini")
            try:
                translated_text, confidence = translate_with_gemini(source_text, source_lang, target_lang)
                used_model = 'gemini-1.5-flash'
            except Exception as e:
                logger.error(f"[{request_id}] Gemini fallback failed: {str(e)}")
                raise Exception("All translation backends failed")
                
        if not translated_text:
            raise Exception("Translation failed or no backends available")
            
        processing_time_ms = int((time.time() - start_time) * 1000)
        
        # Save History
        if user_id and TRANSLATION_HISTORY_TABLE:
            try:
                save_translation_history(user_id, source_text, translated_text, source_lang, target_lang, processing_time_ms, used_model)
            except Exception as e:
                logger.error(f"[{request_id}] History save failed: {str(e)}")
                
        # Metrics
        send_metrics('Translation', processing_time_ms, True, {'BedrockLatency': bedrock_time_ms} if bedrock_time_ms > 0 else None)
        
        return create_response(200, {
            'translated_text': translated_text,
            'confidence': confidence,
            'model': used_model,
            'processing_time_ms': processing_time_ms
        })
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('Translation_Error', processing_time_ms, False)
        return handle_error(e, context, "Translation request failed")

def translate_with_bedrock(source_text: str, source_lang: str, target_lang: str):
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    source_language = lang_map.get(source_lang, source_lang)
    target_language = lang_map.get(target_lang, target_lang)
    
    prompt = f"Translate from {source_language} to {target_language}. Output only the translation.\n\n{source_text}"
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": min(2048, max(256, len(source_text) * 3)),        "temperature": 0.3,
        "messages": [{"role": "user", "content": prompt}]
    }
    
    response = bedrock_runtime.invoke_model(modelId=BEDROCK_MODEL_ID, body=json.dumps(request_body))
    response_body = json.loads(response['body'].read())
    content = response_body.get('content', [])
    if not content or 'text' not in content[0]:
        raise Exception("Unexpected Bedrock response format")
    translated_text = content[0]['text'].strip()
    stop_reason = response_body.get('stop_reason', 'end_turn')
    return translated_text, 0.90 if stop_reason == 'end_turn' else 0.75
def translate_with_gemini(source_text: str, source_lang: str, target_lang: str):
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    source_language = lang_map.get(source_lang, source_lang)
    target_language = lang_map.get(target_lang, target_lang)
    
    prompt = f"Translate from {source_language} to {target_language}. Output only the translation, no extra text.\n\n{source_text}"
    response = gemini_model.generate_content(prompt)
    if not response.text:
        raise Exception("Gemini returned empty response")
    return response.text.strip(), 0.85

def save_translation_history(user_id, source_text, translated_text, source_lang, target_lang, processing_time_ms, backend):
    table = dynamodb.Table(TRANSLATION_HISTORY_TABLE)
    timestamp = int(time.time() * 1000)
    table.put_item(
        Item={
            'userId': user_id,  # Updated from user_id to match Phase 1 requirements
            'timestamp': timestamp,
            'sourceText': source_text,
            'targetText': translated_text,
            'sourceLang': source_lang,
            'targetLang': target_lang,
            'backend': backend,
            'processingTime': processing_time_ms
        }
    )
