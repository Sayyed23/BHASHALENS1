import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AccessibilityService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  double _textSizeFactor = 1.0; 
  ThemeMode _themeMode = ThemeMode.dark; 

  double get textSizeFactor => _textSizeFactor;
  ThemeMode get themeMode => _themeMode;

  AccessibilityService() {
    _initTts();
  }

  void _initTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  void setTextSizeFactor(double factor) {
    if (factor > 0) {
      _textSizeFactor = factor;
      notifyListeners();
    }
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}
