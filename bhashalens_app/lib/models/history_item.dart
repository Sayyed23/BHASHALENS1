class HistoryItem {
  final String id;
  final String userId;
  final String sourceText;
  final String targetText;
  final String sourceLang;
  final String targetLang;
  final DateTime timestamp;
  final String? type; // 'translation', 'grammar', 'simplification', 'chat'

  HistoryItem({
    required this.id,
    required this.userId,
    required this.sourceText,
    required this.targetText,
    required this.sourceLang,
    required this.targetLang,
    required this.timestamp,
    this.type,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      sourceText: json['sourceText'] as String? ?? '',
      targetText: json['targetText'] as String? ??
          json['translatedText'] as String? ??
          '',
      sourceLang: json['sourceLang'] as String? ?? '',
      targetLang: json['targetLang'] as String? ?? '',
      timestamp: _parseTimestamp(json['timestamp']),
      type: json['type'] as String?,
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
    };
  }
}
