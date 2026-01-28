import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalStorageService {
  static Database? _database;
  static SharedPreferences? _preferences;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on the web');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<SharedPreferences> get preferences async {
    if (_preferences != null) return _preferences!;
    try {
      _preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      return _preferences!;
    } catch (e) {
      // If SharedPreferences fails, throw a descriptive exception
      throw Exception('Failed to initialize SharedPreferences: $e');
    }    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bhashalens.db');
    return openDatabase(
      path,
      version: 2, // Incremented version
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new columns to existing table
          // SQLite doesn't support adding multiple columns in one statement easily or IF NOT EXISTS nicely for columns
          // So we do one by one.
          try {
            await db.execute(
              "ALTER TABLE translations ADD COLUMN isStarred INTEGER DEFAULT 0",
            );
            await db.execute(
              "ALTER TABLE translations ADD COLUMN category TEXT DEFAULT 'General'",
            );
          } catch (e) {
            // Columns might already exist if we messed up dev, ignore
          }
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute(
      "CREATE TABLE translations(id INTEGER PRIMARY KEY AUTOINCREMENT, originalText TEXT, translatedText TEXT, sourceLanguage TEXT, targetLanguage TEXT, timestamp INTEGER, isStarred INTEGER DEFAULT 0, category TEXT DEFAULT 'General')",
    );
    await db.execute(
      "CREATE TABLE languagePacks(id INTEGER PRIMARY KEY AUTOINCREMENT, languageCode TEXT, data TEXT)",
    );
  }

  // SharedPreferences methods
  Future<void> saveString(String key, String value) async {
    final prefs = await preferences;
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await preferences;
    return prefs.getString(key);
  }

  // Onboarding status methods
  Future<void> saveOnboardingCompleted(bool completed) async {
    final prefs = await preferences;
    await prefs.setBool('onboarding_completed', completed);
  }

  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await preferences;
      return prefs.getBool('onboarding_completed') ?? false;
    } catch (e) {
      // If SharedPreferences fails, assume onboarding not completed
      return false;
    }
  }

  // API Usage Tracking
  Future<int> getApiUsageCount() async {
    final prefs = await preferences;
    return prefs.getInt('api_usage_count') ?? 0;
  }

  Future<void> _incrementLock = Future.value();
  Future<void> incrementApiUsageCount() async {
    final previousLock = _incrementLock;
    final completer = Completer<void>();
    _incrementLock = completer.future;

    try {
      await previousLock;
    } catch (_) {
      // If previous failed, we still proceed
    }

    try {
      final prefs = await preferences;
      int current = prefs.getInt('api_usage_count') ?? 0;
      await prefs.setInt('api_usage_count', current + 1);
    } finally {
      completer.complete();
    }
  }

  Future<void> resetApiUsageCount() async {
    final previousLock = _incrementLock;
    final completer = Completer<void>();
    _incrementLock = completer.future;

    try {
      await previousLock;
    } catch (_) {
      // If previous failed, we still proceed
    }

    try {
      final prefs = await preferences;
      await prefs.setInt('api_usage_count', 0);
    } finally {
      completer.complete();
    }
  }

  // SQLite methods for translations
  Future<int> insertTranslation(Map<String, dynamic> translation) async {
    if (kIsWeb) return 0; // No-op on web
    final db = await database;
    return await db.insert(
      'translations',
      translation,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTranslations() async {
    if (kIsWeb) return []; // Return empty list on web
    final db = await database;
    // Get all (History)
    return await db.query('translations', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getSavedTranslations() async {
    if (kIsWeb) return []; // Return empty list on web
    final db = await database;
    return await db.query(
      'translations',
      where: 'isStarred = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> updateTranslationStatus(String id, bool isStarred) async {
    if (kIsWeb) return 0;
    final intId = int.tryParse(id);
    if (intId == null) return 0;
    final db = await database;
    return await db.update(
      'translations',
      {'isStarred': isStarred ? 1 : 0},
      where: 'id = ?',
      whereArgs: [intId],
    );
  }

  Future<int> deleteTranslation(String id) async {
    if (kIsWeb) return 0;
    final intId = int.tryParse(id);
    if (intId == null) return 0;
    final db = await database;
    return await db.delete('translations', where: 'id = ?', whereArgs: [intId]);
  }

  // SQLite methods for language packs
  Future<int> insertLanguagePack(Map<String, dynamic> languagePack) async {
    if (kIsWeb) return 0;
    final db = await database;
    return await db.insert(
      'languagePacks',
      languagePack,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLanguagePack(String languageCode) async {
    if (kIsWeb) return null;
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'languagePacks',
      where: 'languageCode = ?',
      whereArgs: [languageCode],
    );
    return result.isNotEmpty ? result.first : null;
  }
}
