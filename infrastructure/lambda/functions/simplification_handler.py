"""
BhashaLens Simplification Handler Lambda Function
Processes text simplification and explanation requests using Amazon Bedrock with Gemini fallback
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

aws_region = os.environ.get('AWS_REGION', 'us-east-1')
bedrock_runtime = boto3.client('bedrock-runtime', region_name=aws_region)

BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-7-sonnet-20250219-v1:0')
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')
MAX_RESPONSE_TIME_MS = 5000

bedrock_cb = CircuitBreaker(failure_threshold=3, recovery_timeout=60)
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    gemini_model = genai.GenerativeModel('gemini-1.5-flash')
else:
    gemini_model = None

def lambda_handler(event, context):
    start_time = time.time()
    request_id = getattr(context, 'aws_request_id', 'unknown')
    logger.info(f"[{request_id}] Simplification request received")
    
    try:
        body, err = safe_parse_body(event)
        if err: return create_response(400, {'error': err})
            
        is_valid, err_msg = validate_required_fields(body, ['text', 'language'])
        if not is_valid: return create_response(400, {'error': err_msg})
            
        text = body['text']
        target_complexity = body.get('target_complexity', 'simple')
        language = body['language']
        explain = body.get('explain', False)
        
        is_valid_len, err_msg = validate_text_length(text, 5000)
        if not is_valid_len: return create_response(400, {'error': err_msg})
            
        valid_complexity = ['simple', 'moderate', 'complex']
        if target_complexity not in valid_complexity:
            return create_response(400, {'error': f'Invalid target_complexity'})

        simplified_text = None
        explanation = None
        used_model = ''
        bedrock_time_ms = 0
        bedrock_start = time.time()
        
        if bedrock_cb.is_allowed():
            try:
                simplified_text = simplify_text(text, target_complexity, language, invoke_bedrock)
                if explain:
                    explanation = generate_explanation(text, simplified_text, language, invoke_bedrock)
                
                bedrock_cb.record_success()
                used_model = BEDROCK_MODEL_ID
                bedrock_time_ms = int((time.time() - bedrock_start) * 1000)
            except Exception as e:
                logger.warning(f"[{request_id}] Bedrock failed: {str(e)}")
                bedrock_cb.record_failure()
                
        if not simplified_text and gemini_model:
            logger.info(f"[{request_id}] Falling back to Gemini")
            try:
                simplified_text = simplify_text(text, target_complexity, language, invoke_gemini)
                if explain:
                    explanation = generate_explanation(text, simplified_text, language, invoke_gemini)
                used_model = 'gemini-1.5-flash'
            except Exception as e:
                logger.error(f"[{request_id}] Gemini fallback failed: {str(e)}")
                raise Exception("All backend models failed")
                
        if not simplified_text:
            raise Exception("Processing failed")
            
        complexity_reduction = calculate_complexity_reduction(text, simplified_text)
        processing_time_ms = int((time.time() - start_time) * 1000)
        
        send_metrics('Simplification', processing_time_ms, True, {'BedrockLatency': bedrock_time_ms} if bedrock_time_ms > 0 else None)
        
        return create_response(200, {
            'simplified_text': simplified_text,
            'explanation': explanation,
            'complexity_reduction': complexity_reduction,
            'model': used_model,
            'processing_time_ms': processing_time_ms
        })
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('Simplification_Error', processing_time_ms, False)
        return handle_error(e, context, "Simplification request failed")

def simplify_text(text, target_complexity, language, invoker_func):
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English', 'ta': 'Tamil', 'te': 'Telugu', 'bn': 'Bengali'}
    lang_name = lang_map.get(language, language)
    instructions = {
        'simple': 'very simple, clear language with short sentences and easy words',
        'moderate': 'clear and accessible language while maintaining some detail',
        'complex': 'concise and accurate language, slightly simplified but preserving professional nuances'
    }
    inst = instructions.get(target_complexity, instructions['simple'])
    prompt = f"""You are a helpful assistant helping Indian users understand complex text.
Simplify the following {lang_name} text using {inst}. 
Preserve the core meaning but make it easily understandable for a layperson.
Output ONLY the simplified text:

{text}"""
    return invoker_func(prompt)

def generate_explanation(original, simplified, language, invoker_func):
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English', 'ta': 'Tamil', 'te': 'Telugu', 'bn': 'Bengali'}
    lang_name = lang_map.get(language, language)
    prompt = f"""Provide a brief educational explanation in {lang_name} comparing the original to the simplified version.
Explain WHY specific complex terms were changed and what they mean.
Keep it encouraging and helpful.

Original: {original}
Simplified: {simplified}"""
    return invoker_func(prompt)

def calculate_complexity_reduction(original, simplified):
    orig_words = len(original.split())
    simp_words = len(simplified.split())
    if orig_words == 0: return 0.0
    
    orig_len = len(original.replace(' ', '')) / max(orig_words, 1)
    simp_len = len(simplified.replace(' ', '')) / max(simp_words, 1)
    
    word_count_factor = min(1.0, (orig_words - simp_words) / orig_words)
    word_length_factor = (orig_len - simp_len) / max(orig_len, 1)
    
    return round(max(0.0, min(1.0, word_count_factor * 0.4 + word_length_factor * 0.6)), 2)

def invoke_bedrock(prompt):
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 2048, "temperature": 0.5,
        "messages": [{"role": "user", "content": prompt}]
    }
    response = bedrock_runtime.invoke_model(modelId=BEDROCK_MODEL_ID, body=json.dumps(request_body))
    response_body = json.loads(response['body'].read())
    
    if 'content' not in response_body or not response_body['content']:
        raise ValueError(f"Unexpected Bedrock response format: {list(response_body.keys())}")
    
    return response_body['content'][0]['text'].strip()
def invoke_gemini(prompt):
    res = gemini_model.generate_content(prompt)
    if not res.text:
        raise ValueError("Gemini returned empty response")
    return res.text.strip()