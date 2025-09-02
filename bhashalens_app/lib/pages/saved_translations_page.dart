import 'package:flutter/material.dart';

class SavedTranslationsPage extends StatelessWidget {
  const SavedTranslationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Translations')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'List of saved translations and history will be displayed here.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            // TODO: Add list view for translations, search/filter, re-translate, edit, delete options
          ],
        ),
      ),
    );
  }
}
