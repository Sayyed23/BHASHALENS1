import 'package:flutter/material.dart';
import 'package:bhashalens_app/services/ml_kit_translation_service.dart';

class OfflineModelsPage extends StatefulWidget {
  const OfflineModelsPage({super.key});

  @override
  State<OfflineModelsPage> createState() => _OfflineModelsPageState();
}

class _OfflineModelsPageState extends State<OfflineModelsPage> {
  final _mlKitService = MlKitTranslationService();
  final List<Map<String, String>> _supportedLanguages =
      MlKitTranslationService().getSupportedLanguages();

  // Track status of downloads: 'downloaded', 'downloading', 'not_downloaded'
  final Map<String, String> _modelStatus = {};

  // Theme Colors
  static const Color bgDark = Color(0xFF101822);
  static const Color cardDark = Color(0xFF1C222B);
  static const Color primaryBlue = Color(0xFF136DEC);
  static const Color textGrey = Color(0xFF94A3B8);
  static const Color dividerColor = Color(0xFF2D3748);

  @override
  void initState() {
    super.initState();
    _checkDownloadedModels();
  }

  Future<void> _checkDownloadedModels() async {
    final downloaded = await _mlKitService.getDownloadedModels();
    if (mounted) {
      setState(() {
        // First reset all
        for (var lang in _supportedLanguages) {
          final code = lang['code']!;
          if (_modelStatus[code] != 'downloading') {
            _modelStatus[code] = 'not_downloaded';
          }
        }
        // Mark downloaded
        for (var code in downloaded) {
          _modelStatus[code] = 'downloaded';
        }
      });
    }

    // Verify individual (optional but safe)
    for (var lang in _supportedLanguages) {
      final code = lang['code']!;
      final isDownloaded = await _mlKitService.isModelDownloaded(code);
      if (mounted) {
        setState(() {
          if (_modelStatus[code] != 'downloading') {
            _modelStatus[code] = isDownloaded ? 'downloaded' : 'not_downloaded';
          }
        });
      }
    }
  }

  Future<void> _downloadModel(String code) async {
    setState(() {
      _modelStatus[code] = 'downloading';
    });

    final success = await _mlKitService.downloadModel(code);

    if (mounted) {
      setState(() {
        _modelStatus[code] = success ? 'downloaded' : 'not_downloaded';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Model downloaded successfully' : 'Download failed',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteModel(String code) async {
    setState(() {
      _modelStatus[code] = 'deleting';
    });

    final success = await _mlKitService.deleteModel(code);

    if (mounted) {
      setState(() {
        _modelStatus[code] = success ? 'not_downloaded' : 'downloaded';
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Model deleted',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          'Offline Models',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Info card about bidirectional translation
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Bidirectional Translation',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'For translation between non-English languages, both language models plus English are required. English acts as an intermediate language.',
                  style: TextStyle(color: textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          // Language models list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _supportedLanguages.length,
              itemBuilder: (context, index) {
                final lang = _supportedLanguages[index];
                final code = lang['code']!;
                final name = lang['name']!;
                final status = _modelStatus[code] ?? 'loading';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: dividerColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          code.toUpperCase(),
                          style: const TextStyle(color: textGrey, fontSize: 13),
                        ),
                        if (code == 'en')
                          const Text(
                            'Required for non-English to non-English translation',
                            style: TextStyle(color: primaryBlue, fontSize: 11),
                          ),
                      ],
                    ),
                    trailing: _buildActionAndStatus(code, status),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionAndStatus(String code, String status) {
    if (status == 'loading' || status == 'deleting') {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
      );
    } else if (status == 'downloading') {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Downloading...",
            style: TextStyle(color: primaryBlue, fontSize: 12),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryBlue,
            ),
          ),
        ],
      );
    } else if (status == 'downloaded') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF22C55E),
            size: 20,
          ), // Green check
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFEF5350),
            ), // Red delete
            onPressed: () => _deleteModel(code),
            tooltip: "Delete Model",
          ),
        ],
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.download_rounded, color: primaryBlue, size: 26),
        onPressed: () => _downloadModel(code),
        tooltip: "Download Model",
      );
    }
  }
}
