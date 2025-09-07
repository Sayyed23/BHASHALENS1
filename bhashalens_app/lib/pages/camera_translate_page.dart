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

  List<DropdownMenuItem<String>> _getLanguageDropdownItems() {
    // TODO: Implement language dropdown items
    return [];
  }

  void _changeTargetLanguage(String language) {
    // TODO: Implement target language change
  }

  void _shareText() {
    // TODO: Implement share text
  }

  void _saveTranslation() {
    // TODO: Implement save translation
  }

  void _resetCamera() {
    // TODO: Implement reset camera
  }
  Widget _buildImagePreview(File file) {
    try {
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, height: 120, width: double.infinity, fit: BoxFit.cover),
        );
      } else {
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
        );
      }
    } catch (e) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
      );
    }
  }
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
    final theme = Theme.of(context);
    return Positioned(
      bottom: 90,
      left: 12,
      right: 12,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_capturedImageFile != null) ...[
                _buildImagePreview(_capturedImageFile!),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Source:', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                        Text(_sourceLanguage, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target:', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                        DropdownButton<String>(
                          value: _targetLanguage,
                          isExpanded: true,
                          underline: Container(),
                          items: _getLanguageDropdownItems(),
                          onChanged: (value) {
                            if (value != null) _changeTargetLanguage(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isProcessing) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text('Processing with Gemini AI...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Original:', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                    const SizedBox(height: 6),
                    Text(_originalText, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Text('Translated:', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)),
                    const SizedBox(height: 6),
                    Text(_translatedText, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: _copyText,
                        icon: const Icon(Icons.copy, size: 22),
                        label: const Text('Copy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary.withOpacity(0.13),
                          foregroundColor: theme.colorScheme.secondary,
                          elevation: 0,
                          textStyle: theme.textTheme.labelLarge,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: _shareText,
                        icon: const Icon(Icons.share, size: 22),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.13),
                          foregroundColor: theme.colorScheme.primary,
                          elevation: 0,
                          textStyle: theme.textTheme.labelLarge,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: _saveTranslation,
                        icon: const Icon(Icons.save, size: 22),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.tertiary.withOpacity(0.13),
                          foregroundColor: theme.colorScheme.tertiary,
                          elevation: 0,
                          textStyle: theme.textTheme.labelLarge,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resetCamera,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Take Another Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  }

  Widget _buildFooterNavigationBlock() {
    return Builder(
      builder: (context) => Positioned(
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
      ),
    );
  }
