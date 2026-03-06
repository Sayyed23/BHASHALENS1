"""
BhashaLens Assistance Handler Lambda Function
Processes assistance requests using Amazon Bedrock with Gemini fallback
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

BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
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
    logger.info(f"[{request_id}] Assistance request received")
    
    try:
        body, err = safe_parse_body(event)
        if err: return create_response(400, {'error': err})
            
        is_valid, err_msg = validate_required_fields(body, ['request_type', 'text', 'language'])
        if not is_valid: return create_response(400, {'error': err_msg})
            
        request_type = body['request_type']
        text = body['text']
        language = body['language']
        context_text = body.get('context')
        conversation_history = body.get('conversation_history', [])
        
        is_valid_len, err_msg = validate_text_length(text, 5000)
        if not is_valid_len: return create_response(400, {'error': err_msg})
            
        valid_types = ['grammar', 'qa', 'conversation']
        if request_type not in valid_types:
            return create_response(400, {'error': f'Invalid request_type'})

        response_data = None
        bedrock_time_ms = 0
        used_model = ''
        
        if bedrock_cb.is_allowed():
            try:
                bedrock_start = time.time()
                if request_type == 'grammar': response_data = process_grammar_check(text, language, invoke_bedrock)
                elif request_type == 'qa': response_data = process_question_answer(text, language, context_text, invoke_bedrock)
                elif request_type == 'conversation': response_data = process_conversation(text, language, conversation_history, invoke_bedrock)
                if response_data:
                    bedrock_cb.record_success()
                    used_model = BEDROCK_MODEL_ID
                    bedrock_time_ms = int((time.time() - bedrock_start) * 1000)            except Exception as e:
                logger.warning(f"[{request_id}] Bedrock failed: {str(e)}")
                bedrock_cb.record_failure()
                
        if not response_data and gemini_model:
            logger.info(f"[{request_id}] Falling back to Gemini")
            try:
                if request_type == 'grammar': response_data = process_grammar_check(text, language, invoke_gemini)
                elif request_type == 'qa': response_data = process_question_answer(text, language, context_text, invoke_gemini)
                elif request_type == 'conversation': response_data = process_conversation(text, language, conversation_history, invoke_gemini)
                used_model = 'gemini-1.5-flash'
            except Exception as e:
                logger.error(f"[{request_id}] Gemini fallback failed: {str(e)}")
                raise Exception("All backend models failed")
                
        if not response_data:
            raise Exception("Processing failed")
            
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics(f'Assistance_{request_type}', processing_time_ms, True, {'BedrockLatency': bedrock_time_ms} if bedrock_time_ms > 0 else None)
        
        return create_response(200, {
            'response': response_data['response'],
            'metadata': response_data.get('metadata', {}),
            'model': used_model,
            'processing_time_ms': processing_time_ms
        })
        
    except Exception as e:
        processing_time_ms = int((time.time() - start_time) * 1000)
        send_metrics('Assistance_Error', processing_time_ms, False)
        return handle_error(e, context, "Assistance request failed")

def process_grammar_check(text, language, invoker_func):
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    lang_name = lang_map.get(language, language)
    prompt = f'You are a {lang_name} expert. Check for grammar errors. Format as JSON with "corrected_text" and "corrections" list of dicts (original, corrected, explanation):\n\n{text}'
    
    res = invoker_func(prompt)
    try:
        # Strip potential markdown blocks (e.g. ```json )
        if "```" in res:
            res = res.split("```")[1]
            if res.startswith("json\n"): res = res[5:]
        parsed = json.loads(res.strip())
    except:
        parsed = {"corrected_text": res, "corrections": []}
        
    return {'response': parsed.get('corrected_text', text), 'metadata': {'corrections': parsed.get('corrections', [])}}

def process_question_answer(text, language, context, invoker_func):
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    lang_name = lang_map.get(language, language)
    prompt = f'Answer in {lang_name}. Question: {text}'
    if context: prompt += f'\nContext: {context}'
    return {'response': invoker_func(prompt), 'metadata': {'language': lang_name}}

def process_conversation(text, language, history, invoker_func):
    # Depending on invoker, we might just format as a single text prompt for simplicity
    lang_map = {'hi': 'Hindi', 'mr': 'Marathi', 'en': 'English'}
    lang_name = lang_map.get(language, language)
    
    prompt = f"System: You are a friendly {lang_name} practice partner.\n"
    for msg in history[-10:]:
        content = msg.get('content', '')
        if not content:
            continue
        role = "System" if msg.get("role") == "system" else "User" if msg.get("role") == "user" else "Assistant"
        prompt += f"{role}: {content}\n"
    prompt += f"User: {text}\nAssistant:"    
    return {'response': invoker_func(prompt), 'metadata': {'language': lang_name, 'conversation_length': len(history)+1}}

def invoke_bedrock(prompt):
    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 2048, "temperature": 0.7,
    response = bedrock_runtime.invoke_model(modelId=BEDROCK_MODEL_ID, body=json.dumps(request_body))
    response_body = json.loads(response['body'].read())
    content = response_body.get('content', [])
    if not content or 'text' not in content[0]:
        raise ValueError("Unexpected Bedrock response format")
    return content[0]['text'].strip()    response = bedrock_runtime.invoke_model(modelId=BEDROCK_MODEL_ID, body=json.dumps(request_body))
    return json.loads(response['body'].read())['content'][0]['text'].strip()

def invoke_gemini(prompt):
    res = gemini_model.generate_content(prompt)
    return res.text.strip()
