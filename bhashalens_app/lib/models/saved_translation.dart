import 'package:cloud_firestore/cloud_firestore.dart';

class SavedTranslation {
  final String? id; // Changed to String to support Firestore IDs
  final String originalText;
  final String translatedText;
  final String fromLanguage;
  final String toLanguage;
  final DateTime dateTime;
  bool isStarred;
  final String category; // 'Medical', 'Travel', 'Business', 'General'

  SavedTranslation({
    this.id,
    required this.originalText,
    required this.translatedText,
    required this.fromLanguage,
    required this.toLanguage,
    required this.dateTime,
    this.isStarred = false,
    this.category = 'General',
  });

  Map<String, dynamic> toMap() {
    final map = {
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': fromLanguage,
      'targetLanguage': toLanguage,
      'timestamp': dateTime.millisecondsSinceEpoch,
      'isStarred': isStarred,
      'category': category,
    };
    // Only include id if it exists (for updates, not for new documents)
    // Removed 'id' to prevent conflicts with local SQLite AUTOINCREMENT
    // and redundancy in Firestore.
    /*
    if (id != null) {
      map['id'] = id;
    }
    */
    return map;
  }

  factory SavedTranslation.fromMap(Map<String, dynamic> map) {
    return SavedTranslation(
      id: map['id']?.toString(), // Handle both int (SQLite) and String
      originalText: map['originalText'] ?? '',
      translatedText: map['translatedText'] ?? '',
      fromLanguage: map['sourceLanguage'] ?? '',
      toLanguage: map['targetLanguage'] ?? '',
      dateTime: map['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      isStarred: map['isStarred'] == 1 || map['isStarred'] == true,
      category: map['category'] ?? 'General',
    );
  }

  factory SavedTranslation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      // Handle the case where the document exists but has no data,
      // or return a default object.
      return SavedTranslation(
        id: doc.id,
        originalText: '',
        translatedText: '',
        fromLanguage: '',
        toLanguage: '',
        dateTime: DateTime.now(),
      );
    }
    return SavedTranslation(
      id: doc.id,
      originalText: data['originalText'] ?? '',
      translatedText: data['translatedText'] ?? '',
      fromLanguage: data['sourceLanguage'] ?? '',
      toLanguage: data['targetLanguage'] ?? '',
      dateTime: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isStarred: data['isStarred'] ?? false,
      // Prefer 'category' key, fallback to 'context' key, default 'General'
      category: data['category'] ?? data['context'] ?? 'General',
    );
  }
}
