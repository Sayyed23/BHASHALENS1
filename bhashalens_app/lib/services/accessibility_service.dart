import 'package:flutter/material.dart';

class AccessibilityService extends ChangeNotifier {
  double _textSizeFactor = 1.0; // Default text size
  bool _highContrastMode = false; // Default high contrast mode

  double get textSizeFactor => _textSizeFactor;
  bool get highContrastMode => _highContrastMode;

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

  void toggleHighContrastMode() {
    _highContrastMode = !_highContrastMode;
    notifyListeners();
  }
}
