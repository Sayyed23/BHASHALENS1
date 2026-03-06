import 'package:flutter/foundation.dart';
import 'aws_api_gateway_client.dart';

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
      final result = await _apiClient.exportData(
        exportType: exportType,
        format: format,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
      );
      return result;
    } on AwsApiException catch (e) {
      _error = 'Failed to export data: ${e.message}';
      debugPrint(_error);
      return null;
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
