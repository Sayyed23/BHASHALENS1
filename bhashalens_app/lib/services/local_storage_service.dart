import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorageService {
  static Database? _database;
  static SharedPreferences? _preferences;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<SharedPreferences> get preferences async {
    if (_preferences != null) return _preferences!;
    _preferences = await SharedPreferences.getInstance();
    return _preferences!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bhashalens.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE translations(id INTEGER PRIMARY KEY AUTOINCREMENT, originalText TEXT, translatedText TEXT, sourceLanguage TEXT, targetLanguage TEXT, timestamp INTEGER)",
        );
        await db.execute(
          "CREATE TABLE languagePacks(id INTEGER PRIMARY KEY AUTOINCREMENT, languageCode TEXT, data TEXT)",
        );
      },
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
    final prefs = await preferences;
    return prefs.getBool('onboarding_completed') ??
        false; // Default to false if not set
  }

  // SQLite methods for translations
  Future<int> insertTranslation(Map<String, dynamic> translation) async {
    final db = await database;
    return await db.insert(
      'translations',
      translation,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTranslations() async {
    final db = await database;
    return await db.query('translations', orderBy: 'timestamp DESC');
  }

  // SQLite methods for language packs
  Future<int> insertLanguagePack(Map<String, dynamic> languagePack) async {
    final db = await database;
    return await db.insert(
      'languagePacks',
      languagePack,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLanguagePack(String languageCode) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'languagePacks',
      where: 'languageCode = ?',
      whereArgs: [languageCode],
    );
    return result.isNotEmpty ? result.first : null;
  }
}
