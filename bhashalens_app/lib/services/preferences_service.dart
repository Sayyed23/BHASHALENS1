import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'aws_api_gateway_client.dart';
import 'local_storage_service.dart';

class PreferencesService extends ChangeNotifier {
  final AwsApiGatewayClient _apiClient;
  final LocalStorageService _localStorageService;
  static const String _localPrefsKey = 'bhashalens_user_preferences';

  Map<String, dynamic> _preferences = {};
  bool _isLoading = false;
  String? _error;

  PreferencesService({
    required AwsApiGatewayClient apiClient,
    required LocalStorageService localStorageService,
  })  : _apiClient = apiClient,
        _localStorageService = localStorageService;

  Map<String, dynamic> get preferences => Map.unmodifiable(_preferences);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load from local first so Settings work when cloud is off
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

      if (_apiClient.isEnabled) {
        try {
          final data = await _apiClient.getPreferences();
          _preferences = data['preferences'] ?? _preferences;
          await _localStorageService.saveString(
            _localPrefsKey,
            jsonEncode(_preferences),
          );
        } on AwsApiException catch (e) {
          _error = 'Failed to load preferences: ${e.message}';
          debugPrint(_error);
        } catch (e) {
          _error = 'Error fetching preferences: $e';
          debugPrint(_error);
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePreference(String key, dynamic value) async {
    final originalValue = _preferences[key];
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

    if (_apiClient.isEnabled) {
      try {
        await _apiClient.updatePreferences(updatedPrefs);
        notifyListeners();
        return true;
      } catch (e) {
        // Rollback local changes on API failure
        if (originalValue != null) {
          _preferences[key] = originalValue;
        } else {
          _preferences.remove(key);
        }
        await _localStorageService.saveString(
          _localPrefsKey,
          jsonEncode(_preferences),
        );
        _error = 'Error updating preference: $e';
        debugPrint('Error updating preference: $e');
        notifyListeners();
        return false;
      }
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
