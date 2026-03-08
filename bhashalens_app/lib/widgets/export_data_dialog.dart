import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bhashalens_app/services/export_service.dart';
import 'package:bhashalens_app/services/aws_api_gateway_client.dart';

/// Dialog to export history/saved data via AWS. Opens presigned download URL
/// when cloud sync is enabled; shows message when disabled.
class ExportDataDialog extends StatefulWidget {
  const ExportDataDialog({super.key});

  @override
  State<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<ExportDataDialog> {
  String _exportType = 'history';
  String _format = 'json';
  bool _isExporting = false;

  Future<void> _doExport() async {
    final exportService = Provider.of<ExportService>(context, listen: false);
    final apiClient = Provider.of<AwsApiGatewayClient>(context, listen: false);

    if (!apiClient.isEnabled) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Export is available when cloud sync is enabled. Check Settings.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() => _isExporting = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exporting...')),
      );
    }

    final result = await exportService.exportData(
      exportType: _exportType,
      format: _format,
    );

    if (!mounted) return;
    setState(() => _isExporting = false);

    if (result == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exportService.error ?? 'Export failed. Check connection and cloud sync.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final downloadUrl = result['downloadUrl'] as String?;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export failed. No download link received.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export ready. Opening download...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open download link.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export failed. Check connection and cloud sync.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardDark = Color(0xFF1C222B);
    const textGrey = Color(0xFF94A3B8);
    const primaryBlue = Color(0xFF136DEC);

    return AlertDialog(
      backgroundColor: cardDark,
      title: const Text(
        'Export data',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What to export',
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _exportType,
              dropdownColor: cardDark,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'history', child: Text('History')),
                DropdownMenuItem(value: 'saved', child: Text('Saved')),
                DropdownMenuItem(value: 'both', child: Text('History & Saved')),
              ],
              onChanged: _isExporting
                  ? null
                  : (v) {
                      if (v != null) setState(() => _exportType = v);
                    },
            ),
            const SizedBox(height: 16),
            const Text(
              'Format',
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _format,
              dropdownColor: cardDark,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'json', child: Text('JSON')),
                DropdownMenuItem(value: 'csv', child: Text('CSV')),
              ],
              onChanged: _isExporting
                  ? null
                  : (v) {
                      if (v != null) setState(() => _format = v);
                    },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: textGrey)),
        ),
        FilledButton(
          onPressed: _isExporting ? null : _doExport,
          style: FilledButton.styleFrom(backgroundColor: primaryBlue),
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Export'),
        ),
      ],
    );
  }
}
