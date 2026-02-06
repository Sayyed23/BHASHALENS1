import 'package:bhashalens_app/models/detected_intent.dart';
import 'package:bhashalens_app/models/explanation_result.dart';
import 'package:bhashalens_app/services/rule_engine.dart';
import 'package:bhashalens_app/services/template_service.dart';
import 'package:bhashalens_app/services/gemma_service.dart';

/// Main service for offline explanations.
/// Combines rule engine and template service for fully offline operation.
/// Optionally uses Gemma for enhanced explanations when available.
class OfflineExplainService {
  final RuleEngine _ruleEngine;
  final TemplateService _templateService;
  final GemmaService? _gemmaService;

  OfflineExplainService({GemmaService? gemmaService})
      : _ruleEngine = RuleEngine(),
        _templateService = TemplateService(),
        _gemmaService = gemmaService;

  /// Generate an explanation for the given text.
  /// Works entirely offline using rule-based analysis and templates.
  /// Optionally enhanced by Gemma if available and enabled.
  Future<ExplanationResult> explain(
    String text, {
    ContextType? userContext,
  }) async {
    // 1. Analyze text with rule engine
    final intent = _ruleEngine.analyze(text, userContext: userContext);

    // 2. Generate base explanation from templates
    var result = _templateService.generate(intent);

    // 3. Optionally enhance with Gemma
    if (_gemmaService != null && _gemmaService.isEnabled) {
      final contextName = _getContextName(intent.context);
      final enhanced =
          await _gemmaService.simplifyText(text, context: contextName);

      if (enhanced != null) {
        // Replace meaning with Gemma-enhanced version
        result = ExplanationResult(
          meaning: enhanced,
          usage: result.usage,
          toneDescription: result.toneDescription,
          suggestions: result.suggestions,
          culturalNote: result.culturalNote,
          safetyNote: result.safetyNote,
          offlineGenerated: true,
          timestamp: DateTime.now(),
          detectedIntent: intent,
        );
      }
    }

    return result;
  }

  /// Generate explanation and return as Map for UI compatibility
  Future<Map<String, dynamic>> explainAsMap(
    String text, {
    ContextType? userContext,
  }) async {
    final result = await explain(text, userContext: userContext);
    return result.toContextDataMap();
  }

  /// Quick analyze without full explanation (for preview/debug)
  DetectedIntent analyze(String text, {ContextType? userContext}) {
    return _ruleEngine.analyze(text, userContext: userContext);
  }

  String _getContextName(ContextType context) {
    switch (context) {
      case ContextType.hospital:
        return 'Hospital';
      case ContextType.office:
        return 'Office';
      case ContextType.travel:
        return 'Travel';
      case ContextType.publicPlace:
        return 'Public Place';
      case ContextType.legal:
        return 'Legal';
      case ContextType.dailyLife:
        return 'Daily Life';
      case ContextType.unknown:
        return 'General';
    }
  }
}
