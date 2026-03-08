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
      final localList = localData.map((json) => HistoryItem(
        id: json['id'].toString(),
        userId: 'local',
        sourceText: json['originalText'] ?? '',
        targetText: json['translatedText'] ?? '',
        sourceLang: json['sourceLanguage'] ?? '',
        targetLang: json['targetLanguage'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
        type: json['category'] ?? 'translation',
        isSynced: (json['isSynced'] as int?) == 1,
        backend: json['backend'] as String? ?? 'offline',
      )).toList();

      if (_apiClient.isEnabled) {
        try {
          int page = 1;
          const int pageSize = 100;
          final allCloudItems = <HistoryItem>[];
          bool hasMore = true;

          while (hasMore) {
            final response = await _apiClient.getSavedTranslations(
              page: page,
              pageSize: pageSize,
            );
            final items = (response['items'] as List<dynamic>?)
                    ?.map((e) => _savedItemFromCloud(e as Map<String, dynamic>))
                    .whereType<HistoryItem>()
                    .toList() ??
                [];
            allCloudItems.addAll(items);
            hasMore = items.length == pageSize;
            page++;
          }

          final localIds = {for (final e in localList) e.id};
          final merged = <HistoryItem>[
            ...localList,
            ...allCloudItems.where((e) => !localIds.contains(e.id)),
          ];
          merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _savedItems = merged;
        } catch (e) {
          debugPrint('Cloud saved fetch failed, using local only: $e');
          _savedItems = localList;
          _savedItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      } else {
        _savedItems = localList;
        _savedItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      _error = 'Error fetching saved translations: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static HistoryItem? _savedItemFromCloud(Map<String, dynamic> item) {
    final id = item['translationId']?.toString() ?? item['id']?.toString();
    if (id == null || id.isEmpty) {
      debugPrint('Warning: Skipping saved translation with missing ID');
      return null;
    }

    final savedAt = item['savedAt'];
    final tsMs = savedAt is int
        ? savedAt
        : (savedAt is num ? savedAt.toInt() : DateTime.now().millisecondsSinceEpoch);
    return HistoryItem(
      id: id,
      userId: item['userId']?.toString() ?? 'cloud',
      sourceText: item['sourceText']?.toString() ?? '',
      targetText: item['targetText']?.toString() ?? '',
      sourceLang: item['sourceLang']?.toString() ?? '',
      targetLang: item['targetLang']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
      type: 'translation',
      isSynced: true,
      backend: item['backend']?.toString() ?? 'cloud',
    );
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
