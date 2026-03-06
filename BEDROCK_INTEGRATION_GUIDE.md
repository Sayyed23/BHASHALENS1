# AWS Bedrock Integration Guide for Assist, Explain & Simplify Modes

## Overview

This guide explains how to integrate AWS Bedrock AI into the BhashaLens app's Assist, Explain, and Simplify modes for both web and mobile (APK) platforms.

## Current Status

✅ **Already Implemented:**
- AWS Cloud Service with Bedrock integration (`aws_cloud_service.dart`)
- API Gateway endpoints for `/assist` and `/simplify`
- Lambda functions for processing requests
- Circuit breaker for fault tolerance
- Fallback mechanisms

❌ **Needs Implementation:**
- Update Explain Mode to use AWS Bedrock
- Update Assistant Mode to use AWS Bedrock
- Create Simplify Mode page
- Add backend indicators in UI
- Test cross-platform functionality

## Architecture

```
User Input → Flutter App → Hybrid Service → AWS Cloud Service → API Gateway → Lambda → Bedrock
                                ↓ (fallback)
                              Gemini Service
                                ↓ (fallback)
                              Offline Service
```

## Implementation Steps

### Step 1: Update Explain Mode to Use AWS Bedrock

**File:** `bhashalens_app/lib/pages/explain_mode_page.dart`

**Current Implementation:**
- Uses `HybridTranslationService.explainText()` which calls Gemini
- Has offline fallback

**Required Changes:**
1. Update `_explainWithContext()` method to use AWS Bedrock first
2. Add backend indicator showing which service is being used
3. Improve error handling and loading states



**Implementation Code:**

```dart
// In _explainWithContext() method, replace the online section with:

if (!isOffline) {
  // Try AWS Bedrock first
  final awsService = Provider.of<AwsCloudService>(context, listen: false);
  
  if (awsService.isAvailable) {
    try {
      final result = await awsService.explainText(
        text: text,
        targetLanguage: _selectedOutputLanguage.toLowerCase().substring(0, 2),
        sourceLanguage: _selectedInputLanguage == 'Auto-detected'
            ? null
            : _selectedInputLanguage.toLowerCase().substring(0, 2),
        userId: null, // Add user ID if authenticated
      );

      if (mounted) {
        setState(() {
          _contextData = result;
          _contextData!['_backend'] = 'bedrock'; // Add backend indicator
        });
      }
      return;
    } catch (e) {
      debugPrint('AWS Bedrock failed, falling back to Gemini: $e');
    }
  }
  
  // Fallback to Gemini
  try {
    final hybridService = Provider.of<HybridTranslationService>(context, listen: false);
    final result = await hybridService.explainText(
      text: text,
      targetLanguage: _selectedOutputLanguage.toLowerCase().substring(0, 2),
      sourceLanguage: _selectedInputLanguage == 'Auto-detected'
          ? null
          : _selectedInputLanguage.toLowerCase().substring(0, 2),
    );

    if (mounted) {
      setState(() {
        _contextData = result;
        _contextData!['_backend'] = 'gemini'; // Add backend indicator
      });
    }
  } catch (e) {
    // Final fallback to offline
    final offlineService = OfflineExplainService();
    final result = await offlineService.explainAsMap(text);
    result['_offline'] = true;
    result['_backend'] = 'offline';

    if (mounted) {
      setState(() {
        _contextData = result;
      });
    }
  }
}
```

### Step 2: Update Assistant Mode to Use AWS Bedrock

**File:** `bhashalens_app/lib/pages/assistant_mode_page.dart`

**Current Implementation:**
- Uses `AwsCloudService` for basic guide and roleplay start
- Uses `HybridTranslationService.chat()` for conversation

**Required Changes:**
1. Update `_sendMessage()` to use AWS Bedrock first
2. Add backend indicator
3. Improve error handling

**Implementation Code:**

```dart
// In _sendMessage() method, replace the service call with:

Future<void> _sendMessage() async {
  final text = _chatController.text.trim();
  if (text.isEmpty) return;

  setState(() {
    _chatMessages.add({'role': 'me', 'text': text});
    _chatController.clear();
  });

  // Scroll to bottom
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });

  try {
    final awsService = Provider.of<AwsCloudService>(context, listen: false);
    
    // Try AWS Bedrock first
    if (awsService.isAvailable) {
      try {
        // Convert chat history to AWS format
        final history = _chatMessages.map((m) => {
          'role': m['role'] == 'me' ? 'user' : 'assistant',
          'content': m['text'] as String
        }).toList();

        final response = await awsService.practiceConversation(
          userMessage: text,
          language: 'en', // Or get from user preferences
          conversationHistory: history,
          userId: null,
        );

        if (response.success && mounted) {
          setState(() {
            _chatMessages.add({
              'role': 'other',
              'text': response.response,
              '_backend': 'bedrock',
            });
          });
          _scrollToBottom();
          return;
        }
      } catch (e) {
        debugPrint('AWS Bedrock failed, falling back to Gemini: $e');
      }
    }

    // Fallback to Gemini via HybridTranslationService
    final hybridService = Provider.of<HybridTranslationService>(context, listen: false);
    final history = _chatMessages.map((m) => {
      'role': m['role'] == 'me' ? 'user' : 'assistant',
      'content': m['text'] as String
    }).toList();

    final response = await hybridService.chat(message: text, history: history);
    
    if (mounted) {
      setState(() {
        _chatMessages.add({
          'role': 'other',
          'text': response,
          '_backend': 'gemini',
        });
      });
      _scrollToBottom();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}

void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}
```

