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

  @override
  void initState() {
    super.initState();
    _checkDownloadedModels();
  }

  Future<void> _checkDownloadedModels() async {
    final downloaded = await _mlKitService.getDownloadedModels();
    if (mounted) {
      setState(() {
        // First reset all to not_downloaded or keep existing if downloading
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

    // Individual checks for accuracy (re-verify)
    for (var lang in _supportedLanguages) {
      final code = lang['code']!;
      // Skip if already confirmed downloaded by list to avoid redundant calls,
      // but isModelDownloaded is cheap.
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
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteModel(String code) async {
    setState(() {
      _modelStatus[code] = 'deleting'; // optional status
    });

    final success = await _mlKitService.deleteModel(code);

    if (mounted) {
      setState(() {
        _modelStatus[code] = success ? 'not_downloaded' : 'downloaded';
      });
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Model deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Models'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        itemCount: _supportedLanguages.length,
        itemBuilder: (context, index) {
          final lang = _supportedLanguages[index];
          final code = lang['code']!;
          final name = lang['name']!;
          final status = _modelStatus[code] ?? 'loading';

          return ListTile(
            title: Text(name),
            subtitle: Text(code),
            trailing: _buildTrailingWidget(code, status),
          );
        },
      ),
    );
  }

  Widget _buildTrailingWidget(String code, String status) {
    if (status == 'loading' || status == 'deleting') {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (status == 'downloading') {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (status == 'downloaded') {
      return IconButton(
        icon: const Icon(Icons.delete, color: Colors.grey),
        onPressed: () => _deleteModel(code),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.download, color: Colors.blue),
        onPressed: () => _downloadModel(code),
      );
    }
  }
}
