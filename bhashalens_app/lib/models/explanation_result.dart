import 'detected_intent.dart';

/// Represents the result of an explanation (offline or online)
class ExplanationResult {
  final String meaning;
  final String usage;
  final String toneDescription;
  final List<String> suggestions;
  final String? culturalNote;
  final String? safetyNote;
  final bool offlineGenerated;
  final DateTime timestamp;
  final DetectedIntent? detectedIntent;

  const ExplanationResult({
    required this.meaning,
    required this.usage,
    required this.toneDescription,
    this.suggestions = const [],
    this.culturalNote,
    this.safetyNote,
    this.offlineGenerated = true,
    required this.timestamp,
    this.detectedIntent,
  });

  /// Convert to Map for storage compatibility with existing UI
  Map<String, dynamic> toContextDataMap() {
    return {
      'meaning': meaning,
      'analysis': meaning, // Alias for existing UI compatibility
      'when_to_use': usage,
      'tone': toneDescription,
      'suggested_questions': suggestions,
      'cultural_insight': culturalNote ?? 'N/A',
      'safety_note': safetyNote,
      'situational_context': [usage],
      'translation': meaning, // Fallback for UI
    };
  }

  /// Create from Map (for loading from storage)
  factory ExplanationResult.fromMap(Map<String, dynamic> map) {
    return ExplanationResult(
      meaning: map['meaning'] ?? map['analysis'] ?? '',
      usage: map['when_to_use'] ?? map['usage'] ?? '',
      toneDescription: map['tone'] ?? 'Neutral',
      suggestions: List<String>.from(map['suggested_questions'] ?? []),
      culturalNote: map['cultural_insight'],
      safetyNote: map['safety_note'],
      offlineGenerated: map['offlineGenerated'] is int
          ? map['offlineGenerated'] == 1
          : (map['offlineGenerated'] ?? true),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toStorageMap() {
    return {
      'meaningText': meaning,
      'usageText': usage,
      'toneText': toneDescription,
      'suggestions': suggestions.join('|||'),
      'culturalNote': culturalNote,
      'safetyNote': safetyNote,
      'offlineGenerated': offlineGenerated ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'ExplanationResult(meaning: $meaning, usage: $usage, '
        'tone: $toneDescription, offline: $offlineGenerated)';
  }
}
