import 'package:flutter/material.dart';

class BackendIndicator extends StatelessWidget {
  final String backend;
  
  const BackendIndicator({
    super.key,
    required this.backend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color color;
    IconData icon;
    String label;

    switch (backend.toLowerCase()) {
      case 'bedrock':
      case 'awsbedrock':
        color = Colors.blue;
        icon = Icons.auto_awesome;
        label = 'Gemini (Strict Mode)';
        break;
      case 'gemini':
        color = Colors.blue;
        icon = Icons.auto_awesome;
        label = 'Gemini 1.5 Flash';
        break;
      case 'offline':
      case 'mlkit':
        color = Colors.green;
        icon = Icons.offline_bolt;
        label = 'ML Kit (Offline)';
        break;
      default:
        color = colorScheme.outline;
        icon = Icons.info_outline;
        label = 'Processing...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
