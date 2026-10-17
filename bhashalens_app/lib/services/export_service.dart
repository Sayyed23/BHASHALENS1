import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

class ExportService extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  bool _isExporting = false;
  String? _error;

  ExportService({required LocalStorageService localStorageService})
      : _localStorageService = localStorageService;

  bool get isExporting => _isExporting;
  String? get error => _error;

  Future<Map<String, dynamic>?> exportData({
    required String exportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isExporting = true;
    _error = null;
    notifyListeners();

    try {
      List<Map<String, dynamic>> items = [];
      if (exportType == 'saved' || exportType == 'all') {
        final saved = await _localStorageService.getSavedTranslations();
        items.addAll(saved);
      }
      if (exportType == 'history' || exportType == 'all') {
        final history = await _localStorageService.getTranslations();
        items.addAll(history);
      }

      if (startDate != null) {
        items = items.where((item) {
          final ts = item['timestamp'] as num?;
          return ts != null && ts >= startDate.millisecondsSinceEpoch;
        }).toList();
      }

      if (endDate != null) {
        items = items.where((item) {
          final ts = item['timestamp'] as num?;
          return ts != null && ts <= endDate.millisecondsSinceEpoch;
        }).toList();
      }

      String exportContent = '';
      if (format.toLowerCase() == 'json') {
        exportContent = jsonEncode(items);
      } else {
        // CSV format
        final StringBuffer sb = StringBuffer();
        sb.writeln('ID,OriginalText,TranslatedText,SourceLanguage,TargetLanguage,Timestamp');
        for (final item in items) {
          final id = item['id'] ?? '';
          final orig = (item['originalText'] ?? '').toString().replaceAll('"', '""');
          final trans = (item['translatedText'] ?? '').toString().replaceAll('"', '""');
          final src = item['sourceLanguage'] ?? '';
          final tgt = item['targetLanguage'] ?? '';
          final ts = item['timestamp'] ?? '';
          sb.writeln('"$id","$orig","$trans","$src","$tgt","$ts"');
        }
        exportContent = sb.toString();
      }

      return {
        'format': format,
        'content': exportContent,
        'count': items.length,
      };
    } catch (e) {
      _error = 'Error during export: $e';
      debugPrint(_error);
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
