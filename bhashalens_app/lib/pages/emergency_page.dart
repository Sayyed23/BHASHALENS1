import 'package:flutter/material.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 100, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'SOS button and emergency communication templates will be here.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            // TODO: Add SOS button and emergency communication templates
          ],
        ),
      ),
    );
  }
}
