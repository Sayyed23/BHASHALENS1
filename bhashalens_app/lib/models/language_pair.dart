/// Language pair model for translation
class LanguagePair {
  final Language source;
  final Language target;

  const LanguagePair({
    required this.source,
    required this.target,
  });

  String get key => '${source.code}-${target.code}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguagePair &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          target == other.target;

  @override
  int get hashCode => source.hashCode ^ target.hashCode;

  @override
  String toString() => key;

  Map<String, dynamic> toMap() {
    return {
      'source': source.code,
      'target': target.code,
    };
  }

  factory LanguagePair.fromMap(Map<String, dynamic> map) {
    return LanguagePair(
      source: Language.fromCode(map['source'] as String),
      target: Language.fromCode(map['target'] as String),
    );
  }
}

/// Language enum with metadata
enum Language {
  hindi('hi', 'Hindi', 'हिन्दी'),
  marathi('mr', 'Marathi', 'मराठी'),
  english('en', 'English', 'English');

  final String code;
  final String name;
  final String nativeName;

  const Language(this.code, this.name, this.nativeName);

  static Language fromCode(String code) {
    return Language.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => Language.english,
    );
  }

  static Language fromName(String name) {
    return Language.values.firstWhere(
      (lang) => lang.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Language.english,
    );
  }
}
