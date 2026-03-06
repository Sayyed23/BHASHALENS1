"""
Firebase Token Validation Custom Authorizer
"""
import os
import json
import time
import urllib.request
from typing import Dict, Any
import jwt
from jwt.algorithms import RSAAlgorithm
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

FIREBASE_PROJECT_ID = os.environ.get('FIREBASE_PROJECT_ID')
if not FIREBASE_PROJECT_ID:
    raise ValueError("FIREBASE_PROJECT_ID environment variable is required")GOOGLE_CERTS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'

# Simple in-memory cache for public keys
# Lambda reuses execution context, so this cache persists across invocations
_public_keys_cache = {}
_public_keys_cache_time = 0
CACHE_TTL = 3600  # 1 hour

def fetch_public_keys() -> Dict[str, Any]:
    """Fetch public keys from Google and cache them"""
    global _public_keys_cache, _public_keys_cache_time
    
    current_time = time.time()
    if _public_keys_cache and (current_time - _public_keys_cache_time < CACHE_TTL):
        return _public_keys_cache
        
    try:
        req = urllib.request.Request(GOOGLE_CERTS_URL)
        with urllib.request.urlopen(req, timeout=10) as response:
            cert_data = json.loads(response.read().decode('utf-8'))            
            # Convert X509 certs to public keys that PyJWT can use
            public_keys = {}
            for kid, cert in cert_data.items():
                public_keys[kid] = RSAAlgorithm.from_jwk(jwt.PyJWS().get_unverified_header(cert))
                # For basic PyJWT usage with cert strings directly we can just save certs
                # But PyJWT >= 2.0.0 handles x509 cert strings automatically if passed
                
            _public_keys_cache = cert_data
            _public_keys_cache_time = current_time
            return cert_data
    except Exception as e:
        logger.error(f"Failed to fetch Google public keys: {str(e)}")
        raise

def validate_token(token: str) -> Dict[str, Any]:
    """Validate Firebase ID token"""
    try:
        # Get Key ID (kid) from token header
        header = jwt.get_unverified_header(token)
        kid = header.get('kid')
        if not kid:
            raise ValueError("Token missing 'kid' in header")
            
        # Get public keys
        certs = fetch_public_keys()
        cert_str = certs.get(kid)
        
        if not cert_str:
            raise ValueError(f"Unknown key ID (kid): {kid}")
            
        # Convert PEM string to public key
        # PyJWT handles x509 PEM certificate strings directly
        public_key = cert_str.encode('utf-8')
        
        # Verify token
        issuer = f"https://securetoken.google.com/{FIREBASE_PROJECT_ID}"
        decoded_token = jwt.decode(
            token,
            key=public_key,
            algorithms=['RS256'],
            audience=FIREBASE_PROJECT_ID,
            issuer=issuer
        )
        
        return decoded_token
        
    except jwt.ExpiredSignatureError:
        logger.error("Token signature has expired")
        raise
    except jwt.InvalidTokenError as e:
        logger.error(f"Invalid token: {str(e)}")
        raise
    except Exception as e:
        logger.error(f"Token validation error: {str(e)}")
        raise

def generate_policy(principal_id: str, effect: str, resource: str, context: dict = None) -> Dict[str, Any]:
    """Generate API Gateway custom authorizer policy"""
    auth_response = {'principalId': principal_id}
    
    if effect and resource:
        # Extract the API Gateway ARN up to the stage to allow access to all methods
        # resource format: arn:aws:execute-api:region:account:apiId/stage/method/path
        parts = resource.split('/')
        if len(parts) >= 2:
            base_arn = f"{parts[0]}/{parts[1]}/*/*"
        else:
            base_arn = resource
            
        policy_document = {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': base_arn
                }
            ]
        }
        auth_response['policyDocument'] = policy_document
        
    if context:
        # Add custom context that will be available to backend Lambdas
        # API Gateway context only supports string, numeric, or boolean values
        auth_response['context'] = {
            k: v for k, v in context.items() 
            if isinstance(v, (str, int, float, bool))
        }
        
    return auth_response

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for API Gateway Custom Authorizer
    """
    try:
        # Get token from authorization header
        token = event.get('authorizationToken', '')
        if not token:
            logger.error("Missing authorization token")
            raise Exception('Unauthorized')
            
        # Remove 'Bearer ' prefix if present
        if token.lower().startswith('bearer '):
            token = token[7:]
            
        # Validate token
        decoded_token = validate_token(token)
        user_id = decoded_token.get('sub')
        
        if not user_id:
            logger.error("Token missing 'sub' (user ID)")
            raise Exception('Unauthorized')
            
        # Token is valid, generate allow policy
        logger.info(f"Successfully authenticated user: {user_id}")
        logger.info("Successfully authenticated user")
        
        # Pass useful token claims in the context
        custom_context = {
            'userId': user_id,
            'emailVerified': decoded_token.get('email_verified', False),
            'authTime': decoded_token.get('auth_time', 0)
        }        return generate_policy(user_id, 'Allow', event.get('methodArn', ''), custom_context)
        
    except Exception as e:
        logger.error(f"Authorizer failed: {str(e)}")
        # If we raise Exception('Unauthorized'), API Gateway returns 401
        raise Exception('Unauthorized')
