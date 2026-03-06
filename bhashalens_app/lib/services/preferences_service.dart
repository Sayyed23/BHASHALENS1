import 'package:flutter/foundation.dart';
import 'aws_api_gateway_client.dart';

class PreferencesService extends ChangeNotifier {
  final AwsApiGatewayClient _apiClient;
  Map<String, dynamic> _preferences = {};
  bool _isLoading = false;
  String? _error;

  PreferencesService({required AwsApiGatewayClient apiClient})
      : _apiClient = apiClient;

  Map<String, dynamic> get preferences => Map.unmodifiable(_preferences);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPreferences() async {
    if (!_apiClient.isEnabled) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.getPreferences();
      _preferences = data['preferences'] ?? {};
    } on AwsApiException catch (e) {
      _error = 'Failed to load preferences: ${e.message}';
      debugPrint(_error);
    } catch (e) {
      _error = 'Error fetching preferences: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePreference(String key, dynamic value) async {
    if (!_apiClient.isEnabled) return false;

    final updatedPrefs = Map<String, dynamic>.from(_preferences);
    updatedPrefs[key] = value;

    try {
      await _apiClient.updatePreferences(updatedPrefs);
      _preferences = updatedPrefs;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating preference: $e';
      debugPrint('Error updating preference: $e');
      notifyListeners();
      return false;
    }
  }

  // Helper getters for common preferences
  String get theme => _preferences['theme'] ?? 'dark';
  String get defaultSourceLang => _preferences['defaultSourceLang'] ?? 'en';
  String get defaultTargetLang => _preferences['defaultTargetLang'] ?? 'hi';
  bool get autoTranslate => _preferences['autoTranslate'] ?? true;
}
