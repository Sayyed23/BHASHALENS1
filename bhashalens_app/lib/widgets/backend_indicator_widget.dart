import 'package:flutter/material.dart';
import 'package:bhashalens_app/services/smart_hybrid_router.dart';

/// Shows a small chip indicating which backend processed the result:
/// "Powered by AWS Bedrock", "Powered by Gemini", or "Offline".
class BackendIndicatorWidget extends StatelessWidget {
  /// Prefer [backend] when available (from hybrid result enums).
  final ProcessingBackend? backend;

  /// When result is a Map, pass backend string here (e.g. 'aws-bedrock', 'gemini', 'ml_kit').
  final String? backendLabel;

  const BackendIndicatorWidget({
    super.key,
    this.backend,
    this.backendLabel,
  });

  static String _labelFromEnum(ProcessingBackend b) {
    switch (b) {
      case ProcessingBackend.awsBedrock:
        return 'Powered by AWS Bedrock';
      case ProcessingBackend.gemini:
        return 'Powered by Gemini';
      case ProcessingBackend.mlKit:
        return 'Offline';
      case ProcessingBackend.error:
        return 'Service Error';
    }
  }

  static String? _labelFromString(String? s) {
    if (s == null || s.isEmpty) return null;
    final lower = s.toLowerCase();
    if (lower == 'aws' ||
        lower == 'aws_bedrock' ||
        lower == 'aws-bedrock' ||
        lower == 'bedrock') {
      return 'Powered by AWS Bedrock';
    }
    if (lower == 'gemini') return 'Powered by Gemini';
    if (lower == 'ml' || lower == 'ml_kit' || lower == 'offline') {
      return 'Offline';
    }
    if (lower == 'error') {
      return 'Service Error';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String? label;
    if (backend != null) {
      label = _labelFromEnum(backend!);
    } else if (backendLabel != null) {
      label = _labelFromString(backendLabel);
    }
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 14,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
