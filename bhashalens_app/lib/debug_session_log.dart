import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Debug session logger: sends NDJSON to the ingest endpoint (works on web and app).
/// Logs are written to the session log file by the debug server.
// ignore_for_file: avoid_print
class DebugSessionLog {
  static const String _endpoint =
      'http://127.0.0.1:7294/ingest/3992bec2-0bf9-4b29-bbc1-d7acb84e20a2';
  static const String _sessionId = '023467';

  static void log(
    String location,
    String message, {
    Map<String, dynamic>? data,
    String? hypothesisId,
    String? runId,
  }) {
    final payload = <String, dynamic>{
      'sessionId': _sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'data': data ?? {},
      if (hypothesisId != null) 'hypothesisId': hypothesisId,
      if (runId != null) 'runId': runId,
    };
    // #region agent log
    http
        .post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'X-Debug-Session-Id': _sessionId,
      },
      body: jsonEncode(payload),
    )
        .catchError((Object _) {
      if (kDebugMode) print('DebugSessionLog: ingest failed');
      return http.Response('', 0);
    });
    // #endregion
  }
}
