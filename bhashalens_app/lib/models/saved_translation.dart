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
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': fromLanguage,
      'targetLanguage': toLanguage,
      'timestamp': dateTime.millisecondsSinceEpoch,
      'isStarred': isStarred ? 1 : 0,
      'category': category,
    };
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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SavedTranslation(
      id: doc.id,
      originalText: data['originalText'] ?? '',
      translatedText: data['translatedText'] ?? '',
      fromLanguage: data['sourceLanguage'] ?? '',
      toLanguage: data['targetLanguage'] ?? '',
      dateTime: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isStarred: data['isStarred'] ?? false,
      category:
          data['context'] ??
          'General', // Adapting context to category if needed
      // 'context' field in Firestore map = 'category' here? Or should add category to Firestore
    );
  }
}
