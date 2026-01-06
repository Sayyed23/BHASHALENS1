import 'package:flutter/material.dart';

class ExplainModePage extends StatelessWidget {
  const ExplainModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explain & Simplify'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Explain Mode Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Understand notices, bills, and messages in simple words.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
