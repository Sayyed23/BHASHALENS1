import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Service for Sarvam AI (OCR, ASR, TTS)
class SarvamService {
  final String _apiKey;
  final String _baseUrl = 'https://api.sarvam.ai';
  final http.Client _httpClient;

  SarvamService({http.Client? httpClient})
      : _apiKey = dotenv.env['SARVAM_AI_API_KEY'] ?? '',
        _httpClient = httpClient ?? http.Client();

  bool get isEnabled => _apiKey.isNotEmpty;

  /// Perform OCR on an image (base64)
  Future<String> performOCR(String base64Image) async {
    if (!isEnabled) return '';

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/ocr'),
        headers: {
          'api-subscription-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? '';
      } else {
        debugPrint('Sarvam OCR failed: ${response.statusCode} ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('Sarvam OCR error: $e');
      return '';
    }
  }

  /// Perform Speech-to-Text (ASR)
  Future<String> speechToText(String base64Audio, String languageCode) async {
    if (!isEnabled) return '';

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/asr'),
        headers: {
          'api-subscription-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'audio': base64Audio,
          'language_code': languageCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transcript'] ?? '';
      } else {
        debugPrint('Sarvam ASR failed: ${response.statusCode} ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('Sarvam ASR error: $e');
      return '';
    }
  }

  /// Perform Text-to-Speech (TTS)
  Future<String?> textToSpeech(String text, String languageCode) async {
    if (!isEnabled) return null;

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/text-to-speech'),
        headers: {
          'api-subscription-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'language_code': languageCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['audios']?[0]; // Base64 audio
      } else {
        debugPrint('Sarvam TTS failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Sarvam TTS error: $e');
      return null;
    }
  }

  /// Helper to speak text using the above and VoiceTranslationService playback logic
  /// (Minimal implementation for now, assuming external playback)
  Future<void> speakText(String text, String languageCode) async {
    final audio = await textToSpeech(text, languageCode);
    if (audio != null) {
      // Playback logic normally goes here or in a separate audio service
      debugPrint("Sarvam TTS: Audio generated, playback required");
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
