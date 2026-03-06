import 'package:flutter/foundation.dart';
import '../models/history_item.dart';
import 'aws_api_gateway_client.dart';
import 'local_storage_service.dart';

class HistoryService extends ChangeNotifier {
  final AwsApiGatewayClient _apiClient;
  final LocalStorageService _localStorageService;
  List<HistoryItem> _history = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;

  HistoryService({
    required AwsApiGatewayClient apiClient,
    required LocalStorageService localStorageService,
  })  : _apiClient = apiClient,
        _localStorageService = localStorageService;

  List<HistoryItem> get history => _history;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;

  /// Synchronize local unsynced items with the cloud
  Future<void> syncLocalHistoryWithCloud() async {
    if (!_apiClient.isEnabled || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final unsynced = await _localStorageService.getUnsyncedTranslations();
      if (unsynced.isEmpty) return;

      int syncCount = 0;
      for (final item in unsynced) {
        try {
          await _apiClient.addHistoryItem(
            sourceText: item['originalText'],
            sourceLang: item['sourceLanguage'],
            targetText: item['translatedText'],
            targetLang: item['targetLanguage'],
            timestamp: item['timestamp'],
            type: item['category'],
            backend: 'offline',
          );

          await _localStorageService.markAsSynced(item['id'].toString());
          syncCount++;
        } catch (e) {
          debugPrint('Failed to sync item ${item['id']}: $e');
          // Continue to next item
        }
      }

      if (syncCount > 0) {
        debugPrint('Synced $syncCount items to cloud');
        await fetchHistory(); // Refresh cloud history
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    if (!_apiClient.isEnabled) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiClient.getHistory();
      final List<dynamic> items = data['items'] ?? [];
      _history = items.map((json) => HistoryItem.fromJson(json)).toList();
      // Sort by timestamp descending
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } on AwsApiException catch (e) {
      _error = 'Failed to load history: ${e.message}';
      debugPrint(_error);
    } catch (e) {
      _error = 'Error fetching history: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteHistoryItem(String id) async {
    try {
      await _apiClient.deleteHistoryItem(id);
      _history.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting history item: $e');
      return false;
    }
  }

  Future<bool> clearHistory() async {
    _isLoading = true;
    notifyListeners();

    // Assuming a bulk delete endpoint or iterating through locally and calling delete for each
    // For now, let's assume we delete individually if no bulk endpoint exists
    bool allDeleted = true;
    final ids = _history.map((e) => e.id).toList();
    for (final id in ids) {
      final success = await deleteHistoryItem(id);
      if (!success) allDeleted = false;
    }

    _isLoading = false;
    notifyListeners();
    return allDeleted;
  }
}
