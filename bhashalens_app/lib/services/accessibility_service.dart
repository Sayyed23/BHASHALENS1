import 'package:flutter/material.dart';

class AccessibilityService extends ChangeNotifier {
  double _textSizeFactor = 1.0; // Default text size
  ThemeMode _themeMode = ThemeMode.dark; // Default theme mode

  double get textSizeFactor => _textSizeFactor;
  ThemeMode get themeMode => _themeMode;

  // AccessibilityService() {
  //   _initTts();
  // }

  // void _initTts() {
  //   // TODO: Configure TTS settings (e.g., language, pitch, rate)
  //   _flutterTts.setLanguage("en-US");
  //   _flutterTts.setSpeechRate(0.5);
  //   _flutterTts.setPitch(1.0);
  // }

  // Future<void> speak(String text) async {
  //   await _flutterTts.speak(text);
  // }

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
