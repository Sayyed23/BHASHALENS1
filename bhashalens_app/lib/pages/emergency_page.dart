import 'package:flutter/material.dart';
import 'package:bhashalens_app/theme/app_colors.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Assistance'),
        backgroundColor: AppColors.sosRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.campaign, size: 80, color: AppColors.sosRed),
            const SizedBox(height: 16),
            Text(
              'Emergency Mode',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.sosRed,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these templates for quick communication in urgent situations.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // SOS Trigger Button
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Triggering Emergency SOS Alert...'),
                      backgroundColor: AppColors.sosRed,
                    ),
                  );
                },
                icon: const Icon(Icons.warning, size: 32),
                label: const Text(
                  'DRAG TO SEND SOS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            _buildSectionHeader(context, 'COMMUNICATION TEMPLATES'),
            const SizedBox(height: 16),
            _buildEmergencyTemplate(context, 'Medical', 'I need a doctor / Ambulance.'),
            _buildEmergencyTemplate(context, 'Safety', 'I need help / Call the Police.'),
            _buildEmergencyTemplate(context, 'Location', 'Where is the nearest Hospital?'),
            _buildEmergencyTemplate(context, 'Fire', 'There is a Fire / Call Fire Station.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmergencyTemplate(BuildContext context, String category, String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(text),
        trailing: const Icon(Icons.volume_up),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speaking: $text')),
          );
        },
      ),
    );
  }
}
