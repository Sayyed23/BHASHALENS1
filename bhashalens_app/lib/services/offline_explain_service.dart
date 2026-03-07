import 'package:bhashalens_app/models/detected_intent.dart';
import 'package:bhashalens_app/models/explanation_result.dart';
import 'package:bhashalens_app/services/rule_engine.dart';
import 'package:bhashalens_app/services/template_service.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';

/// Main service for offline explanations.
/// Combines rule engine and template service for fully offline operation.
class OfflineExplainService {
  final RuleEngine _ruleEngine;
  final TemplateService _templateService;
  final MlKitTranslationService _mlKit;

  OfflineExplainService()
      : _ruleEngine = RuleEngine(),
        _templateService = TemplateService(),
        _mlKit = MlKitTranslationService();

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
    String targetLanguage = 'English',
  }) async {
    final result = await explain(text, userContext: userContext);
    final map = result.toContextDataMap();

    // If target is English, return as is (templates are in English)
    if (targetLanguage.toLowerCase() == 'english' || targetLanguage == 'en') {
      return map;
    }

    // Attempt to localize using ML Kit
    try {
      final langCode = _getLanguageCode(targetLanguage);
      
      // Identify source language for the input text
      final sourceLangCode = await _mlKit.identifyLanguage(text);
      
      // 1. Translate the input text itself to provide "dynamic" content
      // If we can't identify or it's same as target, translation is just the text
      String? translatedInput;
      if (sourceLangCode != 'und' && sourceLangCode != langCode) {
        translatedInput = await _mlKit.translate(
          text: text,
          sourceLanguage: sourceLangCode,
          targetLanguage: langCode,
        );
      } else {
        translatedInput = text;
      }

      // 2. Translate the explanation fields (they are in English in templates)
      final translatedMeaning = await _mlKit.translate(
        text: map['meaning'] ?? '',
        sourceLanguage: 'en',
        targetLanguage: langCode,
      );

      final translatedAnalysis = await _mlKit.translate(
        text: 'This text is about ${map['meaning']?.toLowerCase() ?? 'information'}.',
        sourceLanguage: 'en',
        targetLanguage: langCode,
      );

      if (translatedInput != null) map['translation'] = translatedInput;
      if (translatedMeaning != null) map['meaning'] = translatedMeaning;
      if (translatedAnalysis != null) map['analysis'] = translatedAnalysis;

      // Translate tone and other small strings if needed
      final translatedTone = await _mlKit.translate(
        text: map['tone'] ?? 'Neutral',
        sourceLanguage: 'en',
        targetLanguage: langCode,
      );
      if (translatedTone != null) map['tone'] = translatedTone;

    } catch (e) {
      // Fallback to English if translation fails
    }

    return map;
  }

  Future<Map<String, dynamic>> simplifyAsMap(
    String text, {
    String targetLanguage = 'English',
  }) async {
    final map = await explainAsMap(text, targetLanguage: targetLanguage);

    // In "Simplify" mode, we prioritize the "Meaning" as the primary simplified text
    // and provide a slightly different structure.
    return {
      'simplified_text': map['meaning'] ?? text,
      'explanation':
          map['cultural_insight'] ?? 'No additional explanation available offline.',
      'key_points': map['situational_context'] ?? [],
      'tone': map['tone'] ?? 'Neutral',
      '_offline': true,
    };
  }

  String _getLanguageCode(String name) {
    switch (name.toLowerCase()) {
      case 'hindi': return 'hi';
      case 'marathi': return 'mr';
      case 'bengali': return 'bn';
      case 'tamil': return 'ta';
      case 'telugu': return 'te';
      case 'gujarati': return 'gu';
      case 'kannada': return 'kn';
      case 'urdu': return 'ur';
      case 'spanish': return 'es';
      case 'french': return 'fr';
      case 'german': return 'de';
      default: return 'en';
    }
  }

  /// Quick analyze without full explanation (for preview/debug)
  DetectedIntent analyze(String text, {ContextType? userContext}) {
    return _ruleEngine.analyze(text, userContext: userContext);
  }
}
