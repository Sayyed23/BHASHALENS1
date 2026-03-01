# AWS Integration for BhashaLens

This document describes the AWS cloud integration for BhashaLens, enabling cloud-augmented translation and language assistance features.

## Overview

BhashaLens uses a hybrid offline-first, cloud-augmented architecture. All features work offline using on-device models (ML Kit, Gemini), with AWS cloud services enhancing capabilities when connectivity is available.

## Architecture

### Components

1. **AWS API Gateway Client** (`aws_api_gateway_client.dart`)
   - HTTP client for AWS API Gateway endpoints
   - Firebase authentication integration
   - Automatic retry with exponential backoff
   - 5-second timeout for cloud requests

2. **AWS Cloud Service** (`aws_cloud_service.dart`)
   - High-level interface for cloud features
   - Translation, grammar checking, Q&A, conversation, simplification
   - Circuit breaker pattern for fault tolerance
   - Graceful fallback on failures

3. **Smart Hybrid Router** (`smart_hybrid_router.dart`)
   - Intelligent routing between on-device and cloud processing
   - Decision based on network, battery, complexity, user preferences
   - Implements routing logic from design document

4. **Hybrid Translation Service** (`hybrid_translation_service.dart`)
   - Unified interface combining on-device and cloud services
   - Automatic fallback from cloud to on-device
   - Transparent to application code

5. **Circuit Breaker** (`circuit_breaker.dart`)
   - Prevents cascading failures
   - Opens after 5 consecutive failures
   - Auto-recovery after 30 seconds

6. **Retry Policy** (`retry_policy.dart`)
   - Exponential backoff retry logic
   - Up to 3 retry attempts
   - Configurable delays and timeouts

## Configuration

### Environment Variables

Add to `.env` file:

```env
# AWS Configuration
AWS_API_GATEWAY_URL=https://your-api-id.execute-api.region.amazonaws.com/production/v1
AWS_REGION=us-east-1
AWS_ENABLE_CLOUD=true
```

### Getting AWS API Gateway URL

After deploying infrastructure with Terraform:

```bash
cd infrastructure/terraform
terraform output api_endpoint
```

Copy the output URL to your `.env` file.

## API Endpoints

The AWS backend exposes three endpoints:

### 1. Translation (`POST /v1/translate`)

**Request:**
```json
{
  "source_text": "Hello world",
  "source_lang": "en",
  "target_lang": "hi",
  "user_id": "optional-user-id"
}
```

**Response:**
```json
{
  "translated_text": "नमस्ते दुनिया",
  "confidence": 0.95,
  "model": "amazon.titan-text-premier-v1:0",
  "processing_time_ms": 1234
}
```

### 2. Assistance (`POST /v1/assist`)

**Request:**
```json
{
  "request_type": "grammar|qa|conversation",
  "text": "User input text",
  "language": "en",
  "context": "optional context",
  "conversation_history": [],
  "user_id": "optional-user-id"
}
```

**Response:**
```json
{
  "response": "AI response text",
  "metadata": {
    "corrections": [],
    "confidence": 0.9,
    "sources": []
  },
  "processing_time_ms": 2345
}
```

### 3. Simplification (`POST /v1/simplify`)

**Request:**
```json
{
  "text": "Complex text to simplify",
  "target_complexity": "simple|moderate",
  "language": "en",
  "explain": true,
  "user_id": "optional-user-id"
}
```

**Response:**
```json
{
  "simplified_text": "Simplified version",
  "explanation": "Optional explanation",
  "complexity_reduction": 0.6,
  "processing_time_ms": 1890
}
```

## Usage

### Basic Translation

```dart
import 'package:bhashalens_app/services/hybrid_translation_service.dart';

final service = HybridTranslationService();

final result = await service.translateText(
  sourceText: 'Hello world',
  sourceLang: 'en',
  targetLang: 'hi',
  userPreference: DataUsagePreference.cellularAllowed,
);

if (result.success) {
  print('Translation: ${result.translatedText}');
  print('Backend: ${result.backend}'); // onDevice or awsCloud
  print('Time: ${result.processingTimeMs}ms');
}
```

### Grammar Checking

```dart
final result = await service.checkGrammar(
  text: 'I has a book',
  language: 'en',
  userPreference: DataUsagePreference.wifiOnly,
);

if (result.success) {
  print('Corrections: ${result.response}');
}
```

### Text Simplification

```dart
final result = await service.simplifyText(
  text: 'The phenomenon of photosynthesis...',
  targetComplexity: 'simple',
  language: 'en',
  includeExplanation: true,
);

if (result.success) {
  print('Simplified: ${result.simplifiedText}');
  print('Explanation: ${result.explanation}');
}
```

## Routing Logic

The Smart Hybrid Router uses the following decision tree:

1. **Network offline** → On-device
2. **User preference: offline-only** → On-device
3. **Battery < 20%** → On-device
4. **User preference: WiFi-only + Cellular network** → On-device
5. **Request complexity: simple** → On-device
6. **Cloud service unavailable** → On-device
7. **Request complexity: complex + Network available** → AWS Cloud
8. **Default (moderate complexity)** → On-device

