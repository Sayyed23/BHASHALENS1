import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Initialize offline persistence settings if needed (usually auto-enabled in newer SDKs)
  FirestoreService() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  Future<void> saveTranslation({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
    required String type, // 'text', 'voice', 'camera'
    String? context,
  }) async {
    final uid = _userId;
    if (uid == null) return; // Should be logged in anonymously at least

    try {
      await _firestore.collection('users').doc(uid).collection('history').add({
        'originalText': originalText,
        'translatedText': translatedText,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'type': type,
        'context': context,
        'timestamp':
            FieldValue.serverTimestamp(), // Will fallback to local time offline
        'isStarred': false,
      });
    } catch (e) {
      debugPrint("Error saving translation: $e");
    }
  }

  Future<void> toggleSavedStatus(String docId, bool isStarred) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc(docId)
          .update({'isStarred': isStarred});
    } catch (e) {
      debugPrint("Error toggling saved status: $e");
    }
  }

  Future<void> deleteTranslation(String docId) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint("Error deleting translation: $e");
    }
  }

  Stream<QuerySnapshot> getHistoryStream() {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  Stream<QuerySnapshot> getSavedStream() {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('history')
        .where('isStarred', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Assistant Mode Phrases
  Future<void> saveAssistantPhrase({
    required String phrase,
    required String intent,
    required String translatedPhrase,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('assistant_phrases')
        .add({
          'phrase': phrase,
          'intent': intent,
          'translatedPhrase': translatedPhrase,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot> getAssistantPhrasesStream() {
    final uid = _userId;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('assistant_phrases')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
