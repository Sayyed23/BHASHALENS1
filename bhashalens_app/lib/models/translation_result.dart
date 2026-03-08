import 'translation_history_entry.dart';

/// Result of a translation operation
class TranslationResult {
  final String translatedText;
  final double confidence;
  final int processingTimeMs;
  final ProcessingBackend backend;
  final bool success;
  final String? error;

  TranslationResult({
    required this.translatedText,
    required this.confidence,
    required this.processingTimeMs,
    required this.backend,
    this.success = true,
    this.error,
  });

  factory TranslationResult.failure({
    required String error,
    required ProcessingBackend backend,
    required int processingTimeMs,
  }) {
    return TranslationResult(
      translatedText: '',
      confidence: 0.0,
      processingTimeMs: processingTimeMs,
      backend: backend,
      success: false,
      error: error,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'translated_text': translatedText,
      'confidence': confidence,
      'processing_time_ms': processingTimeMs,
      'backend': backend.name,
      'success': success,
      'error': error,
    };
  }

  factory TranslationResult.fromMap(Map<String, dynamic> map) {
    return TranslationResult(
      translatedText: map['translated_text'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      processingTimeMs: map['processing_time_ms'] as int,
      backend: ProcessingBackend.values.firstWhere(
        (e) => e.name == map['backend'],
        orElse: () => ProcessingBackend.mlKit,
      ),
      success: map['success'] as bool? ?? true,
      error: map['error'] as String?,
    );
  }
}
