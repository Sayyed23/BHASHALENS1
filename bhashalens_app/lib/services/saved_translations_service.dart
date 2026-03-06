import 'package:flutter/foundation.dart';
import '../models/history_item.dart'; // Reuse the same model or create a new one if different
import 'aws_api_gateway_client.dart';

class SavedTranslationsService extends ChangeNotifier {
  final AwsApiGatewayClient _apiClient;
  List<HistoryItem> _savedItems = [];
  bool _isLoading = false;
  String? _error;

  SavedTranslationsService({required AwsApiGatewayClient apiClient})
      : _apiClient = apiClient;

  List<HistoryItem> get savedItems => List.unmodifiable(_savedItems);
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isSaved(String id) {
    return _savedItems.any((item) => item.id == id);
  }

  Future<void> fetchSavedTranslations() async {
    if (!_apiClient.isEnabled) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.getSavedTranslations();
      final List<dynamic> items = data['items'] ?? [];
      _savedItems = items.map((json) => HistoryItem.fromJson(json)).toList();
      _savedItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } on AwsApiException catch (e) {
      _error = 'Failed to load saved translations: ${e.message}';
      debugPrint(_error);
    } catch (e) {
      _error = 'Error fetching saved translations: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveItem(HistoryItem item) async {
    try {
      await _apiClient.saveTranslation(
        translationId: item.id,
        sourceText: item.sourceText,
        sourceLang: item.sourceLang,
        translatedText: item.targetText,
        targetLang: item.targetLang,
      );
      _savedItems.insert(0, item);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving translation: $e');
      return false;
    }
  }

  Future<bool> deleteSavedItem(String id) async {
    if (!_apiClient.isEnabled) return false;

    try {
      await _apiClient.deleteSavedTranslation(id);
      _savedItems.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting saved item: $e');
      return false;
    }
  }
}
