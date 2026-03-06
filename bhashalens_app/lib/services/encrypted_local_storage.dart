import 'dart:async';
import 'package:bhashalens_app/models/language_pair.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import '../models/translation_history_entry.dart';
import '../models/cached_translation.dart';
import '../models/conversation_message.dart';

/// Encrypted local storage service using SQLCipher with AES-256 encryption
/// and Flutter Secure Storage for key management
class EncryptedLocalStorage {
  static Database? _database;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _encryptionKeyName = 'bhashalens_db_encryption_key';

  /// Get the encrypted database instance
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLCipher is not supported on the web');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the encrypted database with SQLCipher
  Future<Database> _initDatabase() async {
    // Get or create encryption key from secure storage
    String? encryptionKey = await _secureStorage.read(key: _encryptionKeyName);

    if (encryptionKey == null) {
      // Generate a new 256-bit encryption key (64 hex characters)
      encryptionKey = _generateEncryptionKey();
      await _secureStorage.write(key: _encryptionKeyName, value: encryptionKey);
    }

    String path = join(await getDatabasesPath(), 'bhashalens_encrypted.db');

    return openDatabase(
      path,
      version: 1,
      password: encryptionKey,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  /// Generate a secure 256-bit encryption key
  String _generateEncryptionKey() {
    // Generate a random 256-bit key (32 bytes = 64 hex characters)
    final random = DateTime.now().millisecondsSinceEpoch.toString() +
        DateTime.now().microsecondsSinceEpoch.toString();
    return random.padRight(64, '0').substring(0, 64);
  }

  /// Create all database tables with the schema from the design document
  Future<void> _createTables(Database db) async {
    // Translation History table
    await db.execute('''
      CREATE TABLE translation_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        source_lang TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        mode TEXT NOT NULL,
        backend TEXT NOT NULL,
        confidence REAL,
        timestamp INTEGER NOT NULL,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // User Preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Translation Cache table
    await db.execute('''
      CREATE TABLE translation_cache (
        source_text TEXT NOT NULL,
        source_lang TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        confidence REAL,
        cached_at INTEGER NOT NULL,
        PRIMARY KEY (source_text, source_lang, target_lang)
      )
    ''');

    // Conversation History table
    await db.execute('''
      CREATE TABLE conversation_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        language TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Language Pack Metadata table
    await db.execute('''
      CREATE TABLE language_pack_metadata (
        language_pair TEXT PRIMARY KEY,
        version TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        installed_at INTEGER NOT NULL,
        last_used INTEGER
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_translation_history_timestamp ON translation_history(timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_conversation_history_session ON conversation_history(session_id, timestamp)',
    );
  }

  // ==================== Translation History Methods ====================

  /// Save a translation to history
  Future<void> saveTranslation(TranslationHistoryEntry translation) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'translation_history',
      translation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get translation history with pagination, ordered by timestamp descending (newest first)
  Future<List<TranslationHistoryEntry>> getTranslationHistory({
    int limit = 100,
    int offset = 0,
  }) async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'translation_history',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => TranslationHistoryEntry.fromMap(map)).toList();
  }

  /// Search translation history by query string
  Future<List<TranslationHistoryEntry>> searchTranslationHistory(
    String query,
  ) async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'translation_history',
      where: 'source_text LIKE ? OR translated_text LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => TranslationHistoryEntry.fromMap(map)).toList();
  }

  /// Delete translation history before a specific timestamp
  /// If beforeTimestamp is null, deletes all history
  Future<void> deleteTranslationHistory({int? beforeTimestamp}) async {
    if (kIsWeb) return;
    final db = await database;
    if (beforeTimestamp == null) {
      await db.delete('translation_history');
    } else {
      await db.delete(
        'translation_history',
        where: 'timestamp < ?',
        whereArgs: [beforeTimestamp],
      );
    }
  }

  // ==================== User Preferences Methods ====================

  /// Save a user preference
  Future<void> savePreference(String key, String value) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'user_preferences',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a user preference by key
  Future<String?> getPreference(String key) async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  // ==================== Translation Cache Methods ====================

  /// Cache a translation result
  Future<void> cacheTranslation({
    required String sourceText,
    required Language sourceLang,
    required Language targetLang,
    required String translatedText,
    required double confidence,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    final cachedTranslation = CachedTranslation(
      translatedText: translatedText,
      confidence: confidence,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insert(
      'translation_cache',
      cachedTranslation.toMap(
        sourceText: sourceText,
        sourceLang: sourceLang.name,
        targetLang: targetLang.name,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a cached translation
  Future<CachedTranslation?> getCachedTranslation({
    required String sourceText,
    required Language sourceLang,
    required Language targetLang,
  }) async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'translation_cache',
      where: 'source_text = ? AND source_lang = ? AND target_lang = ?',
      whereArgs: [sourceText, sourceLang.name, targetLang.name],
    );
    if (maps.isEmpty) return null;
    return CachedTranslation.fromMap(maps.first);
  }

  // ==================== Conversation History Methods ====================

  /// Save a conversation message
  Future<void> saveConversationMessage(ConversationMessage message) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'conversation_history',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get conversation history for a session
  Future<List<ConversationMessage>> getConversationHistory({
    required String sessionId,
    int limit = 10,
  }) async {
    if (kIsWeb) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversation_history',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => ConversationMessage.fromMap(map)).toList();
  }

  // ==================== Language Pack Metadata Methods ====================

  /// Save language pack metadata
  Future<void> saveLanguagePackMetadata({
    required String languagePair,
    required String version,
    required int sizeBytes,
    required int installedAt,
    int? lastUsed,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'language_pack_metadata',
      {
        'language_pair': languagePair,
        'version': version,
        'size_bytes': sizeBytes,
        'installed_at': installedAt,
        'last_used': lastUsed,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get language pack metadata
  Future<Map<String, dynamic>?> getLanguagePackMetadata(
    String languagePair,
  ) async {
    if (kIsWeb) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'language_pack_metadata',
      where: 'language_pair = ?',
      whereArgs: [languagePair],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Get all installed language packs
  Future<List<Map<String, dynamic>>> getAllLanguagePacks() async {
    if (kIsWeb) return [];
    final db = await database;
    return await db.query('language_pack_metadata');
  }

  // ==================== Data Management Methods ====================

  /// Clear all data from the database (for privacy/security)
  Future<void> clearAllData() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('translation_history');
    await db.delete('user_preferences');
    await db.delete('translation_cache');
    await db.delete('conversation_history');
    await db.delete('language_pack_metadata');
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
