import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

class PreferencesService extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  static const String _localPrefsKey = 'bhashalens_user_preferences';

  Map<String, dynamic> _preferences = {};
  bool _isLoading = false;
  String? _error;

  PreferencesService({
    required LocalStorageService localStorageService,
  }) : _localStorageService = localStorageService;

  Map<String, dynamic> get preferences => Map.unmodifiable(_preferences);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final localJson = await _localStorageService.getString(_localPrefsKey);
      if (localJson != null && localJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(localJson);
          if (decoded is Map<String, dynamic>) {
            _preferences = decoded;
          }
        } catch (_) {
          // Ignore invalid local cache
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePreference(String key, dynamic value) async {
    final updatedPrefs = Map<String, dynamic>.from(_preferences);
    updatedPrefs[key] = value;
    _preferences = updatedPrefs;
    _error = null;

    try {
      await _localStorageService.saveString(
        _localPrefsKey,
        jsonEncode(_preferences),
      );
    } catch (e) {
      debugPrint('Error saving preferences locally: $e');
    }

    notifyListeners();
    return true;
  }

  // Helper getters for common preferences
  String get theme => _preferences['theme'] ?? 'dark';
  String get defaultSourceLang => _preferences['defaultSourceLang'] ?? 'en';
  String get defaultTargetLang => _preferences['defaultTargetLang'] ?? 'hi';
  bool get autoTranslate => _preferences['autoTranslate'] ?? true;
}
