import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/services/hybrid_translation_service.dart';
import 'package:bhashalens_app/services/sarvam_service.dart';
import 'package:bhashalens_app/widgets/backend_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
// Removed unused dart:typed_data import

class SimplifyModePage extends StatefulWidget {
  const SimplifyModePage({super.key});

  @override
  State<SimplifyModePage> createState() => _SimplifyModePageState();
}

class _SimplifyModePageState extends State<SimplifyModePage> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String _simplifiedText = '';
  String? _explanation;
  String? _backend;
  bool _isLoading = false;
  String _selectedLanguage = 'hi';
  String _targetComplexity = 'simple';

  final Map<String, String> _languages = {
    'hi': 'Hindi',
    'mr': 'Marathi',
    'ta': 'Tamil',
    'te': 'Telugu',
    'bn': 'Bengali',
    'en': 'English',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processSimplify() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _simplifiedText = '';
      _explanation = null;
      _backend = null;
    });

    try {
      final hybridService = Provider.of<HybridTranslationService>(context, listen: false);
      final result = await hybridService.simplifyText(
        text: text,
        targetComplexity: _targetComplexity,
        language: _selectedLanguage,
        includeExplanation: true,
      );

      if (mounted) {
        setState(() {
          _simplifiedText = result.simplifiedText;
          _explanation = result.explanation;
          _backend = result.backend.name == 'awsBedrock' ? 'bedrock' : 'gemini';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanText() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final sarvamService = Provider.of<SarvamService>(context, listen: false);
      final extractedText = await sarvamService.performOCR(base64Image);

      if (mounted && extractedText.isNotEmpty) {
        setState(() {
          _controller.text = extractedText;
          _isLoading = false;
        });
        _processSimplify();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not extract text from image")),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OCR Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explain & Simplify"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_backend != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BackendIndicator(backend: _backend!),
              ),
            
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Enter complex text or scan a document...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _scanText,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(labelText: "Language"),
                    items: _languages.entries.map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedLanguage = val!),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _targetComplexity,
                    decoration: const InputDecoration(labelText: "Simplicity"),
                    items: const [
                      DropdownMenuItem(value: 'simple', child: Text("Very Simple")),
                      DropdownMenuItem(value: 'moderate', child: Text("Moderate")),
                      DropdownMenuItem(value: 'complex', child: Text("Professional")),
                    ],
                    onChanged: (val) => setState(() => _targetComplexity = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processSimplify,
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text("Simplify Now"),
              ),
            ),
            
            if (_simplifiedText.isNotEmpty) ...[
              const SizedBox(height: 30),
              _buildResultCard("Simplified Meaning", _simplifiedText, Icons.auto_awesome),
              if (_explanation != null) ...[
                const SizedBox(height: 20),
                _buildResultCard("Educational Insight", _explanation!, Icons.lightbulb),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String content, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            Text(content, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
