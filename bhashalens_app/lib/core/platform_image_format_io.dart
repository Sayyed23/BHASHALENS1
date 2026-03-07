import 'dart:io';
import 'package:camera/camera.dart';

/// VM/IO: use Platform to pick format for camera.
ImageFormatGroup get imageFormatGroupForCamera =>
    Platform.isAndroid ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888;
