import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/pages/explain_mode_page.dart'; // Import ExplainModePage
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/local_storage_service.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:ui' as ui; // Import for ImageFilter
import 'package:share_plus/share_plus.dart';

class CameraTranslatePage extends StatefulWidget {
  const CameraTranslatePage({super.key});

  @override
  State<CameraTranslatePage> createState() => _CameraTranslatePageState();
}

class _CameraTranslatePageState extends State<CameraTranslatePage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;

  // Translation State
  XFile? _capturedImage;
  Uint8List? _capturedImageBytes;
  String _extractedText = '';
  String _translatedText = '';
  String _sourceLanguageCode = 'auto'; // 'auto' means detect
  String _targetLanguageCode = 'en'; // Default target

  // Mapping for display
  final Map<String, String> _displayLanguages = {
    'auto': 'Detect Language',
  };

  final _mlKitService = MlKitTranslationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLanguages();
    _initializeCamera();
  }

  void _loadLanguages() {
    final languages = _mlKitService.getSupportedLanguages();
    setState(() {
      for (var lang in languages) {
        _displayLanguages[lang['code']!] = lang['name']!;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-initialize camera on resume if needed
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.jpeg
              : ImageFormatGroup.bgra8888,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _isProcessing) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile image = await _cameraController!.takePicture();
      if (!mounted) return;
      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _capturedImage = image;
        _capturedImageBytes = bytes;
      });

      await _processImage(bytes);
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        if (!mounted) return;
        setState(() {
          _isProcessing = true;
        });

        final Uint8List bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _capturedImage = image;
          _capturedImageBytes = bytes;
        });

        await _processImage(bytes);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processImage(Uint8List bytes) async {
    // Logic adapted from previous implementation
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!mounted) return;
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      String extracted = '';
      String translated = '';
      String detectedLang = _sourceLanguageCode;

      if (isOffline) {
        if (_sourceLanguageCode == 'auto') {
          throw Exception(
            "Offline Mode: Please select a specific Source Language (Auto-detect not supported offline).",
          );
        }

        // Check if Source model is downloaded
        if (_sourceLanguageCode != 'en') {
          final isSourceDownloaded = await _mlKitService.isModelDownloaded(
            _sourceLanguageCode,
          );
          if (!isSourceDownloaded) {
            throw Exception(
              "Offline Mode: Source language model (${_displayLanguages[_sourceLanguageCode]}) not downloaded.",
            );
          }
        }

        // Check if Target model is downloaded
        if (_targetLanguageCode != 'en') {
          final isTargetDownloaded = await _mlKitService.isModelDownloaded(
            _targetLanguageCode,
          );
          if (!isTargetDownloaded) {
            throw Exception(
              "Offline Mode: Target language model (${_displayLanguages[_targetLanguageCode]}) not downloaded.",
            );
          }
        }

        // ML Kit Text Recognition often needs a file path or InputImage
        // Assuming we have _capturedImage path
        if (_capturedImage != null) {
          extracted = await _mlKitService.extractTextFromFile(
            File(_capturedImage!.path),
          );
        } else {
          extracted = "Error: Image file not available for offline OCR.";
        }

        if (extracted.isNotEmpty && !extracted.startsWith("Error")) {
          final result = await _mlKitService.translate(
            text: extracted,
            sourceLanguage: _sourceLanguageCode,
            targetLanguage: _targetLanguageCode,
          );
          
          if (result != null && result.isNotEmpty) {
            translated = result;
          } else {
            // Check what models are missing for better error message
            final missingModels = await _mlKitService.getMissingModelsForTranslation(
              _sourceLanguageCode,
              _targetLanguageCode,
            );

            if (missingModels.isNotEmpty) {
              final languageNames = missingModels.map((code) {
                final lang = _mlKitService.getSupportedLanguages()
                    .firstWhere((l) => l['code'] == code, orElse: () => {'name': code});
                return lang['name'] ?? code;
              }).join(', ');
              
              translated = 'Missing language models: $languageNames. Please download them in Settings → Offline Models.';
            } else {
              translated = "Translation failed (Offline)";
            }
          }
        }
      } else {
        // Gemini Online Logic
        final geminiService = Provider.of<GeminiService>(
          context,
          listen: false,
        );
        if (!geminiService.isInitialized) {
          throw Exception("Gemini Service not initialized");
        }

        extracted = await geminiService.extractTextFromImage(bytes);
        if (!mounted) return;

        if (extracted.isNotEmpty && extracted != 'No text detected') {
          if (_sourceLanguageCode == 'auto') {
            detectedLang = await geminiService.detectLanguage(extracted);
            if (!mounted) return;
          }
          translated = await geminiService.translateText(
            extracted,
            _targetLanguageCode,
            sourceLanguage: detectedLang == 'auto' ? null : detectedLang,
          );
        } else {
          extracted = "No text found in image.";
        }
      }

      if (mounted) {
        setState(() {
          _extractedText = extracted;
          _translatedText = translated;
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Processing error: $e');
      if (mounted) {
        setState(() {
          _extractedText = "Error processing image";
          _translatedText = e.toString();
          _isProcessing = false;
        });
      }
    }
  }

  void _resetState() {
    setState(() {
      _capturedImage = null;
      _capturedImageBytes = null;
      _extractedText = '';
      _translatedText = '';
    });
    _initializeCamera(); // Re-init preview if needed
  }

  void _toggleFlash() {
    if (_cameraController != null && _isCameraInitialized) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark theme enforce
    const backgroundColor = Color(0xFF111827);
    const surfaceColor = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview Layer
          if (_isCameraInitialized && _capturedImageBytes == null)
            CameraPreview(_cameraController!)
          else if (_capturedImageBytes != null)
            Image.memory(_capturedImageBytes!, fit: BoxFit.cover)
          else
            Container(color: Colors.black),

          // 2. Overlay (Dimmer & Focus Area) - Only in Camera Mode
          if (_capturedImageBytes == null)
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 300,
                      height: 200, // Focus Rectangle
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2.5 Focus Brackets Decoration (Visual only)
          if (_capturedImageBytes == null)
            Center(
              child: Container(
                width: 320,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent),
                ),
                child: Stack(
                  children: [
                    // Top Left
                    Positioned(
                      left: 0,
                      top: 0,
                      child: _buildCorner(true, true),
                    ),
                    // Top Right
                    Positioned(
                      right: 0,
                      top: 0,
                      child: _buildCorner(true, false),
                    ),
                    // Bottom Left
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: _buildCorner(false, true),
                    ),
                    // Bottom Right
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _buildCorner(false, false),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Top Language Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 15,
                left: 20,
                right: 20,
              ),
              child: Row(
                children: [
                  // Back Button (Glassy)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Language Selector Pill (Glassy)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _showLanguagePicker(true),
                              child: Text(
                                _displayLanguages[_sourceLanguageCode] ??
                                    _sourceLanguageCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 16,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showLanguagePicker(false),
                              child: Text(
                                _displayLanguages[_targetLanguageCode] ??
                                    _targetLanguageCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance spacing
                ],
              ),
            ),
          ),

          // 4. Bottom Controls / Result Card
          if (_capturedImageBytes == null && !_isProcessing)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 50, top: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery
                    _buildGlassyButton(
                      icon: Icons.photo_library_rounded,
                      onTap: _pickFromGallery,
                    ),

                    // Shutter
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Flash
                    _buildGlassyButton(
                      icon: _isFlashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),

          // 5. Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // 6. Result Sheet
          if (_capturedImageBytes != null && !_isProcessing)
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Translation
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "English (Translated)", // Placeholder dynamic
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _translatedText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              color: Color(0xFF3B82F6),
                            ),
                            onPressed: () {
                              // TTS placeholder
                            },
                          ),
                        ],
                      ),

                      const Divider(color: Colors.grey, height: 32),

                      // Original
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Original Text",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Text(
                              _extractedText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            Icons.copy,
                            "Copy",
                            _copyTranslation,
                          ),
                          _buildActionButton(
                            Icons.save,
                            "Save",
                            _saveTranslation,
                          ),
                          _buildActionButton(
                            Icons.psychology,
                            "Explain",
                            _explainTranslation,
                          ),
                          _buildActionButton(
                            Icons.share,
                            "Share",
                            _shareTranslation,
                          ),
                          _buildActionButton(
                            Icons.restart_alt,
                            "Retake",
                            _resetState,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    const double size = 20;
    const double thickness = 3;
    const color = Color(0xFF3B82F6);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: isTop
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80, // Fixed width for alignment
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF374151).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  void _copyTranslation() {
    Clipboard.setData(ClipboardData(text: _translatedText));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _saveTranslation() async {
    if (_extractedText.isEmpty || _translatedText.isEmpty) return;
    try {
      final localStorage = Provider.of<LocalStorageService>(
        context,
        listen: false,
      );
      await localStorage.insertTranslation({
        'originalText': _extractedText,
        'translatedText': _translatedText,
        'sourceLanguage': _sourceLanguageCode,
        'targetLanguage': _targetLanguageCode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Translation Saved')));
      }
    } catch (e) {
      debugPrint("Error saving: $e");
    }
  }

  void _explainTranslation() {
    if (_extractedText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No text to explain')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExplainModePage(initialText: _extractedText),
      ),
    );
  }

  void _shareTranslation() {
    Share.share("$_extractedText\n\n$_translatedText");
  }

  void _showLanguagePicker(bool isSource) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: _displayLanguages.entries.map((e) {
            // Filter "auto" if offline and isSource
            // But we don't have easy access to 'isOffline' state here without checking connectivity again or passing it.
            // For now show all.
            return ListTile(
              title: Text(e.value, style: const TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  if (isSource) {
                    _sourceLanguageCode = e.key;
                  } else {
                    _targetLanguageCode = e.key;
                  }
                });
                Navigator.pop(ctx);
                // Rerun process if image exists?
              },
            );
          }).toList(),
        );
      },
    );
  }
}
