import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// VM/IO: create InputImage from File (dart:io).
InputImage createInputImageFromFile(dynamic file) {
  return InputImage.fromFile(file as File);
}
