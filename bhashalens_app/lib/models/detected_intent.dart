/// Intent types detected from text analysis
enum IntentType {
  question,
  request,
  warning,
  statement,
  unknown,
}

/// Tone types detected from text analysis
enum ToneType {
  urgent,
  polite,
  neutral,
  formal,
  casual,
}

/// Context types for situational awareness
enum ContextType {
  hospital,
  office,
  travel,
  publicPlace,
  dailyLife,
  legal,
  unknown,
}

/// Sensitivity levels for content handling
enum SensitivityLevel {
  general,
  medical,
  legal,
}

/// Represents the detected intent and context from rule-based analysis
class DetectedIntent {
  final IntentType intent;
  final ToneType tone;
  final ContextType context;
  final SensitivityLevel sensitivity;
  final double confidence; // 0.0 to 1.0

  const DetectedIntent({
    required this.intent,
    required this.tone,
    required this.context,
    required this.sensitivity,
    required this.confidence,
  });

  /// Returns true if confidence is high enough for specific templates
  bool get isHighConfidence => confidence >= 0.7;

  /// Returns true if confidence is medium (use blended templates)
  bool get isMediumConfidence => confidence >= 0.4 && confidence < 0.7;

  /// Returns true if confidence is low (use generic templates only)
  bool get isLowConfidence => confidence < 0.4;

  @override
  String toString() {
    return 'DetectedIntent(intent: $intent, tone: $tone, context: $context, '
        'sensitivity: $sensitivity, confidence: ${confidence.toStringAsFixed(2)})';
  }
}
