import 'package:flutter/foundation.dart';
import '../models/history_item.dart'; // Reuse the same model or create a new one if different
import 'aws_api_gateway_client.dart';

import 'local_storage_service.dart';

class SavedTranslationsService extends ChangeNotifier {
  final AwsApiGatewayClient _apiClient;
  final LocalStorageService _localStorageService;
  List<HistoryItem> _savedItems = [];
  bool _isLoading = false;
  String? _error;

  SavedTranslationsService({
    required AwsApiGatewayClient apiClient,
    required LocalStorageService localStorageService,
  })  : _apiClient = apiClient,
        _localStorageService = localStorageService;

  List<HistoryItem> get savedItems => List.unmodifiable(_savedItems);
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isSaved(String id) {
    return _savedItems.any((item) => item.id == id);
  }

  Future<void> fetchSavedTranslations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final localData = await _localStorageService.getSavedTranslations();
      _savedItems = localData.map((json) => HistoryItem(
        id: json['id'].toString(),
        userId: 'local',
        sourceText: json['originalText'] ?? '',
        targetText: json['translatedText'] ?? '',
        sourceLang: json['sourceLanguage'] ?? '',
        targetLang: json['targetLanguage'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
        type: json['category'] ?? 'translation',
      )).toList();
      _savedItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
      if (_apiClient.isEnabled) {
        try {
          await _apiClient.saveTranslation(
            translationId: item.id,
            sourceText: item.sourceText,
            sourceLang: item.sourceLang,
            translatedText: item.targetText,
            targetLang: item.targetLang,
          );
        } catch (e) {
          debugPrint('Error syncing saved translation to cloud: $e');
        }
      }
      
      await _localStorageService.updateTranslationStatus(item.id, true);
      
      if (!isSaved(item.id)) {
        _savedItems.insert(0, item);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving translation: $e');
      return false;
    }
  }

  Future<bool> deleteSavedItem(String id) async {
    try {
      if (_apiClient.isEnabled) {
        try {
          await _apiClient.deleteSavedTranslation(id);
        } catch (e) {
          debugPrint('Error deleting cloud saved translation: $e');
        }
      }
      
      await _localStorageService.updateTranslationStatus(id, false);
      _savedItems.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting saved item: $e');
      return false;
    }
  }
}
