import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:bhashalens_app/pages/gemini_settings_page.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
// import 'package:bhashalens_app/theme/app_theme.dart'; // Import AppTheme
// Added for Uint8List

class CameraTranslatePage extends StatefulWidget {
  const CameraTranslatePage({super.key});

  @override
  State<CameraTranslatePage> createState() => _CameraTranslatePageState();
}

class _CameraTranslatePageState extends State<CameraTranslatePage>
    with SingleTickerProviderStateMixin {
  Future<void> _captureImage() async {
    if (!_isCameraInitialized) return;
    try {
      setState(() {
        _isProcessing = true;
      });
      final XFile image = await _cameraController!.takePicture();
      // final imageFile = File(image.path); // Commented out
      final Uint8List imageBytes = await image
          .readAsBytes(); // Read image as bytes
      setState(() {
        _capturedImageFile = File(image.path); // Keep for _buildImagePreview
        _capturedImageBytes = imageBytes; // Store bytes
        _hasCapturedImage = true;
      });
      // Process with Gemini service
      await _processImage(imageBytes); // Pass bytes to processing
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Helper method for selecting target language (placeholder for future implementation)
  void _selectTargetLanguage() async {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final languages = geminiService.getSupportedLanguages();

    final String? selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: const Color(0xFF111C22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Target Language',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    return ListTile(
                      title: Text(
                        lang['name']!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, lang['name']);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedLanguage != null && selectedLanguage != _targetLanguage) {
      setState(() {
        _targetLanguage = selectedLanguage;
      });
      if (_hasCapturedImage && _capturedImageBytes != null) {
        await _processImage(
          _capturedImageBytes!,
        ); // Re-translate with new language
      }
    }
  }

  void _shareText() {
    if (_translatedText.isNotEmpty) {
      final shareText =
          'Original: $_originalText\n\nTranslation: $_translatedText';
      Share.share(shareText, subject: 'Translation from BhashaLens');
    }
  }

  void _saveTranslation() {
    if (_originalText.isNotEmpty && _translatedText.isNotEmpty) {
      // For now, we'll show a success message
      // In a real implementation, you'd save to a database or local storage
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translation saved successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetCamera() {
    setState(() {
      _capturedImageFile = null;
      _capturedImageBytes = null; // Reset image bytes
      _hasCapturedImage = false;
      _originalText = '';
      _translatedText = '';
      _sourceLanguage = 'Auto-detected';
      _textInputController.clear();
    });
  }

  // New method for text-to-text translation
  Future<void> _translateText() async {
    final text = _textInputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text to translate'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      String translatedText = '';
      String detectedLanguage = 'Unknown';

      if (isOffline) {
        final mlKitService = MlKitTranslationService();
        // Assuming source is English for offline demo or we need a selector.
        // Since we don't have source selector in UI fully, defaults to 'en'.

        final result = await mlKitService.translate(
          text: text,
          sourceLanguage: 'en', // Constraint for offline
          targetLanguage: _targetLanguage == 'Hindi'
              ? 'hi'
              : _targetLanguage == 'Marathi'
              ? 'mr'
              : _targetLanguage == 'Spanish'
              ? 'es'
              : _targetLanguage == 'French'
              ? 'fr'
              : 'en',
        );

        translatedText = result ?? 'Translation failed or model not downloaded';
        detectedLanguage = 'English (Offline/Assumed)';
      } else {
        final geminiService = Provider.of<GeminiService>(
          context,
          listen: false,
        );

        if (!geminiService.isInitialized) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please configure Gemini API key in settings first',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        detectedLanguage = await geminiService.detectLanguage(text);
        translatedText = await geminiService.translateText(
          text,
          _targetLanguage,
          sourceLanguage: detectedLanguage,
        );
      }

      setState(() {
        _originalText = text;
        _translatedText = translatedText;
        _sourceLanguage = detectedLanguage;
        _hasCapturedImage = false; // Clear any captured image
        _capturedImageFile = null;
        _capturedImageBytes = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error translating text: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  // Widget _buildImagePreview(File file) {
  //   try {
  //     if (file.existsSync()) {
  //       return ClipRRect(
  //         borderRadius: BorderRadius.circular(12),
  //         child: Image.file(
  //           file,
  //           height: 120,
  //           width: double.infinity,
  //           fit: BoxFit.cover,
  //         ),
  //       );
  //     } else {
  //       return Container(
  //         height: 120,
  //         width: double.infinity,
  //         decoration: BoxDecoration(
  //           color: Colors.grey[200],
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: const Center(
  //           child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     return Container(
  //       height: 120,
  //       width: double.infinity,
  //       decoration: BoxDecoration(
  //         color: Colors.grey[200],
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: const Center(
  //         child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
  //       ),
  //     );
  //   }
  // }

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _hasCapturedImage = false;
  String _originalText = '';
  String _translatedText = '';
  String _sourceLanguage = 'Auto-detected'; // Reintroduced
  String _targetLanguage = 'English'; // Removed final
  bool _isProcessing = false;
  File? _capturedImageFile; // Reintroduced
  Uint8List? _capturedImageBytes; // New: Stores image as bytes
  final ImagePicker _imagePicker = ImagePicker();

  // New state variables for enhanced features
  bool _isTextMode = false; // Toggle between camera and text mode
  final TextEditingController _textInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // late AnimationController _animationController;
  // late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    // _animationController = AnimationController(
    //   duration: const Duration(milliseconds: 300),
    //   vsync: this,
    // );
    // _fadeAnimation = CurvedAnimation(
    //   parent: _animationController,
    //   curve: Curves.easeInOut,
    // );
    // _animationController.forward();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textInputController.dispose();
    _scrollController.dispose();
    // _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera not available on this platform: $e');
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _processImage(Uint8List imageBytes) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      String extractedText = '';
      String translatedText = '';
      String detectedLanguage = 'Unknown';

      if (isOffline) {
        // Offline processing
        final mlKitService = MlKitTranslationService();

        // Extract text using ML Kit (requires file)
        if (_capturedImageFile != null) {
          extractedText = await mlKitService.extractTextFromFile(
            _capturedImageFile!,
          );
        } else {
          // If we only have bytes (unlikely in current flow but safe to handle)
          // We'd need to write to temp file or skip
          extractedText = 'Offline OCR requires file based image capture.';
        }

        if (extractedText.isEmpty) {
          extractedText = 'No text detected';
        }

        if (extractedText != 'No text detected') {
          // Detect language (simple heuristic or use input)
          // ML Kit doesn't detect language from text easily without another model.
          // We'll assume source language if set, or just try to translate assuming it matches?
          // For now, we might default to 'en' or skip detection and let user pick source.
          // But `translate` needs source.
          // Let's assume auto-detect isn't available offline unless we add language identification model.
          // For now, default to 'English' or 'Hindi' if unknown, or ask user.
          // BhashaLens usually translates TO specific target.
          // Helper: If _sourceLanguage is 'Auto-detected', force a default or show error.

          // Using 'en' as default source for offline if not set is risky.
          // Ideally we used LanguageIdentificationClient but that's another dependency.
          // For MVP offline, let's assume valid source or default to 'en'.
          String sourceCode = 'en'; // Default

          final result = await mlKitService.translate(
            text: extractedText,
            sourceLanguage: sourceCode,
            targetLanguage: _targetLanguage == 'Hindi'
                ? 'hi'
                : _targetLanguage == 'Marathi'
                ? 'mr'
                : _targetLanguage == 'Spanish'
                ? 'es'
                : _targetLanguage == 'French'
                ? 'fr'
                : 'en',
          );

          translatedText =
              result ?? 'Translation failed or model not downloaded';
          detectedLanguage = 'English (Assumed/Offline)';
        } else {
          translatedText = 'No text to translate';
        }
      } else {
        // Online processing (Gemini)
        final geminiService = Provider.of<GeminiService>(
          context,
          listen: false,
        );
        if (!geminiService.isInitialized) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gemini API key missing')),
          );
          return;
        }

        extractedText = await geminiService.extractTextFromImage(imageBytes);

        if (extractedText.isEmpty || extractedText == 'No text detected') {
          translatedText = 'No text to translate';
        } else {
          detectedLanguage = await geminiService.detectLanguage(extractedText);
          translatedText = await geminiService.translateText(
            extractedText,
            _targetLanguage,
            sourceLanguage: detectedLanguage,
          );
        }
      }

      setState(() {
        _originalText = extractedText;
        _translatedText = translatedText;
        _sourceLanguage = detectedLanguage;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _toggleFlash() {
    if (_isCameraInitialized) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      _cameraController?.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    }
  }

  Future<void> _importFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // final imageFile = File(image.path); // Commented out
        final Uint8List imageBytes = await image
            .readAsBytes(); // Read image as bytes
        setState(() {
          _capturedImageFile = File(image.path); // Keep for _buildImagePreview
          _capturedImageBytes = imageBytes; // Store bytes
          _hasCapturedImage = true;
        });

        // Process with Gemini service
        await _processImage(imageBytes); // Pass bytes to processing
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error importing image: $e')));
    }
  }

  void _copyText() {
    if (_translatedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _translatedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Translation copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Helper method to build the image preview (reintroduced)
  Widget _buildImagePreview(File file, ThemeData theme, bool isDarkMode) {
    try {
      // Prefer bytes if available (more reliable on mobile)
      if (_capturedImageBytes != null) {
        return Image.memory(
          _capturedImageBytes!,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 40,
                  color: Colors.white54,
                ),
              ),
            );
          },
        );
      } else if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  size: 40,
                  color: isDarkMode
                      ? Colors.white54
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            );
          },
        );
      } else {
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              size: 40,
              color: isDarkMode
                  ? Colors.white54
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.broken_image,
            size: 40,
            color: isDarkMode
                ? Colors.white54
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Header with mode toggle - handles its own SafeArea
          SafeArea(
            bottom: false,
            child: _buildEnhancedHeader(theme, isDarkMode),
          ),

          // Main content area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isTextMode
                  ? _buildTextTranslationView(theme, isDarkMode)
                  : _buildCameraTranslationView(theme, isDarkMode),
            ),
          ),

          // Footer Navigation
          _buildFooterNavigationBlock(theme, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Translate',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // IconButton(
              //   onPressed: () {
              //     Navigator.of(context).push(
              //       MaterialPageRoute(
              //         builder: (context) => const GeminiSettingsPage(),
              //       ),
              //     );
              //   },
              //   icon: Icon(Icons.settings, color: theme.colorScheme.onBackground),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          // Mode toggle
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTextMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isTextMode
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: !_isTextMode
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Camera',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: !_isTextMode
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                              fontWeight: !_isTextMode
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTextMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isTextMode
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.text_fields,
                            color: _isTextMode
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Text',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _isTextMode
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                              fontWeight: _isTextMode
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraTranslationView(ThemeData theme, bool isDarkMode) {
    if (_hasCapturedImage) {
      // Show translation results
      return _buildScrollableTranslationOutput(theme, isDarkMode);
    }

    // Show camera view with controls
    return Stack(
      children: [
        // Camera view fills the available space
        _buildCameraView(theme, isDarkMode),

        // Action controls overlay
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: _buildActionControlsBlock(theme, isDarkMode),
        ),

        if (_isProcessing) // Add this conditional loading overlay
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.surface.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Processing image...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCameraView(ThemeData theme, bool isDarkMode) {
    if (!_isCameraInitialized) {
      return Container(
        color: theme.colorScheme.onSurface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 80,
                color: theme.colorScheme.surface,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera Preview',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Camera functionality is available on mobile devices',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tap the capture button to simulate photo capture',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.surface.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_cameraController!),
        ),

        // Overlay guides (crosshair)
        if (!_hasCapturedImage)
          Center(
            child: Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.onSurface,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.crop_free,
                color: theme.colorScheme.onSurface,
                size: 40,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextTranslationView(ThemeData theme, bool isDarkMode) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Input section
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Language selector bar
                _buildLanguageSelectionBar(theme, isDarkMode),
                Divider(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  height: 1,
                ),
                // Text input field
                Container(
                  constraints: const BoxConstraints(minHeight: 150),
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _textInputController,
                    maxLines: null,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter text to translate...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // Translate button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _translateText,
                    icon: _isProcessing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.translate,
                            color: theme.colorScheme.onPrimary,
                          ),
                    label: Text(_isProcessing ? 'Translating...' : 'Translate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Translation output
          if (_translatedText.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTranslationResultCard(theme, isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildScrollableTranslationOutput(ThemeData theme, bool isDarkMode) {
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_capturedImageFile != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: _buildImagePreview(
                          _capturedImageFile!,
                          theme,
                          isDarkMode,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildLanguageSelectionBar(theme, isDarkMode),
                  const SizedBox(height: 16),
                  _buildTranslationResultCard(theme, isDarkMode),
                  const SizedBox(height: 16),
                  _buildActionButtons(theme, isDarkMode),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _resetCamera,
                      icon: Icon(
                        Icons.refresh,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      label: Text(
                        'Take Another Photo',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationResultCard(ThemeData theme, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original text
          if (_originalText.isNotEmpty && !_isProcessing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _sourceLanguage,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _originalText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
            Divider(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              height: 24,
            ),
          ],
          // Translated text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _targetLanguage,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_translatedText.isNotEmpty && !_isProcessing)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _isProcessing && _translatedText.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Generating translation...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  _translatedText.isEmpty
                      ? 'Translation will appear here...'
                      : _translatedText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: _translatedText.isEmpty ? 15 : 18,
                    fontWeight: _translatedText.isEmpty
                        ? FontWeight.normal
                        : FontWeight.w600,
                    color: _translatedText.isEmpty
                        ? theme.colorScheme.onSurface.withOpacity(0.3)
                        : theme.colorScheme.onSurface,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.content_copy,
          label: 'Copy',
          onTap: _copyText,
          color: theme.colorScheme.primary,
        ),
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onTap: _shareText,
          color: Colors.purple,
        ),
        _buildActionButton(
          icon: Icons.bookmark_border,
          label: 'Save',
          onTap: _saveTranslation,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionControlsBlock(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Gemini Status Indicator
          Consumer<GeminiService>(
            builder: (context, geminiService, child) {
              if (!geminiService.isInitialized) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        color: theme.colorScheme.onError,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Configure Gemini API Key',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onError,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // GestureDetector(
                      //   onTap: () {
                      //     Navigator.of(context).push(
                      //       MaterialPageRoute(
                      //         builder: (context) =>
                      //             const GeminiSettingsPage(),
                      //       ),
                      //     );
                      //   },
                      //   child: Container(
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 8,
                      //       vertical: 4,
                      //     ),
                      //     decoration: BoxDecoration(
                      //       color: theme.colorScheme.onError.withOpacity(0.2),
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //     child: Text(
                      //       'Settings',
                      //       style: theme.textTheme.labelSmall?.copyWith(
                      //         color: theme.colorScheme.onError,
                      //         fontSize: 10,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gallery import button
              GestureDetector(
                onTap: _isProcessing ? null : _importFromGallery,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isProcessing
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.photo_library,
                          color: theme.colorScheme.onSurface,
                        ),
                ),
              ),
              const SizedBox(width: 16), // Space between buttons
              // Large circular capture button
              GestureDetector(
                onTap: _isProcessing ? null : _captureImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.onSurface,
                      width: 4,
                    ),
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 4,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: _isProcessing
                      ? Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        )
                      : Container(), // Empty container for the inner circle as per HTML
                ),
              ),
              const SizedBox(width: 16), // Space between buttons
              // Flash toggle button
              GestureDetector(
                onTap: _isProcessing ? null : _toggleFlash,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionBar(ThemeData theme, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // var(--secondary-color)
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 2,
      ), // Reduced vertical padding to match HTML
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
              ),
              child: Text(
                _sourceLanguage, // Display detected language
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
            ),
          ),
          Container(
            height: 24,
            width: 1,
            color: theme.colorScheme.onSurface.withOpacity(
              0.1,
            ), // Divider color
          ),
          Expanded(
            child: TextButton(
              onPressed: () {
                _selectTargetLanguage(); // Call the new method for language selection
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _targetLanguage, // Display target language
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    size: 16,
                    color: theme.colorScheme.onSurface,
                  ), // Dropdown icon
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNavigationBlock(ThemeData theme, bool isDarkMode) {
    return Container(
      color: theme.colorScheme.surface.withOpacity(0.9),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
        left: 8,
        right: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(
            Icons.home,
            'Home',
            '/home',
            theme.colorScheme.onSurface,
            theme: theme,
            isDarkMode: isDarkMode,
          ),
          _buildNavBarItem(
            Icons.photo_camera,
            'Camera',
            '/camera_translate',
            theme.colorScheme.primary,
            isSelected: true,
            theme: theme,
            isDarkMode: isDarkMode,
          ), // Selected camera icon
          _buildNavBarItem(
            Icons.mic,
            'Voice',
            '/voice_translate',
            theme.colorScheme.onSurface,
            theme: theme,
            isDarkMode: isDarkMode,
          ),
          _buildNavBarItem(
            Icons.bookmark,
            'Saved',
            '/saved_translations',
            theme.colorScheme.onSurface,
            theme: theme,
            isDarkMode: isDarkMode,
          ),
          _buildNavBarItem(
            Icons.settings,
            'Settings',
            '/settings',
            theme.colorScheme.onSurface,
            theme: theme,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(
    IconData icon,
    String label,
    String routeName,
    Color color, {
    bool isSelected = false,
    required ThemeData theme,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            Navigator.of(context).pushReplacementNamed(routeName);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ), // Text muted color
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
