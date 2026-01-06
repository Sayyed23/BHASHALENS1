import 'package:flutter/material.dart';

class AssistantModePage extends StatelessWidget {
  const AssistantModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Life Assistant'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Assistant Mode Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Speak confidently in offices, hospitals, and daily life.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
