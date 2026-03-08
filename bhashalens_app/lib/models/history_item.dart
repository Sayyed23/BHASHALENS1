class HistoryItem {
  final String id;
  final String userId;
  final String sourceText;
  final String targetText;
  final String sourceLang;
  final String targetLang;
  final DateTime timestamp;
  final String? type; // 'translation', 'grammar', 'simplification', 'chat'
  final bool isSynced;
  final String backend;

  HistoryItem({
    required this.id,
    required this.userId,
    required this.sourceText,
    required this.targetText,
    required this.sourceLang,
    required this.targetLang,
    required this.timestamp,
    this.type,
    this.isSynced = true,
    this.backend = 'unknown',
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      sourceText: json['originalText'] ?? json['sourceText'] as String? ?? '',
      targetText: json['translatedText'] ?? json['targetText'] as String? ?? '',
      sourceLang: json['sourceLanguage'] ?? json['sourceLang'] as String? ?? '',
      targetLang: json['targetLanguage'] ?? json['targetLang'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      type: json['category'] ?? json['type'] as String?,
      isSynced: (json['isSynced'] as int?) == 1 || json['id'] != null, // Default true if from cloud
      backend: json['backend'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sourceText': sourceText,
      'targetText': targetText,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'isSynced': isSynced ? 1 : 0,
      'backend': backend,
    };
  }
}