### Complexity Estimation

- **Simple**: Text < 100 characters, no context
- **Moderate**: Text 100-500 characters or has context
- **Complex**: Text > 500 characters or long text with context

## Authentication

The integration uses Firebase Authentication for user identification:

- Firebase ID tokens are automatically included in requests
- Anonymous usage is supported (no auth token)
- Tokens are refreshed automatically

## Error Handling

### Circuit Breaker

- Opens after 5 consecutive failures
- Prevents requests when open (fail fast)
- Automatically attempts recovery after 30 seconds
- Transitions to half-open for testing

### Retry Policy

- Up to 3 retry attempts
- Exponential backoff: 1s, 2s, 4s
- Retries on network errors and 5xx responses
- Does not retry on 4xx client errors

### Fallback Strategy

All cloud operations gracefully fall back to on-device processing:

1. Cloud request fails or times out
2. Automatic fallback to ML Kit (translation) or Gemini (LLM)
3. User experience is uninterrupted

## Performance

### Timeouts

- **Request timeout**: 5 seconds
- **Connection timeout**: 3 seconds
- **Circuit breaker reset**: 30 seconds

### Latency Targets

- **Cloud translation**: < 5 seconds
- **On-device translation**: < 1 second
- **Cloud LLM**: < 5 seconds
- **On-device LLM**: < 3 seconds

## Testing

### Unit Tests

Test individual components:

```dart
// Test API client
final client = AwsApiGatewayClient(
  baseUrl: 'https://test-api.example.com',
  httpClient: mockHttpClient,
);

// Test router
final router = SmartHybridRouter(
  cloudService: mockCloudService,
  connectivity: mockConnectivity,
);

// Test circuit breaker
final breaker = CircuitBreaker(
  name: 'test',
  failureThreshold: 3,
);
```

### Integration Tests

Test end-to-end flows:

```dart
testWidgets('Cloud translation with fallback', (tester) async {
  // Simulate cloud failure
  when(mockCloudService.translateText(...))
      .thenThrow(AwsApiException('Network error'));
  
  // Should fall back to on-device
  final result = await service.translateText(...);
  
  expect(result.success, true);
  expect(result.backend, ProcessingBackend.onDevice);
});
```

## Monitoring

### Circuit Breaker Status

```dart
final registry = CircuitBreakerRegistry();
final status = registry.getStatus();

print('Circuit breakers: $status');
// Output: {aws-cloud-service: closed}
```

### Performance Metrics

All operations return processing time:

```dart
final result = await service.translateText(...);
print('Processing time: ${result.processingTimeMs}ms');
print('Backend used: ${result.backend}');
```

## Troubleshooting

### Cloud requests always fail

1. Check `.env` configuration:
   - `AWS_API_GATEWAY_URL` is correct
   - `AWS_ENABLE_CLOUD=true`

2. Verify network connectivity:
   ```dart
   final status = await router.getNetworkStatus();
   print('Network: $status');
   ```

3. Check circuit breaker state:
   ```dart
   final breaker = CircuitBreakerRegistry().get('aws-cloud-service');
   print('Circuit state: ${breaker?.state}');
   ```

### Circuit breaker stuck open

Reset manually:

```dart
final registry = CircuitBreakerRegistry();
registry.resetAll();
```

### Authentication errors

Ensure Firebase user is authenticated:

```dart
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  final token = await user.getIdToken();
  print('Token: ${token?.substring(0, 20)}...');
}
```

## Security

### HTTPS Enforcement

All requests use HTTPS. HTTP requests will fail.

### Authentication

- Firebase ID tokens are included in `Authorization` header
- Tokens are automatically refreshed
- Anonymous usage is supported

### Data Privacy

- User data is only sent to cloud with consent
- Voice recordings are never sent to cloud
- Translation history sync requires opt-in

## Cost Optimization

### Minimize Cloud Usage

1. Set user preference to `wifiOnly` or `offlineOnly`
2. Reduce complexity threshold for cloud routing
3. Increase battery threshold (default: 20%)

### Monitor Usage

Track backend usage:

```dart
int cloudRequests = 0;
int onDeviceRequests = 0;

final result = await service.translateText(...);
if (result.backend == ProcessingBackend.awsCloud) {
  cloudRequests++;
} else {
  onDeviceRequests++;
}

print('Cloud: $cloudRequests, On-device: $onDeviceRequests');
```

## Future Enhancements

- [ ] Battery level detection (requires `battery_plus` package)
- [ ] Sync manager for preferences and history
- [ ] Language pack downloads from S3
- [ ] CloudWatch metrics integration
- [ ] A/B testing for routing strategies

## References

- [Design Document](../.kiro/specs/bhashalens-production-ready/design.md)
- [Requirements Document](../.kiro/specs/bhashalens-production-ready/requirements.md)
- [AWS Infrastructure](../infrastructure/README.md)
- [Lambda Functions](../infrastructure/lambda/)
