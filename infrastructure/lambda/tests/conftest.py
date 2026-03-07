import sys
import os
import pytest

# Add paths to sys.path so we can import from functions and shared
base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
functions_dir = os.path.join(base_dir, 'functions')
shared_layer_dir = os.path.join(base_dir, 'layers', 'shared', 'python')

sys.path.insert(0, shared_layer_dir)
sys.path.insert(0, functions_dir)

# Set common dummy env vars
os.environ['AWS_REGION'] = 'us-east-1'
os.environ['TRANSLATION_HISTORY_TABLE'] = 'mock-history'
os.environ['SAVED_TRANSLATIONS_TABLE'] = 'mock-saved'
os.environ['USER_PREFERENCES_TABLE'] = 'mock-prefs'
os.environ['EXPORT_BUCKET'] = 'mock-bucket'
os.environ['BEDROCK_MODEL_ID'] = 'mock-model'

@pytest.fixture
def mock_context():
    class Context:
        def __init__(self):
            self.aws_request_id = 'test-request-123'
    return Context()
