import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Voice information for TTS
class Voice {
  final String name;
  final String locale;
  final String? gender;

  const Voice({
    required this.name,
    required this.locale,
    this.gender,
  });

  @override
  String toString() => 'Voice(name: $name, locale: $locale, gender: $gender)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Voice &&
        other.name == name &&
        other.locale == locale &&
        other.gender == gender;
  }

  @override
  int get hashCode => name.hashCode ^ locale.hashCode ^ (gender?.hashCode ?? 0);
}

/// TTS engine state
enum TtsState {
  stopped,
  playing,
  paused,
  continued,
}

/// Abstract interface for TTS engine
abstract class TtsEngine {
  /// Current TTS state
  TtsState get state;

  /// Stream of TTS state changes
  Stream<TtsState> get stateStream;

  /// Initialize the TTS engine
  Future<void> initialize();

  /// Dispose the TTS engine
  Future<void> dispose();

  /// Speak the given text
  Future<void> speak(String text, {String? language});

  /// Stop current speech
  Future<void> stop();

  /// Pause current speech
  Future<void> pause();

  /// Resume paused speech
  Future<void> resume();

  /// Set speech rate (0.1 to 2.0, default 1.0)
  Future<void> setSpeechRate(double rate);

  /// Set speech pitch (0.5 to 2.0, default 1.0)
  Future<void> setSpeechPitch(double pitch);

  /// Set speech volume (0.0 to 1.0, default 1.0)
  Future<void> setVolume(double volume);

  /// Set voice by name
  Future<void> setVoice(String voiceName);

  /// Set language
  Future<void> setLanguage(String language);

  /// Get available voices
  Future<List<Voice>> getVoices();

  /// Get available languages
  Future<List<String>> getLanguages();

  /// Check if language is available
  Future<bool> isLanguageAvailable(String language);
}

/// Flutter TTS engine implementation
class FlutterTtsEngine implements TtsEngine {
  final FlutterTts _flutterTts = FlutterTts();
  final StreamController<TtsState> _stateController =
      StreamController<TtsState>.broadcast();

  TtsState _currentState = TtsState.stopped;
  List<Voice>? _cachedVoices;
  List<String>? _cachedLanguages;

  // Variables to support pause/resume functionality
  String? _pausedText;
  String? _pausedLanguage;

  @override
  TtsState get state => _currentState;

  @override
  Stream<TtsState> get stateStream => _stateController.stream;

