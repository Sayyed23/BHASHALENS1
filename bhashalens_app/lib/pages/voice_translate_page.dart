import 'package:flutter/material.dart';

class VoiceTranslatePage extends StatelessWidget {
  const VoiceTranslatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Translate')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Voice recording and Whisper transcription will be implemented here.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            // TODO: Add audio recording, transcription, translation, playback, save/share options
          ],
        ),
      ),
    );
  }
}
