import json
import pytest
from unittest.mock import patch, MagicMock

# Import the handler (since conftest adds functions to sys.path)
import translation_handler

from hypothesis import given, strategies as st

# Property 11: Model Selection Returns Valid Model ID
# Property 12: Fallback Chain Completeness
# Property 13: Response Includes Backend Identifier
# Property 14: Circuit Breaker State Transitions

# Mocking the boto3 and genai calls
@pytest.fixture(autouse=True)
def mock_aws_services(monkeypatch):
    mock_bedrock = MagicMock()
    mock_dynamodb = MagicMock()
    mock_cloudwatch = MagicMock()
    
    # Fake successful Bedrock response
    mock_body = MagicMock()
    mock_body = MagicMock()
    mock_body.read.return_value = json.dumps({
        'content': [{'text': 'Translated text'}],
        'stop_reason': 'end_turn'
    }).encode('utf-8')
    bedrock_response = {'body': mock_body}
    mock_bedrock.invoke_model.return_value = bedrock_response    monkeypatch.setattr(translation_handler, 'bedrock_runtime', mock_bedrock)
    monkeypatch.setattr(translation_handler, 'dynamodb', mock_dynamodb)
    monkeypatch.setattr(translation_handler.shared.logging_utils, 'cloudwatch', mock_cloudwatch)
    
    # Also mock Gemini
    mock_gemini = MagicMock()
    mock_gemini_resp = MagicMock()
    mock_gemini_resp.text = 'Translated by Gemini'
    mock_gemini.generate_content.return_value = mock_gemini_resp
    monkeypatch.setattr(translation_handler, 'gemini_model', mock_gemini)
    
    return {
        'bedrock': mock_bedrock,
        'dynamodb': mock_dynamodb,
        'gemini': mock_gemini
    }

def test_successful_translation(mock_context):
    event = {
        'body': json.dumps({
            'source_text': 'Hello',
            'source_lang': 'en',
            'target_lang': 'hi'
        })
    }
    
    # Reset circuit breaker
    translation_handler.bedrock_cb.record_success()
    
    response = translation_handler.lambda_handler(event, mock_context)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert 'translated_text' in body
    assert body['translated_text'] == 'Translated text'
    # Property 13 check
    assert body['model'] == 'mock-model'

def test_fallback_to_gemini(mock_context, mock_aws_services):
    # Make bedrock raise an error
    mock_aws_services['bedrock'].invoke_model.side_effect = Exception("Bedrock timeout")
    
    event = {
        'body': json.dumps({
            'source_text': 'Hello',
            'source_lang': 'en',
            'target_lang': 'hi'
        })
    }
    
    # Property 12 & 14 Check
    # Force the cb to open after a failure? Well one failure doesn't open it but it does fallback
    translation_handler.bedrock_cb.record_success()
    response = translation_handler.lambda_handler(event, mock_context)
    
    assert response['statusCode'] == 200
    body = json.loads(response['body'])
    assert body['translated_text'] == 'Translated by Gemini'
    assert body['model'] == 'gemini-1.5-flash'
    assert translation_handler.bedrock_cb.failure_count == 1

@given(
    source_text=st.text(min_size=1, max_size=100),
    source_lang=st.sampled_from(['en', 'hi', 'mr']),
    target_lang=st.sampled_from(['en', 'hi', 'mr'])
)
def test_property_translation_response_invariants(source_text, source_lang, target_lang, mock_context):
    event = {
        'body': json.dumps({
            'source_text': source_text,
            'source_lang': source_lang,
            'target_lang': target_lang
        })
    }
    
    translation_handler.bedrock_cb.record_success()
    response = translation_handler.lambda_handler(event, mock_context)
    
    # Property 27: Lambda Response Structure Invariant
    assert response['statusCode'] == 200
    assert 'headers' in response
    assert 'body' in response
    
    body = json.loads(response['body'])
    assert 'translated_text' in body
    assert 'confidence' in body
    assert 'model' in body
    assert 'processing_time_ms' in body
    
    # Property 13: Response Includes Backend Identifier
    assert len(body['model']) > 0
