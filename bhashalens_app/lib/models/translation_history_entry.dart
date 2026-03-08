import 'language_pair.dart';

/// Data model for translation history entries
class TranslationHistoryEntry {
  final int? id;
  final String sourceText;
  final String translatedText;
  final Language sourceLang;
  final Language targetLang;
  final TranslationMode mode;
  final ProcessingBackend backend;
  final double? confidence;
  final int timestamp;
  final bool isFavorite;

  TranslationHistoryEntry({
    this.id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.mode,
    required this.backend,
    this.confidence,
    required this.timestamp,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_text': sourceText,
      'translated_text': translatedText,
      'source_lang': sourceLang.name,
      'target_lang': targetLang.name,
      'mode': mode.name,
      'backend': backend.name,
      'confidence': confidence,
      'timestamp': timestamp,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory TranslationHistoryEntry.fromMap(Map<String, dynamic> map) {
    return TranslationHistoryEntry(
      id: map['id'] as int?,
      sourceText: map['source_text'] as String,
      translatedText: map['translated_text'] as String,
      sourceLang: _parseLanguage(map['source_lang']),
      targetLang: _parseLanguage(map['target_lang']),
      mode: TranslationMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => TranslationMode.text,
      ),
      backend: _parseBackend(map['backend']),
      confidence: map['confidence'] as double?,
      timestamp: map['timestamp'] as int,
      isFavorite: (map['is_favorite'] as int) == 1,
    );
  }

  static ProcessingBackend _parseBackend(dynamic value) {
    if (value is String) {
      if (value == 'onDevice' || value == 'ml_kit') return ProcessingBackend.mlKit;
      if (value == 'awsCloud' || value == 'aws_bedrock') return ProcessingBackend.gemini;
      if (value == 'gemini') return ProcessingBackend.gemini;
      
      return ProcessingBackend.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ProcessingBackend.mlKit,
      );
    }
    return ProcessingBackend.mlKit;
  }

  static Language _parseLanguage(dynamic value) {
    if (value is String) {
      // Try to parse from code first
      try {
        return Language.fromCode(value);
      } catch (e) {
        // Fall back to name parsing
        return Language.values.firstWhere(
          (e) => e.name == value,
          orElse: () => Language.english,
        );
      }
    }
    return Language.english;
  }
}

// Keep old enum definitions for backward compatibility
// but mark as deprecated
@Deprecated('Use Language from language_pair.dart instead')
enum LanguageOld {
  hindi,
  marathi,
  english,
}

enum TranslationMode {
  text,
  voice,
  ocr,
}

enum ProcessingBackend {
  mlKit,
  gemini,
  error,
}