### Step 3: Create Simplify Mode Page

**File:** `bhashalens_app/lib/pages/simplify_mode_page.dart`

Create a new page for text simplification with AWS Bedrock integration.



### Step 4: Add Backend Indicator Widget

**File:** `bhashalens_app/lib/widgets/backend_indicator.dart`

Create a reusable widget to show which backend is being used.

```dart
import 'package:flutter/material.dart';

class BackendIndicator extends StatelessWidget {
  final String backend; // 'bedrock', 'gemini', 'offline'
  final bool isDismissible;
  final VoidCallback? onDismiss;

  const BackendIndicator({
    super.key,
    required this.backend,
    this.isDismissible = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getBackendConfig(backend);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config['color'].withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'],
            size: 16,
            color: config['color'],
          ),
          const SizedBox(width: 6),
          Text(
            config['label'],
            style: TextStyle(
              color: config['color'],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isDismissible) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 14,
                color: config['color'].withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getBackendConfig(String backend) {
    switch (backend.toLowerCase()) {
      case 'bedrock':
        return {
          'label': 'Powered by AWS Bedrock',
          'icon': Icons.cloud,
          'color': const Color(0xFF136DEC), // Blue
        };
      case 'gemini':
        return {
          'label': 'Powered by Gemini',
          'icon': Icons.auto_awesome,
          'color': const Color(0xFFFF6B35), // Orange
        };
      case 'offline':
        return {
          'label': 'Offline Mode',
          'icon': Icons.offline_bolt,
          'color': const Color(0xFF9DA8B9), // Grey
        };
      default:
        return {
          'label': 'Unknown',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }
}
```

**Usage in Explain Mode:**

```dart
// Add this in the build method where you display results
if (_contextData != null && _contextData!['_backend'] != null)
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: BackendIndicator(
      backend: _contextData!['_backend'],
      onDismiss: () {
        setState(() {
          _contextData!.remove('_backend');
        });
      },
    ),
  ),
```

### Step 5: Update Hybrid Translation Service

**File:** `bhashalens_app/lib/services/hybrid_translation_service.dart`

Add methods to route explain, simplify, and chat requests through AWS first.

```dart
// Add these methods to HybridTranslationService class

/// Explain text with AWS Bedrock fallback to Gemini
Future<Map<String, dynamic>> explainText({
  required String text,
  required String targetLanguage,
  String? sourceLanguage,
  String? userId,
}) async {
  // Try AWS Bedrock first
  if (_awsService.isAvailable) {
    try {
      final result = await _awsService.explainText(
        text: text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
        userId: userId,
      );
      result['_backend'] = 'bedrock';
      return result;
    } catch (e) {
      debugPrint('AWS Bedrock explain failed, falling back to Gemini: $e');
    }
  }

  // Fallback to Gemini
  try {
    final result = await _geminiService.explainText(
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
    );
    result['_backend'] = 'gemini';
    return result;
  } catch (e) {
    debugPrint('Gemini explain failed: $e');
    rethrow;
  }
}

/// Simplify text with AWS Bedrock fallback to Gemini
Future<Map<String, dynamic>> simplifyText({
  required String text,
  required String targetComplexity,
  required String language,
  bool includeExplanation = false,
  String? userId,
}) async {
  // Try AWS Bedrock first
  if (_awsService.isAvailable) {
    try {
      final result = await _awsService.simplifyText(
        text: text,
        targetComplexity: targetComplexity,
        language: language,
        includeExplanation: includeExplanation,
        userId: userId,
      );
      
      return {
        'simplified_text': result.simplifiedText,
        'explanation': result.explanation,
        'complexity_reduction': result.complexityReduction,
        '_backend': 'bedrock',
      };
    } catch (e) {
      debugPrint('AWS Bedrock simplify failed, falling back to Gemini: $e');
    }
  }

  // Fallback to Gemini
  try {
    final result = await _geminiService.simplifyText(
      text: text,
      targetComplexity: targetComplexity,
      language: language,
      includeExplanation: includeExplanation,
    );
    result['_backend'] = 'gemini';
    return result;
  } catch (e) {
    debugPrint('Gemini simplify failed: $e');
    rethrow;
  }
}

/// Chat with AWS Bedrock fallback to Gemini
Future<String> chat({
  required String message,
  required List<Map<String, String>> history,
  String? userId,
}) async {
  // Try AWS Bedrock first
  if (_awsService.isAvailable) {
    try {
      final result = await _awsService.practiceConversation(
        userMessage: message,
        language: 'en', // Or get from preferences
        conversationHistory: history,
        userId: userId,
      );
      
      if (result.success) {
        return result.response;
      }
    } catch (e) {
      debugPrint('AWS Bedrock chat failed, falling back to Gemini: $e');
    }
  }

  // Fallback to Gemini
  try {
    return await _geminiService.chat(
      message: message,
      history: history,
    );
  } catch (e) {
    debugPrint('Gemini chat failed: $e');
    rethrow;
  }
}
```

