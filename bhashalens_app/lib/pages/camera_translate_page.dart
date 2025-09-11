import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/gemini_service.dart';
import 'package:bhashalens_app/pages/gemini_settings_page.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List

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
      await _processImageWithGemini(imageBytes); // Pass bytes to processing
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
                        style: TextStyle(color: Colors.white70),
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
        await _processImageWithGemini(
          _capturedImageBytes!,
        ); // Re-translate with new language
      }
    }
  }

  void _shareText() {
    if (_translatedText.isNotEmpty) {
      final shareText = 'Original: $_originalText\n\nTranslation: $_translatedText';
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

      final detectedLanguage = await geminiService.detectLanguage(text);
      final translatedText = await geminiService.translateText(
        text,
        _targetLanguage,
        sourceLanguage: detectedLanguage,
      );

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textInputController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
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

  Future<void> _processImageWithGemini(Uint8List imageBytes) async {
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
      final extractedText = await geminiService.extractTextFromImage(
        imageBytes,
      );

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
        _sourceLanguage = detectedLanguage; // Reintroduced
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
        await _processImageWithGemini(imageBytes); // Pass bytes to processing
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
  Widget _buildImagePreview(File file) {
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
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.broken_image, size: 40, color: Colors.white54),
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
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.broken_image, size: 40, color: Colors.white54),
              ),
            );
          },
        );
      } else {
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 40, color: Colors.white54),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.white54),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111C22),
      body: Column(
        children: [
          // Header with mode toggle - handles its own SafeArea
          SafeArea(
            bottom: false,
            child: _buildEnhancedHeader(),
          ),
          
          // Main content area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isTextMode
                  ? _buildTextTranslationView()
                  : _buildCameraTranslationView(),
            ),
          ),
          
          // Footer Navigation
          _buildFooterNavigationBlock(),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C22),
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
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              const Text(
                'Translate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GeminiSettingsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mode toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A33),
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
                        color: !_isTextMode ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: !_isTextMode ? Colors.white : Colors.white60,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Camera',
                            style: TextStyle(
                              color: !_isTextMode ? Colors.white : Colors.white60,
                              fontWeight: !_isTextMode ? FontWeight.bold : FontWeight.normal,
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
                        color: _isTextMode ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.text_fields,
                            color: _isTextMode ? Colors.white : Colors.white60,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Text',
                            style: TextStyle(
                              color: _isTextMode ? Colors.white : Colors.white60,
                              fontWeight: _isTextMode ? FontWeight.bold : FontWeight.normal,
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
          color: const Color(
            0xFF111C22,
          ).withOpacity(0.8), // Updated to match HTML header background
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Distribute space between items
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
              ), // Updated icon
            ),
            // Page title
            const Text(
              'Camera', // Updated title to match HTML
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Settings/Help icon
            IconButton(
              onPressed: () {
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

  Widget _buildCameraTranslationView() {
    if (_hasCapturedImage) {
      // Show translation results
      return _buildScrollableTranslationOutput();
    }
    
    // Show camera view with controls
    return Stack(
      children: [
        // Camera view fills the available space
        _buildCameraView(),
        
        // Action controls overlay
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: _buildActionControlsBlock(),
        ),
      ],
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

  Widget _buildTextTranslationView() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Input section
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A33),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Language selector bar
                _buildLanguageSelectionBar(),
                const Divider(color: Colors.white10, height: 1),
                // Text input field
                Container(
                  constraints: const BoxConstraints(minHeight: 150),
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _textInputController,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Enter text to translate...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.translate),
                    label: Text(_isProcessing ? 'Translating...' : 'Translate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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
            _buildTranslationResultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildScrollableTranslationOutput() {
    return Container(
      color: const Color(0xFF111C22),
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
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                        ),
                        child: _buildImagePreview(_capturedImageFile!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildLanguageSelectionBar(),
                  const SizedBox(height: 16),
                  _buildTranslationResultCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _resetCamera,
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: const Text(
                        'Take Another Photo',
                        style: TextStyle(color: Colors.white70),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2A33),
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

  Widget _buildTranslationResultCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original text
          if (_originalText.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _sourceLanguage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _originalText,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const Divider(color: Colors.white10, height: 24),
          ],
          // Translated text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _targetLanguage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade300,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_translatedText.isNotEmpty)
                Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _translatedText.isEmpty
                ? 'Translation will appear here...'
                : _translatedText,
            style: TextStyle(
              fontSize: _translatedText.isEmpty ? 15 : 18,
              fontWeight: _translatedText.isEmpty ? FontWeight.normal : FontWeight.w600,
              color: _translatedText.isEmpty ? Colors.white30 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.content_copy,
          label: 'Copy',
          onTap: _copyText,
          color: Colors.blue,
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
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionControlsBlock() {
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gallery import button
                GestureDetector(
                  onTap: _isProcessing ? null : _importFromGallery,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const Icon(Icons.photo_library, color: Colors.white),
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
                      border: Border.all(color: Colors.white, width: 4),
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
                        ? const Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
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
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTranslationOutputBlock() {
    return Positioned(
      bottom: 90,
      left: 0,
      right: 0,
      child: Container(
        color: const Color(0xFF111C22), // Background color from HTML
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_capturedImageFile != null && _hasCapturedImage) ...[
              _buildImagePreview(_capturedImageFile!),
              const SizedBox(height: 16),
            ],
            _buildLanguageSelectionBar(), // Integrated language selection bar
            const SizedBox(height: 16),
            // Translated text block
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A33), // Secondary color from HTML
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'English (Detected)', // Hardcoded as per HTML, consider making dynamic later
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF92B7C9), // Text muted color
                        ),
                      ),
                      const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ), // Close icon
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _originalText.isEmpty
                        ? 'Welcome to our translation app.'
                        : _originalText, // Placeholder or actual text
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const Divider(color: Colors.white10, height: 24), // Divider
                  Text(
                    _translatedText.isEmpty
                        ? 'Bienvenue dans notre application de traduction.'
                        : _translatedText, // Placeholder or actual text
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons (Copy, Share, Save)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildTextActionButton(Icons.content_copy, 'Copy', _copyText),
                const SizedBox(width: 16),
                _buildTextActionButton(Icons.share, 'Share', _shareText),
                const SizedBox(width: 16),
                _buildTextActionButton(
                  Icons.bookmark_border,
                  'Save',
                  _saveTranslation,
                ),
              ],
            ),
            const SizedBox(height: 16), // Added space
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _resetCamera,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white70,
                ), // Icon and color
                label: const Text(
                  'Take Another Photo',
                  style: TextStyle(color: Colors.white70), // Text color
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF1A2A33,
                  ), // Secondary color from HTML
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
    );
  }

  Widget _buildTextActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Helper method to build the language selection bar
  Widget _buildLanguageSelectionBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A33), // var(--secondary-color)
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
                foregroundColor: Colors.white.withOpacity(0.5),
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
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withOpacity(0.1), // Divider color
          ),
          Expanded(
            child: TextButton(
              onPressed: () {
                _selectTargetLanguage(); // Call the new method for language selection
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more, size: 16), // Dropdown icon
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNavigationBlock() {
    return Container(
      color: const Color(0xFF192B33).withOpacity(0.9),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
        left: 8,
        right: 8,
      ),
      child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(Icons.home, 'Home', '/home', Colors.grey),
              _buildNavBarItem(
                Icons.photo_camera,
                'Camera',
                '/camera_translate',
                Colors.white,
                isSelected: true,
              ), // Selected camera icon
              _buildNavBarItem(
                Icons.mic,
                'Voice',
                '/voice_translate',
                Colors.grey,
              ),
              _buildNavBarItem(
                Icons.bookmark,
                'Saved',
                '/saved_translations',
                Colors.grey,
              ),
              _buildNavBarItem(
                Icons.settings,
                'Settings',
                '/settings',
                Colors.grey,
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
              color: isSelected ? Colors.white : const Color(0xFF92B7C9),
            ), // Text muted color
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF92B7C9),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
