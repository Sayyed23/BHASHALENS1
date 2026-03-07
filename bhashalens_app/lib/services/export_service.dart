import 'package:flutter/foundation.dart';
import 'aws_api_gateway_client.dart';
import 'package:bhashalens_app/debug_session_log.dart';

class ExportService extends ChangeNotifier {
  final AwsApiGatewayClient _apiClient;
  bool _isExporting = false;
  String? _error;

  ExportService({required AwsApiGatewayClient apiClient})
      : _apiClient = apiClient;

  bool get isExporting => _isExporting;
  String? get error => _error;

  Future<Map<String, dynamic>?> exportData({
    required String exportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_apiClient.isEnabled) return null;

    _isExporting = true;
    _error = null;
    notifyListeners();

    try {
      // #region agent log
      DebugSessionLog.log(
        'export_service.dart:exportData',
        'export_attempt',
        data: {'exportType': exportType, 'format': format},
        hypothesisId: 'H4',
      );
      // #endregion
      final result = await _apiClient.exportData(
        exportType: exportType,
        format: format,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
      );
      // #region agent log
      DebugSessionLog.log(
        'export_service.dart:exportData',
        'export_ok',
        data: {'hasUrl': result['url'] != null || result['downloadUrl'] != null},
        hypothesisId: 'H4',
      );
      // #endregion
      return result;
    } on AwsApiException catch (e) {
      _error = 'Failed to export data: ${e.message}';
      debugPrint(_error);
      // #region agent log
      DebugSessionLog.log(
        'export_service.dart:exportData',
        'export_failed',
        data: {'error': e.message},
        hypothesisId: 'H4',
      );
      // #endregion
      return null;
    } catch (e) {
      _error = 'Error during export: $e';
      debugPrint(_error);
      // #region agent log
      DebugSessionLog.log(
        'export_service.dart:exportData',
        'export_failed',
        data: {'error': e.toString()},
        hypothesisId: 'H4',
      );
      // #endregion
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