### Step 6: Testing Checklist

#### Web Testing
- [ ] Open web app in browser
- [ ] Test Explain Mode with AWS Bedrock
- [ ] Verify backend indicator shows "Powered by AWS Bedrock"
- [ ] Test fallback to Gemini (disable AWS in .env)
- [ ] Test Assistant Mode with AWS Bedrock
- [ ] Test Simplify Mode with AWS Bedrock
- [ ] Check browser console for errors
- [ ] Verify API calls in Network tab

#### Mobile (APK) Testing
- [ ] Build APK: `flutter build apk --release`
- [ ] Install on Android device
- [ ] Test Explain Mode with AWS Bedrock
- [ ] Verify backend indicator shows correctly
- [ ] Test fallback to Gemini (turn off WiFi temporarily)
- [ ] Test Assistant Mode with AWS Bedrock
- [ ] Test Simplify Mode with AWS Bedrock
- [ ] Check logs with `adb logcat`

#### Cross-Platform Verification
- [ ] Same features work on both web and mobile
- [ ] Backend indicators display correctly on both platforms
- [ ] Fallback mechanisms work on both platforms
- [ ] Performance is acceptable on both platforms
- [ ] Error messages are user-friendly on both platforms

### Step 7: Environment Configuration

Ensure your `.env` file has the correct AWS configuration:

```env
# AWS Configuration
AWS_API_GATEWAY_URL=https://e38c3iwchc.execute-api.us-east-1.amazonaws.com
AWS_REGION=us-east-1
AWS_ENABLE_CLOUD=true
```

For web deployment, ensure Amplify environment variables are set in AWS Console.

### Step 8: Monitoring and Debugging

#### CloudWatch Logs
1. Go to AWS CloudWatch Console
2. Navigate to Log Groups
3. Find `/aws/lambda/bhashalens-assistance-dev`
4. Check for errors or performance issues

#### API Gateway Metrics
1. Go to API Gateway Console
2. Select your API
3. View Metrics dashboard
4. Monitor:
   - Request count
   - Latency
   - Error rate (4XX, 5XX)

#### Flutter Debugging
```dart
// Add debug logging in your code
debugPrint('Using backend: ${_contextData!['_backend']}');
debugPrint('AWS Service available: ${awsService.isAvailable}');
debugPrint('Circuit breaker open: ${_circuitBreaker.isOpen}');
```

### Step 9: Performance Optimization

#### Caching
- Implement response caching for frequent requests
- Cache AWS Bedrock responses in local storage
- Set appropriate TTL (Time To Live) for cached data

#### Request Batching
- Batch multiple requests when possible
- Use debouncing for user input

#### Error Recovery
- Implement exponential backoff for retries
- Use circuit breaker to prevent cascading failures
- Provide clear error messages to users

### Step 10: Cost Optimization

#### AWS Bedrock Costs
- Monitor token usage in CloudWatch
- Implement request deduplication
- Cache frequent requests
- Use cheaper models for simple tasks

#### Estimated Costs
- Bedrock Claude 3 Sonnet: ~$0.003 per 1K input tokens, ~$0.015 per 1K output tokens
- Typical explain request: ~500 input + 1000 output tokens = ~$0.017
- 1000 requests/month: ~$17

#### Cost Alerts
Set up budget alerts in AWS:
1. Go to AWS Budgets
2. Create budget for Bedrock usage
3. Set alert at $50, $100, $200

## Troubleshooting

### Issue: AWS Bedrock not responding
**Solution:**
1. Check AWS_ENABLE_CLOUD in .env
2. Verify API Gateway URL is correct
3. Check CloudWatch logs for Lambda errors
4. Verify Bedrock model access in AWS Console

### Issue: Fallback not working
**Solution:**
1. Check circuit breaker status
2. Verify Gemini API key is valid
3. Check error handling in code
4. Add more detailed logging

### Issue: Different behavior on web vs mobile
**Solution:**
1. Check environment variables on both platforms
2. Verify CORS settings for web
3. Check network permissions for mobile
4. Test with same network conditions

## Next Steps

1. Complete Phase 6 tasks in tasks.md
2. Test thoroughly on both web and mobile
3. Monitor AWS costs and performance
4. Gather user feedback
5. Optimize based on usage patterns

## Support

For issues or questions:
1. Check CloudWatch logs
2. Review API Gateway metrics
3. Test with curl/Postman
4. Check Flutter console logs
5. Review this guide

## References

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [AWS API Gateway](https://docs.aws.amazon.com/apigateway/)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
