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
  final Map<String, double> _downloadProgress = {};
  bool _wifiOnly = true;

  // Theme Colors
  static const Color bgDark = Color(0xFF141920); // main background
  static const Color cardDark = Color(0xFF1E2530); // card background
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color textGrey = Color(0xFF8A9AAB);
  static const Color dividerColor = Color(0xFF28313F);

  @override
  void initState() {
    super.initState();
    _checkDownloadedModels();
  }

  Future<void> _checkDownloadedModels() async {
    final downloaded = await _mlKitService.getDownloadedModels();
    if (mounted) {
      setState(() {
        for (var lang in _supportedLanguages) {
          final code = lang['code']!;
          if (_modelStatus[code] != 'downloading') {
            _modelStatus[code] = 'not_downloaded';
          }
        }
        for (var code in downloaded) {
          _modelStatus[code] = 'downloaded';
        }
      });
    }

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
      _downloadProgress[code] = 0.0;
    });

    // Start a timer/loop to increment progress up to 90%
    void simulateProgress() async {
      for (int i = 0; i <= 90; i += 5) {
        if (!mounted || _modelStatus[code] != 'downloading') break;
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted && _modelStatus[code] == 'downloading') {
          setState(() {
            _downloadProgress[code] = i / 100.0;
          });
        }
      }
    }
    
    simulateProgress();

    final success = await _mlKitService.downloadModel(code);

    if (mounted && _modelStatus[code] == 'downloading') {
      setState(() {
        _downloadProgress[code] = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _modelStatus[code] = success ? 'downloaded' : 'not_downloaded';
          _downloadProgress.remove(code);
        });
        if (!success) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Download failed'), backgroundColor: Colors.red),
           );
        }
      }
    }
  }

  void _cancelDownload(String code) {
    setState(() {
      _modelStatus[code] = 'not_downloaded';
      _downloadProgress.remove(code);
    });
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
        // Optional snippet if you want to notify users about deletion
      }
    }
  }

  Color _getFlagColor(String code) {
    switch (code) {
      case 'hi': return const Color(0xFF6E432A);
      case 'ta': return const Color(0xFF29406B);
      case 'bn': return const Color(0xFF285C42);
      case 'mr': return const Color(0xFF6B3037);
      case 'te': return const Color(0xFF423B69);
      case 'en': return const Color(0xFF1F4E79);
      default: return const Color(0xFF4A5568);
    }
  }

  String _getMockSize(String code) {
    switch (code) {
      case 'hi': return '42.5 MB';
      case 'ta': return '45.1 MB';
      case 'bn': return '38.2 MB';
      case 'mr': return '35.0 MB';
      case 'te': return '41.8 MB';
      case 'en': return '30.0 MB';
      default: return '39.4 MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text(
          'Offline Packs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: dividerColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Why download offline?" Info card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF142033), // Slightly blue tinted background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A2A44)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: primaryBlue, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Why download offline?',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Translate text and use accessibility features even without an internet connection.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Learn More',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Storage Usage Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Storage Usage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '245 MB / 2 GB',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF28313F),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        height: 6,
                        width: 40, // Mock usage width
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '1.75 GB Available on device',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(color: dividerColor, height: 1),
            ),
            
            // LANGUAGE PACKS Header
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Text(
                'LANGUAGE PACKS',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            // Language Packs List
            ..._supportedLanguages.map((lang) {
              final code = lang['code']!;
              final name = lang['name']!;
              final status = _modelStatus[code] ?? 'not_downloaded';
              final size = _getMockSize(code);
              final progress = _downloadProgress[code] ?? 0.0;
              final flagColor = _getFlagColor(code);

              return Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Flag Icon
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: flagColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (status == 'downloading')
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: dividerColor,
                                        valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: primaryBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                status == 'downloaded' ? '$size • Downloaded' : size,
                                style: const TextStyle(
                                  color: textGrey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Actions
                      const SizedBox(width: 16),
                      _buildAction(code, status),
                    ],
                  ),
                ),
              );
            }),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(color: dividerColor, height: 1),
            ),
            
            // Wi-Fi Only Switch
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wi-Fi Only Downloads',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Save mobile data by downloading only on Wi-Fi',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _wifiOnly,
                    onChanged: (val) {
                      setState(() {
                        _wifiOnly = val;
                      });
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: primaryBlue,
                    inactiveThumbColor: textGrey,
                    inactiveTrackColor: dividerColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(String code, String status) {
    if (status == 'downloading') {
      return IconButton(
        icon: const Icon(Icons.close, color: textGrey, size: 24),
        onPressed: () => _cancelDownload(code),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 24,
      );
    } else if (status == 'downloaded') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF22C55E), // Green Check
            size: 22,
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => _deleteModel(code),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.delete_outline,
                color: Color(0xFFEF4444), // Red Trash
                size: 22,
              ),
            ),
          ),
        ],
      );
    } else if (status == 'deleting') {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)),
      );
    } else {
      // not_downloaded
      return InkWell(
        onTap: () => _downloadModel(code),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryBlue, width: 1.5),
          ),
          child: const Icon(
            Icons.download_rounded,
            color: primaryBlue,
            size: 20,
          ),
        ),
      );
    }
  }
}
