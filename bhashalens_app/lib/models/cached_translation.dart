/// Data model for cached translation results
class CachedTranslation {
  final String translatedText;
  final double confidence;
  final int cachedAt;

  CachedTranslation({
    required this.translatedText,
    required this.confidence,
    required this.cachedAt,
  });

  Map<String, dynamic> toMap({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
  }) {
    return {
      'source_text': sourceText,
      'source_lang': sourceLang,
      'target_lang': targetLang,
      'translated_text': translatedText,
      'confidence': confidence,
      'cached_at': cachedAt,
    };
  }

  factory CachedTranslation.fromMap(Map<String, dynamic> map) {
    return CachedTranslation(
      translatedText: map['translated_text'] as String,
      confidence: map['confidence'] as double,
      cachedAt: map['cached_at'] as int,
    );
  }
}
