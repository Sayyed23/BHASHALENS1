import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/history_item.dart';
import 'aws_api_gateway_client.dart';
import 'local_storage_service.dart';
import 'package:bhashalens_app/debug_session_log.dart';

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
          debugPrint('Failed to sync item : ');
          // Continue to next item
        }
      }

      if (syncCount > 0) {
        debugPrint('Synced  items to cloud');
        await fetchHistory(); // Refresh cloud history
      }
    } catch (e) {
      debugPrint('Sync error: ');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final localData = await _localStorageService.getTranslations();
      final localList = localData.map((json) {
        final ts = json['timestamp'];
        final timestamp = ts is num && ts > 0
            ? DateTime.fromMillisecondsSinceEpoch(ts.toInt())
            : DateTime.now();

        return HistoryItem(
          id: json['id'].toString(),
          userId: 'local',
          sourceText: json['originalText'] ?? '',
          targetText: json['translatedText'] ?? '',
          sourceLang: json['sourceLanguage'] ?? '',
          targetLang: json['targetLanguage'] ?? '',
          timestamp: timestamp,
          type: json['category'] ?? 'translation',
          isSynced: (json['isSynced'] as int?) == 1,
          backend: json['backend'] as String? ?? 'offline',
        );
      }).toList();

      if (_apiClient.isEnabled) {
        try {
          // #region agent log
          DebugSessionLog.log(
            'history_service.dart:fetchHistory',
            'history_cloud_fetch_start',
            data: {},
            hypothesisId: 'H4',
          );
          // #endregion
          final response = await _apiClient.getHistory(
            page: 1,
            pageSize: 100,
          );
          final cloudItems = (response['items'] as List<dynamic>?)
                  ?.map((e) => _historyItemFromCloud(e as Map<String, dynamic>))
                  .toList() ??
              [];
          final localKeys = {for (final e in localList) _historyDedupeKey(e)};
          final merged = <HistoryItem>[
            ...localList,
            ...cloudItems.where(
              (e) => !localKeys.contains(_historyDedupeKey(e)),
            ),
          ];
          merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _history = merged;
          // #region agent log
          DebugSessionLog.log(
            'history_service.dart:fetchHistory',
            'history_cloud_fetch_ok',
            data: {'cloudCount': cloudItems.length, 'mergedCount': merged.length},
            hypothesisId: 'H4',
          );
          // #endregion
        } catch (e) {
          debugPrint('Cloud history fetch failed, using local only: ');
          // #region agent log
          DebugSessionLog.log(
            'history_service.dart:fetchHistory',
            'history_cloud_fetch_failed',
            data: {'error': e.toString()},
            hypothesisId: 'H4',
          );
          // #endregion
          _history = localList;
          _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
        if (!_isSyncing) {
          unawaited(syncLocalHistoryWithCloud().catchError((e) {
            debugPrint('Background sync failed: $e');
          }));
        }
      } else {
        _history = localList;
        _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      _error = 'Error fetching history: ';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static HistoryItem _historyItemFromCloud(Map<String, dynamic> item) {
    final ts = item['timestamp'];
    final timestamp = ts is num && ts > 0
        ? DateTime.fromMillisecondsSinceEpoch(ts.toInt())
        : DateTime.now();

    return HistoryItem(
      id: _cloudHistoryId(item),
      userId: item['userId']?.toString() ?? 'cloud',
      sourceText: item['sourceText']?.toString() ?? '',
      targetText: item['targetText']?.toString() ?? '',
      sourceLang: item['sourceLang']?.toString() ?? '',
      targetLang: item['targetLang']?.toString() ?? '',
      timestamp: timestamp,
      type: item['type']?.toString(),
      isSynced: true, // It's from the cloud, so it's synced
      backend: item['backend']?.toString() ?? 'cloud',
    );
  }

  static String _cloudHistoryId(Map<String, dynamic> item) {
    return (item['id'] ?? item['timestamp'])?.toString() ?? '';
  }

  static String _historyDedupeKey(HistoryItem item) {
    final tsMs = item.timestamp.millisecondsSinceEpoch;
    final sourceText = item.sourceText.trim().toLowerCase();
    final targetText = item.targetText.trim().toLowerCase();
    final sourceLang = item.sourceLang.trim().toLowerCase();
    final targetLang = item.targetLang.trim().toLowerCase();
    return '$sourceText|$targetText|$sourceLang|$targetLang|$tsMs';
  }

  Future<bool> deleteHistoryItem(String id) async {
    try {
      if (_apiClient.isEnabled) {
        await _apiClient.deleteHistoryItem(id);
      }
      await _localStorageService.deleteTranslation(id);
      _history.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting history item: ');
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
