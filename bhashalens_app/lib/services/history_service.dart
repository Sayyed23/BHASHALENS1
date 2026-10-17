import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/history_item.dart';
import 'local_storage_service.dart';

class HistoryService extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  List<HistoryItem> _history = [];
  bool _isLoading = false;
  final bool _isSyncing = false;
  String? _error;

  HistoryService({
    required LocalStorageService localStorageService,
  }) : _localStorageService = localStorageService;

  List<HistoryItem> get history => _history;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;

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

      _history = localList;
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
      await _localStorageService.deleteTranslation(id);
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

    try {
      await _localStorageService.clearTranslations();
      _history.clear();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error clearing history: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
