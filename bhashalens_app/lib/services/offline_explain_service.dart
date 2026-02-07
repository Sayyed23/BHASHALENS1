import 'package:bhashalens_app/models/detected_intent.dart';
import 'package:bhashalens_app/models/explanation_result.dart';
import 'package:bhashalens_app/services/rule_engine.dart';
import 'package:bhashalens_app/services/template_service.dart';

/// Main service for offline explanations.
/// Combines rule engine and template service for fully offline operation.
class OfflineExplainService {
  final RuleEngine _ruleEngine;
  final TemplateService _templateService;

  OfflineExplainService()
      : _ruleEngine = RuleEngine(),
        _templateService = TemplateService();

  /// Generate an explanation for the given text.
  /// Works entirely offline using rule-based analysis and templates.
  Future<ExplanationResult> explain(
    String text, {
    ContextType? userContext,
  }) async {
    // 1. Analyze text with rule engine
    final intent = _ruleEngine.analyze(text, userContext: userContext);

    // 2. Generate base explanation from templates
    var result = _templateService.generate(intent);

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
}
