// import 'package:flutter/material.dart';

class SavedTranslation {
  final String originalText;
  final String translatedText;
  final String fromLanguage;
  final String toLanguage;
  final DateTime dateTime;
  bool isStarred;

  SavedTranslation({
    required this.originalText,
    required this.translatedText,
    required this.fromLanguage,
    required this.toLanguage,
    required this.dateTime,
    this.isStarred = false,
  });
}
