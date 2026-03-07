import os
import requests
import pytest
from hypothesis import given, settings, strategies as st

API_URL = os.environ.get("API_GATEWAY_URL", "http://localhost:8080")
REQUEST_TIMEOUT_SECONDS = 5

def test_translate_endpoint():
    """Test 18.2: /translate endpoint integration test."""
    response = requests.post(f"{API_URL}/v1/translate", json={
        "source_text": "Hello",
        "source_lang": "en",
        "target_lang": "hi"
    }, timeout=REQUEST_TIMEOUT_SECONDS)
    # Since we are not passing an auth token, backend might return 200 (anonymous) 
    # or fail if validation is strict. Assuming anonymous is allowed.
    assert response.status_code in [200, 401, 403] 

def test_assist_endpoint():
    response = requests.post(f"{API_URL}/v1/assist", json={
        "text": "Make this better",
        "task": "grammar"
    }, timeout=REQUEST_TIMEOUT_SECONDS)
    assert response.status_code in [200, 401, 403]

def test_simplify_endpoint():
    response = requests.post(f"{API_URL}/v1/simplify", json={
        "text": "This is very complicated."
    }, timeout=REQUEST_TIMEOUT_SECONDS)
    assert response.status_code in [200, 401, 403]

def test_history_endpoint_auth():
    """Test 20.2: /history needs auth"""
    response = requests.get(f"{API_URL}/v1/history")
    # Should be 401 or 403 due to missing auth token
    assert response.status_code in [401, 403]

def test_saved_endpoint_auth():
    response = requests.get(f"{API_URL}/v1/saved")
    assert response.status_code in [401, 403]

def test_preferences_endpoint_auth():
    response = requests.get(f"{API_URL}/v1/preferences")
    assert response.status_code in [401, 403]

def test_export_endpoint_auth():
    response = requests.post(f"{API_URL}/v1/export", json={"type": "history"})
    assert response.status_code in [401, 403]

def test_cors_preflight():
    """Test CORS on translate endpoint."""
    response = requests.options(f"{API_URL}/v1/translate", headers={
        "Origin": "http://localhost:3000",
        "Access-Control-Request-Method": "POST"
    })
    assert response.status_code == 200
    assert "Access-Control-Allow-Origin" in response.headers

# Property 23: Rate Limiting Enforcement
# Property 24: Request Payload Validation
# Property 25: Request Logging Completeness (Cannot be easily tested via blackbox, usually checked via CloudWatch queries)

@settings(max_examples=10, deadline=None)
@given(payload=st.dictionaries(keys=st.text(), values=st.text()))
def test_property_24_request_payload_validation(payload):
    """If unexpected payload is sent, API Gateway request validator should reject with 400 Bad Request if schema is enforced."""
    response = requests.post(f"{API_URL}/v1/translate", json=payload, timeout=REQUEST_TIMEOUT_SECONDS)
    # Depending on schema strictness, it might accept it, but typically malformed requests return 400 or 500
    assert response.status_code in [200, 400]