  @override
  Future<void> initialize() async {
    try {
      // Set up TTS handlers
      _flutterTts.setStartHandler(() {
        _updateState(TtsState.playing);
      });

      _flutterTts.setCompletionHandler(() {
        _updateState(TtsState.stopped);
      });

      _flutterTts.setCancelHandler(() {
        _updateState(TtsState.stopped);
      });

      _flutterTts.setPauseHandler(() {
        _updateState(TtsState.paused);
      });

      _flutterTts.setContinueHandler(() {
        _updateState(TtsState.continued);
      });

      _flutterTts.setErrorHandler((msg) {
        if (kDebugMode) {
          print('TTS Error: $msg');
        }
        _updateState(TtsState.stopped);
      });

      // Platform-specific initialization
      if (Platform.isAndroid) {
        await _flutterTts.setSharedInstance(true);
      }

      // Set default values
      await _flutterTts.setSpeechRate(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      // Set default language
      await _flutterTts.setLanguage('en-US');

      if (kDebugMode) {
        print('TTS Engine initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS Engine initialization failed: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
      await _stateController.close();
      if (kDebugMode) {
        print('TTS Engine disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS Engine disposal error: $e');
      }
    }
  }

  @override
  Future<void> speak(String text, {String? language}) async {
    if (text.trim().isEmpty) return;

    try {
      // Set language if provided
      if (language != null) {
        await setLanguage(language);
      }

      // Stop any current speech
      await stop();

      // Store current text and language for potential pause/resume
      _pausedText = text;
      _pausedLanguage = language;

      // Speak the text
      await _flutterTts.speak(text);

      if (kDebugMode) {
        print('TTS speaking: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS speak error: $e');
      }
      _updateState(TtsState.stopped);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      // Clear paused state when stopping
      _pausedText = null;
      _pausedLanguage = null;
      _updateState(TtsState.stopped);
    } catch (e) {
      if (kDebugMode) {
        print('TTS stop error: $e');
      }
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _updateState(TtsState.paused);
    } catch (e) {
      if (kDebugMode) {
        print('TTS pause error: $e');
      }
    }
  }

  @override
  Future<void> resume() async {
    try {
      if (_currentState != TtsState.paused) {
        if (kDebugMode) {
          print('TTS resume called but not in paused state');
        }
        return;
      }

      if (Platform.isIOS) {
        // iOS: Try to use the resume functionality if available
        // Note: flutter_tts may not have a direct resume method, so we fall back to re-speaking
        try {
          // Attempt to call resume if the plugin supports it
          // This is a workaround since flutter_tts doesn't have a documented resume method
          await _flutterTts
              .speak(""); // This might trigger resume on some versions
          await _flutterTts.stop(); // Stop the empty speak

          // If we have paused text, re-speak it
          if (_pausedText != null) {
            await _restartSpeech();
          } else {
            _updateState(TtsState.stopped);
          }
        } catch (e) {
          // Fallback to re-speaking from the beginning
          if (_pausedText != null) {
            await _restartSpeech();
          } else {
            _updateState(TtsState.stopped);
          }
        }
      } else {
        // Android: Re-speak from the beginning since flutter_tts doesn't support true resume
        if (_pausedText != null) {
          await _restartSpeech();
        } else {
          _updateState(TtsState.stopped);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS resume error: $e');
      }
      _updateState(TtsState.stopped);
    }
  }

  /// Helper method to restart speech from paused state
  /// Note: This is a limitation of flutter_tts - true resume from offset is not supported
  Future<void> _restartSpeech() async {
    if (_pausedText == null) return;

    try {
      // Set language if it was previously set
      if (_pausedLanguage != null) {
        await setLanguage(_pausedLanguage!);
      }

      // Re-speak the text from the beginning
      // This is a limitation: we cannot resume from the exact position where it was paused
      await _flutterTts.speak(_pausedText!);

      if (kDebugMode) {
        print('TTS resumed by re-speaking: $_pausedText');
        print(
            'Note: Resume starts from beginning due to flutter_tts limitations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS restart speech error: $e');
      }
      _updateState(TtsState.stopped);
      rethrow;
    }
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    try {
      // Clamp rate between 0.1 and 2.0
      final clampedRate = rate.clamp(0.1, 2.0);
      await _flutterTts.setSpeechRate(clampedRate);

      if (kDebugMode) {
        print('TTS speech rate set to: $clampedRate');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS setSpeechRate error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> setSpeechPitch(double pitch) async {
    try {
      // Clamp pitch between 0.5 and 2.0
      final clampedPitch = pitch.clamp(0.5, 2.0);
      await _flutterTts.setPitch(clampedPitch);

      if (kDebugMode) {
        print('TTS speech pitch set to: $clampedPitch');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS setSpeechPitch error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      // Clamp volume between 0.0 and 1.0
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(clampedVolume);

      if (kDebugMode) {
        print('TTS volume set to: $clampedVolume');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS setVolume error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> setVoice(String voiceName) async {
    try {
      final voices = await getVoices();
      final voice = voices.firstWhere(
        (v) => v.name == voiceName,
        orElse: () => voices.isNotEmpty
            ? voices.first
            : const Voice(name: 'default', locale: 'en-US'),
      );

      await _flutterTts.setVoice({
        'name': voice.name,
        'locale': voice.locale,
      });

      if (kDebugMode) {
        print('TTS voice set to: ${voice.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS setVoice error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);

      if (kDebugMode) {
        print('TTS language set to: $language');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS setLanguage error: $e');
      }
      rethrow;
    }
  }

  @override
  Future<List<Voice>> getVoices() async {
    if (_cachedVoices != null) {
      return _cachedVoices!;
    }

    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        _cachedVoices = voices.map<Voice>((voice) {
          return Voice(
            name: voice['name'] ?? 'Unknown',
            locale: voice['locale'] ?? 'en-US',
            gender: voice['gender'],
          );
        }).toList();
      } else {
        _cachedVoices = [const Voice(name: 'default', locale: 'en-US')];
      }

      return _cachedVoices!;
    } catch (e) {
      if (kDebugMode) {
        print('TTS getVoices error: $e');
      }
      return [const Voice(name: 'default', locale: 'en-US')];
    }
  }

  @override
  Future<List<String>> getLanguages() async {
    if (_cachedLanguages != null) {
      return _cachedLanguages!;
    }

    try {
      final languages = await _flutterTts.getLanguages;
      if (languages != null) {
        _cachedLanguages = List<String>.from(languages);
      } else {
        _cachedLanguages = ['en-US'];
      }

      return _cachedLanguages!;
    } catch (e) {
      if (kDebugMode) {
        print('TTS getLanguages error: $e');
      }
      return ['en-US'];
    }
  }

  @override
  Future<bool> isLanguageAvailable(String language) async {
    try {
      final result = await _flutterTts.isLanguageAvailable(language);
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('TTS isLanguageAvailable error: $e');
      }
      return false;
    }
  }

  /// Update the current state and notify listeners
  void _updateState(TtsState newState) {
    if (_currentState != newState) {
      _currentState = newState;

      // Check if the controller is still open before adding events
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }

      if (kDebugMode) {
        print('TTS state changed to: $newState');
      }
    }
  }

  /// Detect language from text (basic implementation)
  String detectLanguage(String text) {
    // This is a very basic language detection
    // In a real implementation, you might want to use a proper language detection library

    // Check for common patterns
    if (RegExp(r'[а-яё]', caseSensitive: false).hasMatch(text)) {
      return 'ru-RU'; // Russian
    } else if (RegExp(r'[àâäéèêëïîôöùûüÿç]', caseSensitive: false)
        .hasMatch(text)) {
      return 'fr-FR'; // French
    } else if (RegExp(r'[äöüß]', caseSensitive: false).hasMatch(text)) {
      return 'de-DE'; // German
    } else if (RegExp(r'[áéíóúñü]', caseSensitive: false).hasMatch(text)) {
      return 'es-ES'; // Spanish
    } else if (RegExp(r'[àèéìíîòóù]', caseSensitive: false).hasMatch(text)) {
      return 'it-IT'; // Italian
    } else if (RegExp(r'[ãâáàçéêíóôõú]', caseSensitive: false).hasMatch(text)) {
      return 'pt-PT'; // Portuguese
    } else if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) {
      return 'zh-CN'; // Chinese
    } else if (RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(text)) {
      return 'ja-JP'; // Japanese
    } else if (RegExp(r'[\uac00-\ud7af]').hasMatch(text)) {
      return 'ko-KR'; // Korean
    } else if (RegExp(r'[\u0900-\u097f]').hasMatch(text)) {
      return 'hi-IN'; // Hindi
    } else if (RegExp(r'[\u0600-\u06ff]').hasMatch(text)) {
      return 'ar-SA'; // Arabic
    }

    // Default to English
    return 'en-US';
  }
}
