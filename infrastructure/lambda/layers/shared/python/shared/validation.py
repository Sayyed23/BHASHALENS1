"""
Shared Input Validation utility
"""
import json
from typing import Dict, Any, Tuple

def validate_required_fields(body: Dict[str, Any], required_fields: list) -> Tuple[bool, str]:
    """Validate that all required fields are present and non-empty in the body"""
    missing = []
    for field in required_fields:
        val = body.get(field)
        if val is None or (isinstance(val, str) and not val.strip()):
            missing.append(field)
            
    if missing:
        return False, f"Missing or empty required fields: {', '.join(missing)}"
    return True, ""

def validate_text_length(text: str, max_length: int = 5000) -> Tuple[bool, str]:
    """Validate that text doesn't exceed the maximum length"""
    if not text:
        return True, ""
    if len(text) > max_length:
        return False, f"Text length ({len(text)}) exceeds maximum allowed ({max_length} characters)"
    return True, ""

def safe_parse_body(event: Dict[str, Any]) -> Tuple[Dict[str, Any], str]:
    """Safely parse JSON body from API Gateway event"""
    body = event.get('body', {})
    if isinstance(body, str):
        try:
            body = json.loads(body)
        except json.JSONDecodeError:
            return {}, "Invalid JSON in request body"
    elif body is None:
        body = {}
    return body, ""
