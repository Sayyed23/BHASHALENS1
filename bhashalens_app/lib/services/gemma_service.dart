import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing on-device AI model for smart explanations.
/// Handles model download, initialization, and inference.
/// Uses SmolLM 135M (~80MB) for smaller download size.
class GemmaService extends ChangeNotifier {
  // SmolLM 135M model URL - small and efficient (~80MB)
  static const String _modelUrl =
      'https://huggingface.co/litert-community/SmolLM-135M-Instruct/resolve/main/SmolLM-135M-Instruct-gpu-int4.task';

  // Model filename for checking installation
  static const String _modelName = 'SmolLM-135M-Instruct-gpu-int4.task';

  // Preferences keys
  static const String _keyModelInstalled = 'gemma_model_installed';
  static const String _keySmartExplainEnabled = 'smart_explain_enabled';
  static const String _keyQuantizationType = 'gemma_quantization_type';

  // State
  bool _isModelInstalled = false;
  bool _isSmartExplainEnabled = false;
  bool _isDownloading = false;
  bool _isInitializing = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  String _quantizationType = 'int8'; // 'int4' or 'int8'

  InferenceModel? _activeModel;
  InferenceChat? _activeChat;

  // Getters
  bool get isModelInstalled => _isModelInstalled;
  bool get isSmartExplainEnabled => _isSmartExplainEnabled;
  bool get isDownloading => _isDownloading;
  bool get isInitializing => _isInitializing;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  String get quantizationType => _quantizationType;

  /// Check if Gemma is ready for use
  bool get isAvailable => _isModelInstalled && _activeModel != null;

  /// Check if Gemma should be used for explanations
  bool get isEnabled => _isSmartExplainEnabled && isAvailable;

  /// Initialize the service and check model status
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isModelInstalled = prefs.getBool(_keyModelInstalled) ?? false;
      _isSmartExplainEnabled = prefs.getBool(_keySmartExplainEnabled) ?? false;
      _quantizationType = prefs.getString(_keyQuantizationType) ?? 'int8';

      // Verify model is actually installed
      if (_isModelInstalled) {
        final isInstalled = await FlutterGemma.isModelInstalled(_modelName);
        _isModelInstalled = isInstalled;

        // Update prefs if model was removed
        if (!isInstalled) {
          await prefs.setBool(_keyModelInstalled, false);
        }
      }

      notifyListeners();

      // If model is installed and enabled, initialize it
      if (_isModelInstalled && _isSmartExplainEnabled) {
        await _initializeModel();
      }
    } catch (e) {
      debugPrint('GemmaService init error: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Download and install the SmolLM 135M model (~80MB)
  /// If huggingFaceToken is not provided, it will be loaded from .env
  Future<bool> downloadModel({
    String? huggingFaceToken,
  }) async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use provided token or load from .env
      final token = huggingFaceToken ?? dotenv.env['HUGGINGFACE_TOKEN'];

      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt, // Works with SmolLM .task files
      )
          .fromNetwork(
        _modelUrl,
        token: token,
      )
          .withProgress((progress) {
        _downloadProgress = progress / 100.0;
        notifyListeners();
      }).install();

      // Save installation status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyModelInstalled, true);

      _isModelInstalled = true;
      _isDownloading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Model download error: $e');
      _errorMessage = 'Download failed: $e';
      _isDownloading = false;
      notifyListeners();
      return false;
    }
  }

  /// Initialize the model for inference
  Future<bool> _initializeModel() async {
    if (_isInitializing || !_isModelInstalled) return false;

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeModel = await FlutterGemma.getActiveModel(
        maxTokens: 256, // Keep responses short for explanations
        preferredBackend: PreferredBackend.gpu,
      );

      _activeChat = await _activeModel!.createChat();

      _isInitializing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Model initialization error: $e');
      _errorMessage = 'Failed to initialize model: $e';
      _isInitializing = false;
      notifyListeners();
      return false;
    }
  }

  /// Enable or disable smart explanations
  Future<void> setSmartExplainEnabled(bool enabled) async {
    _isSmartExplainEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmartExplainEnabled, enabled);

    notifyListeners();

    // Initialize model if enabling and not yet initialized
    if (enabled && _isModelInstalled && _activeModel == null) {
      await _initializeModel();
    }
  }

  /// Simplify text using Gemma
  /// Returns simplified text or null if Gemma is not available/fails
  Future<String?> simplifyText(String text, {String? context}) async {
    if (!isAvailable || _activeChat == null) {
      return null;
    }

    try {
      // Build constrained prompt
      final contextLine = context != null ? 'Context: $context\n' : '';
      final prompt = '''
Task: Simplify and explain.

${contextLine}Sentence: "$text"

Rules:
- Use simple words
- Maximum 2 sentences
- Do not add advice
- Do not change meaning

Output:''';

      await _activeChat!.addQueryChunk(Message.text(
        text: prompt,
        isUser: true,
      ));

      final response = await _activeChat!.generateChatResponse();

      // Handle response - extract text from ModelResponse
      // The response contains tokens, convert to string
      final responseText = response.toString();

      // Post-process the response
      return _postProcess(responseText);
    } catch (e) {
      debugPrint('Gemma inference error: $e');
      return null;
    }
  }

  /// Post-process Gemma output for safety
  String? _postProcess(String? output) {
    if (output == null || output.trim().isEmpty) {
      return null;
    }

    String result = output.trim();

    // Remove common unsafe patterns
    final unsafePatterns = [
      RegExp(r'(you should|you must|I recommend|I suggest)',
          caseSensitive: false),
      RegExp(r'(consult a doctor|see a lawyer|seek medical)',
          caseSensitive: false),
      RegExp(r'(this is not advice|disclaimer)', caseSensitive: false),
    ];

    for (final pattern in unsafePatterns) {
      if (pattern.hasMatch(result)) {
        // If output contains advice, return null to fallback to template
        return null;
      }
    }

    // Limit to max 100 words
    final words = result.split(RegExp(r'\s+'));
    if (words.length > 100) {
      result = '${words.take(100).join(' ')}...';
    }

    // Ensure output ends properly
    if (!result.endsWith('.') &&
        !result.endsWith('!') &&
        !result.endsWith('?')) {
      result = '$result.';
    }

    return result;
  }

  /// Get model size info
  String getModelSizeInfo() {
    if (_quantizationType == 'int4') {
      return '~1.0 GB (INT4)';
    } else {
      return '~1.5 GB (INT8)';
    }
  }

  /// Release resources
  @override
  void dispose() {
    _activeChat = null;
    _activeModel = null;
    super.dispose();
  }

  /// Delete the downloaded model
  Future<bool> deleteModel() async {
    try {
      _activeChat = null;
      _activeModel = null;

      // Note: flutter_gemma may not have a direct delete method
      // Mark as uninstalled in preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyModelInstalled, false);

      _isModelInstalled = false;
      _isSmartExplainEnabled = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Delete model error: $e');
      _errorMessage = 'Failed to delete model: $e';
      notifyListeners();
      return false;
    }
  }
}
