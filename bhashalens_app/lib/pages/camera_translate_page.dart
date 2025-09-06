import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/pages/gemini_settings_page.dart';
import 'dart:io';

class CameraTranslatePage extends StatefulWidget {
  const CameraTranslatePage({super.key});

  @override
  State<CameraTranslatePage> createState() => _CameraTranslatePageState();
}

class _CameraTranslatePageState extends State<CameraTranslatePage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _hasCapturedImage = false;
  String _originalText = '';
  String _translatedText = '';
  String _sourceLanguage = 'Auto-detected';
  String _targetLanguage = 'English';
  bool _isProcessing = false;
  File? _capturedImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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

        try {
          await _cameraController!.initialize();
          setState(() {
            _isCameraInitialized = true;
          });
        } catch (e) {
          debugPrint('Error initializing camera: $e');
        }
      }
    } catch (e) {
      debugPrint('Camera not available on this platform: $e');
      // For platforms without camera support (like Windows), show a placeholder
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      setState(() {
        _capturedImageFile = imageFile;
        _hasCapturedImage = true;
      });

      // Process with Gemini service
      await _processImageWithGemini(imageFile);
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

  Future<void> _processImageWithGemini(File imageFile) async {
    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);

      if (!geminiService.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please configure Gemini API key in settings first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      // Detect language first, then translate
      final extractedText = await geminiService.extractTextFromImage(imageFile);

      if (extractedText.isEmpty || extractedText == 'No text detected') {
        setState(() {
          _originalText = extractedText;
          _translatedText = 'No text to translate';
        });
        return;
      }

      final detectedLanguage = await geminiService.detectLanguage(
        extractedText,
      );
      final translatedText = await geminiService.translateText(
        extractedText,
        _targetLanguage,
        sourceLanguage: detectedLanguage,
      );

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
        final imageFile = File(image.path);
        setState(() {
          _capturedImageFile = imageFile;
          _hasCapturedImage = true;
        });

        // Process with Gemini service
        await _processImageWithGemini(imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error importing image: $e')));
    }
  }

  void _copyText() {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Text copied to clipboard!')));
  }

  void _shareText() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _saveTranslation() {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Translation saved!')));
  }

  void _resetCamera() {
    setState(() {
      _hasCapturedImage = false;
      _originalText = '';
      _translatedText = '';
      _capturedImageFile = null;
      _sourceLanguage = 'Auto-detected';
    });
  }

  void _changeTargetLanguage(String language) {
    setState(() {
      _targetLanguage = language;
    });

    // Re-translate if we have extracted text
    if (_originalText.isNotEmpty && _originalText != 'No text detected') {
      _retranslateText();
    }
  }

  Future<void> _retranslateText() async {
    if (_originalText.isEmpty || _originalText == 'No text detected') return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final translatedText = await geminiService.translateText(
        _originalText,
        _targetLanguage,
        sourceLanguage: _sourceLanguage,
      );

      setState(() {
        _translatedText = translatedText;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error re-translating: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  List<DropdownMenuItem<String>> _getLanguageDropdownItems() {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    return geminiService.getSupportedLanguages().map((language) {
      return DropdownMenuItem<String>(
        value: language['name']!,
        child: Text(language['name']!, style: const TextStyle(fontSize: 14)),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Live Camera View Block
          _buildCameraView(),

          // Header Block
          _buildHeaderBlock(),

          // Action Controls Block (overlaid on camera)
          if (!_hasCapturedImage) _buildActionControlsBlock(),

          // Translation Output Block
          if (_hasCapturedImage) _buildTranslationOutputBlock(),

          // Footer Navigation Block
          _buildFooterNavigationBlock(),
        ],
      ),
    );
  }

  Widget _buildHeaderBlock() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const Spacer(),
            // Page title
            const Text(
              'Camera Translate',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Settings/Help icon
            IconButton(
              onPressed: () {
                // TODO: Implement settings/help
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings/Help coming soon!')),
                );
              },
              icon: const Icon(Icons.help_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 80, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Camera Preview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Camera functionality is available on mobile devices',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Tap the capture button to simulate photo capture',
                style: TextStyle(color: Colors.white60, fontSize: 14),
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
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.crop_free, color: Colors.white, size: 40),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionControlsBlock() {
    return Positioned(
      bottom: 100, // Above footer navigation
      left: 0,
      right: 0,
      child: Container(
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
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Configure Gemini API Key',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const GeminiSettingsPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gallery import button
                FloatingActionButton(
                  heroTag: 'gallery_button',
                  onPressed: _isProcessing ? null : _importFromGallery,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.photo_library, color: Colors.white),
                ),

                // Large circular capture button
                FloatingActionButton(
                  heroTag: 'capture_button',
                  onPressed: _isProcessing ? null : _captureImage,
                  backgroundColor: Colors.white,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera,
                            color: Colors.black,
                            size: 40,
                          ),
                  ),
                ),

                // Flash toggle button
                FloatingActionButton(
                  heroTag: 'flash_button',
                  onPressed: _isProcessing ? null : _toggleFlash,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationOutputBlock() {
    return Positioned(
      bottom: 100, // Above footer navigation
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Captured Image Preview
            if (_capturedImageFile != null) ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_capturedImageFile!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Language Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Source:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _sourceLanguage,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _targetLanguage,
                        isExpanded: true,
                        underline: Container(),
                        items: _getLanguageDropdownItems(),
                        onChanged: (value) {
                          if (value != null) {
                            _changeTargetLanguage(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Processing Status
            if (_isProcessing) ...[
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Processing with Gemini AI...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Original Text and Translated Text (combined view)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Original:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_originalText, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  const Text(
                    'Translated:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _translatedText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _copyText,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareText,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[200],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveTranslation,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[200],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Reset button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _resetCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('Take Another Photo'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNavigationBlock() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 1, // Camera tab
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Camera',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacementNamed('/home');
                break;
              case 1:
                // Already on camera page
                break;
              case 2:
                Navigator.of(context).pushReplacementNamed('/voice_translate');
                break;
              case 3:
                Navigator.of(context).pushReplacementNamed('/saved_translations');
                break;
              case 4:
                Navigator.of(context).pushReplacementNamed('/settings');
                break;
            }
          },
        ),
      ),
    );
  }
}
