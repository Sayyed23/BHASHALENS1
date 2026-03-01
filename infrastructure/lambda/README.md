# BhashaLens Lambda Functions

This directory contains AWS Lambda function handlers for the BhashaLens cloud backend.

## Functions

### 1. Translation Handler (`translation_handler.py`)
Processes translation requests using Amazon Bedrock Claude models.

**Endpoint**: `POST /v1/translate`

**Input**:
```json
{
  "source_text": "Text to translate",
  "source_lang": "hi",
  "target_lang": "en",
  "user_id": "optional-user-id"
}
```

**Output**:
```json
{
  "translated_text": "Translated text",
  "confidence": 0.90,
  "model": "anthropic.claude-3-sonnet-20240229-v1:0",
  "processing_time_ms": 1234
}
```

### 2. Assistance Handler (`assistance_handler.py`)
Processes grammar checking, Q&A, and conversation practice requests.

**Endpoint**: `POST /v1/assist`

**Input**:
```json
{
  "request_type": "grammar|qa|conversation",
  "text": "Text to process",
  "language": "hi",
  "context": "optional context",
  "conversation_history": []
}
```

**Output**:
```json
{
  "response": "Response text",
  "metadata": {},
  "processing_time_ms": 1234
}
```

### 3. Simplification Handler (`simplification_handler.py`)
Processes text simplification and explanation requests.

**Endpoint**: `POST /v1/simplify`

**Input**:
```json
{
  "text": "Complex text to simplify",
  "target_complexity": "simple|moderate|complex",
  "language": "hi",
  "explain": true
}
```

**Output**:
```json
{
  "simplified_text": "Simplified text",
  "explanation": "Optional explanation",
  "complexity_reduction": 0.65,
  "processing_time_ms": 1234
}
```

## Environment Variables

All Lambda functions require the following environment variables:

- `AWS_REGION`: AWS region (e.g., `us-east-1`)
- `BEDROCK_MODEL_ID`: Bedrock model ID (default: `anthropic.claude-3-sonnet-20240229-v1:0`)
- `TRANSLATION_HISTORY_TABLE`: DynamoDB table name for translation history (translation handler only)
- `DEBUG`: Set to `true` to include detailed error messages in responses

## Performance Targets

All Lambda functions are optimized to meet the following targets:

- **Response Time**: < 5 seconds (5000ms)
- **Bedrock Latency**: Tracked separately for optimization
- **Error Rate**: < 1%

## Logging

All functions use structured logging with the following format:

```
[request_id] Log message
```

Log levels:
- `INFO`: Normal operation logs
- `WARNING`: Performance issues, validation failures
- `ERROR`: Exceptions and failures

## Metrics

All functions send custom metrics to CloudWatch:

- `ProcessingTime`: Total processing time in milliseconds
- `BedrockLatency`: Bedrock API call latency
- `RequestCount`: Number of requests (success/failure)
- `PerformanceTargetMet`: Whether response time was < 5s

Metrics are namespaced under `BhashaLens` with dimensions:
- `Operation`: Function type (Translation, Assistance_grammar, etc.)
- `Success`: true/false

## Error Handling

All functions implement comprehensive error handling:

1. **Request Validation**: Validates required fields and data types
2. **Bedrock Errors**: Catches and logs Bedrock API failures
3. **DynamoDB Errors**: Non-blocking, logs failures but doesn't fail request
4. **Metrics Errors**: Non-blocking, logs failures but doesn't fail request
5. **Generic Errors**: Catches all exceptions, logs with stack trace

Error responses follow this format:
```json
{
  "error": "Error category",
  "message": "Detailed error message (if DEBUG=true)"
}
```

## Deployment

These functions are deployed using Terraform (see `../terraform/lambda.tf`).

### Manual Deployment

1. Install dependencies:
```bash
pip install -r requirements.txt -t .
```

2. Create deployment package:
```bash
zip -r function.zip .
```

3. Upload to AWS Lambda via AWS CLI or Console

### Terraform Deployment

```bash
cd ../terraform
terraform init
terraform plan
terraform apply
```

## Testing

### Local Testing

Use the AWS SAM CLI for local testing:

```bash
sam local invoke TranslationHandler -e test_events/translation.json
```

### Integration Testing

Test against deployed functions:

```bash
aws lambda invoke \
  --function-name bhashalens-translation-handler \
  --payload '{"body": "{\"source_text\":\"नमस्ते\",\"source_lang\":\"hi\",\"target_lang\":\"en\"}"}' \
  response.json
```

## Security

- All functions use IAM roles with least privilege
- Bedrock access is restricted to specific models
- DynamoDB access is scoped to specific tables
- CloudWatch logging is enabled for audit trails
- CORS headers are configured for API Gateway integration

## Optimization Notes

### Translation Handler
- Dynamic token limits based on input length
- Concise prompts for faster processing
- Confidence scoring based on stop reason
- Async DynamoDB writes (non-blocking)

### Assistance Handler
- Optimized prompts for each request type
- Conversation history limited to last 10 exchanges
- JSON parsing with fallback for grammar checks

### Simplification Handler
- Complexity-based prompt instructions
- Optional explanation generation
- Simplified complexity reduction metric
- Async metrics reporting

## Monitoring

Monitor Lambda functions using:

1. **CloudWatch Logs**: `/aws/lambda/bhashalens-*-handler`
2. **CloudWatch Metrics**: `BhashaLens` namespace
3. **X-Ray Tracing**: Enable for detailed performance analysis
4. **CloudWatch Alarms**: Set up for error rates and latency

## Troubleshooting

### High Latency
- Check Bedrock model availability
- Review CloudWatch metrics for bottlenecks
- Consider using Claude 3 Haiku for faster responses

### Errors
- Check CloudWatch Logs for detailed error messages
- Verify IAM permissions for Bedrock and DynamoDB
- Ensure environment variables are set correctly

### Timeout Issues
- Increase Lambda timeout (current: 30s)
- Optimize Bedrock prompts
- Consider async processing for long-running tasks
