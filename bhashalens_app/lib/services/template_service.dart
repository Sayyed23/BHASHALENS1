import 'package:bhashalens_app/data/explanation_templates.dart';
import 'package:bhashalens_app/models/detected_intent.dart';
import 'package:bhashalens_app/models/explanation_result.dart';

/// Service for generating explanations from templates based on detected intent.
/// Works entirely offline with deterministic, safe outputs.
class TemplateService {
  /// Generate an explanation result from detected intent
  ExplanationResult generate(DetectedIntent intent) {
    // Select templates based on confidence level
    if (intent.isHighConfidence) {
      return _generateSpecificExplanation(intent);
    } else if (intent.isMediumConfidence) {
      return _generateBlendedExplanation(intent);
    } else {
      return _generateGenericExplanation(intent);
    }
  }

  /// High confidence: Use specific templates
  ExplanationResult _generateSpecificExplanation(DetectedIntent intent) {
    final contextTemplate =
        ExplanationTemplates.contextTemplates[intent.context] ??
            ExplanationTemplates.contextTemplates[ContextType.dailyLife]!;

    // Build meaning with context awareness
    String meaning = ExplanationTemplates.meaningTemplates[intent.intent] ??
        ExplanationTemplates.genericTemplates['meaning']!;

    // If context is specific, add context meaning
    if (intent.context != ContextType.dailyLife &&
        intent.context != ContextType.unknown) {
      meaning = '${contextTemplate['meaning']} $meaning';
    }

    // Build usage
    String usage = ExplanationTemplates.usageTemplates[intent.intent] ??
        ExplanationTemplates.genericTemplates['usage']!;

    // Build tone description
    String toneDesc = ExplanationTemplates.toneTemplates[intent.tone] ??
        ExplanationTemplates.genericTemplates['tone']!;

    // Build suggestions (combine intent + context suggestions)
    List<String> suggestions = [
      ...ExplanationTemplates.suggestedQuestions[intent.intent] ?? [],
    ];

    // Add context-specific suggestions if context is specific
    if (intent.context != ContextType.dailyLife &&
        intent.context != ContextType.unknown) {
      final contextSuggestions =
          ExplanationTemplates.contextSuggestions[intent.context];
      if (contextSuggestions != null && contextSuggestions.isNotEmpty) {
        suggestions.add(contextSuggestions.first);
      }
    }

    // Limit to 3 suggestions
    if (suggestions.length > 3) {
      suggestions = suggestions.take(3).toList();
    }

    // Get cultural/context note
    String? culturalNote = contextTemplate['note'];

    // Get safety note based on sensitivity
    String? safetyNote =
        ExplanationTemplates.sensitivityNotes[intent.sensitivity];

    return ExplanationResult(
      meaning: meaning,
      usage: usage,
      toneDescription: toneDesc,
      suggestions: suggestions,
      culturalNote: culturalNote,
      safetyNote: safetyNote,
      offlineGenerated: true,
      timestamp: DateTime.now(),
      detectedIntent: intent,
    );
  }

  /// Medium confidence: Blend specific with generic
  ExplanationResult _generateBlendedExplanation(DetectedIntent intent) {
    // Use intent-specific meaning but generic context
    String meaning = ExplanationTemplates.meaningTemplates[intent.intent] ??
        ExplanationTemplates.genericTemplates['meaning']!;

    // Use generic usage
    String usage = ExplanationTemplates.usageTemplates[intent.intent] ??
        ExplanationTemplates.genericTemplates['usage']!;

    // Use tone description
    String toneDesc = ExplanationTemplates.toneTemplates[intent.tone] ??
        ExplanationTemplates.genericTemplates['tone']!;

    // Use intent suggestions only
    List<String> suggestions =
        ExplanationTemplates.suggestedQuestions[intent.intent] ??
            ExplanationTemplates.suggestedQuestions[IntentType.unknown]!;

    // Limit to 2 suggestions for medium confidence
    if (suggestions.length > 2) {
      suggestions = suggestions.take(2).toList();
    }

    // Get safety note based on sensitivity (important even at medium confidence)
    String? safetyNote =
        ExplanationTemplates.sensitivityNotes[intent.sensitivity];

    return ExplanationResult(
      meaning: meaning,
      usage: usage,
      toneDescription: toneDesc,
      suggestions: suggestions,
      culturalNote: null,
      safetyNote: safetyNote,
      offlineGenerated: true,
      timestamp: DateTime.now(),
      detectedIntent: intent,
    );
  }

  /// Low confidence: Use only generic templates
  ExplanationResult _generateGenericExplanation(DetectedIntent intent) {
    // Get safety note based on sensitivity (always important)
    String? safetyNote =
        ExplanationTemplates.sensitivityNotes[intent.sensitivity];

    return ExplanationResult(
      meaning: ExplanationTemplates.genericTemplates['meaning']!,
      usage: ExplanationTemplates.genericTemplates['usage']!,
      toneDescription: ExplanationTemplates.genericTemplates['tone']!,
      suggestions: ExplanationTemplates.suggestedQuestions[IntentType.unknown]!,
      culturalNote: null,
      safetyNote: safetyNote,
      offlineGenerated: true,
      timestamp: DateTime.now(),
      detectedIntent: intent,
    );
  }
}
