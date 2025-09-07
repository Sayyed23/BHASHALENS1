
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SavedTranslation {
  final String originalText;
  final String translatedText;
  final String fromLanguage;
  final String toLanguage;
  final DateTime dateTime;
  bool isStarred;

  SavedTranslation({
    required this.originalText,
    required this.translatedText,
    required this.fromLanguage,
    required this.toLanguage,
    required this.dateTime,
    this.isStarred = false,
  });
}

class SavedTranslationsProvider extends ChangeNotifier {
  final List<SavedTranslation> _translations = [];
  List<SavedTranslation> get translations => _translations;

  void add(SavedTranslation t) {
    _translations.insert(0, t);
    notifyListeners();
  }

  void remove(SavedTranslation t) {
    _translations.remove(t);
    notifyListeners();
  }

  void toggleStar(SavedTranslation t) {
    t.isStarred = !t.isStarred;
    notifyListeners();
  }
}

class SavedTranslationsPage extends StatefulWidget {
  const SavedTranslationsPage({Key? key}) : super(key: key);

  @override
  State<SavedTranslationsPage> createState() => _SavedTranslationsPageState();
}

class _SavedTranslationsPageState extends State<SavedTranslationsPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavedTranslationsProvider>(context);
    final grouped = _groupByDate(provider.translations);
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        elevation: 0,
        title: const Text('Saved Translations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2D3748),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Search translations',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (q) => setState(() => searchQuery = q),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                      ),
                    ),
                    ...entry.value.where(_matchesSearch).map((t) => _buildTranslationCard(context, t)).toList(),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  bool _matchesSearch(SavedTranslation t) {
    if (searchQuery.isEmpty) return true;
    return t.originalText.toLowerCase().contains(searchQuery.toLowerCase()) ||
        t.translatedText.toLowerCase().contains(searchQuery.toLowerCase());
  }

  Map<String, List<SavedTranslation>> _groupByDate(List<SavedTranslation> list) {
    final now = DateTime.now();
    final Map<String, List<SavedTranslation>> map = {};
    for (var t in list) {
      String label;
      if (_isSameDay(t.dateTime, now)) {
        label = 'Today';
      } else if (_isSameDay(t.dateTime, now.subtract(const Duration(days: 1)))) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMM d, yyyy').format(t.dateTime);
      }
      map.putIfAbsent(label, () => []).add(t);
    }
    return map;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildTranslationCard(BuildContext context, SavedTranslation t) {
    final provider = Provider.of<SavedTranslationsProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.originalText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(t.translatedText, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                      Row(
                        children: [
                          const Icon(Icons.translate, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text('${t.fromLanguage} to ${t.toLanguage}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(DateFormat('h:mm a').format(t.dateTime), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.white),
                  onPressed: () {
                    // TODO: Play audio for t.translatedText
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    t.isStarred ? Icons.star : Icons.star_border,
                    color: t.isStarred ? Colors.yellow : Colors.grey,
                  ),
                  onPressed: () {
                    provider.toggleStar(t);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy, color: Colors.grey),
                  onPressed: () {
                    // TODO: Copy translation
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.grey),
                  onPressed: () {
                    // TODO: Share translation
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () {
                    provider.remove(t);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1A202C),
      selectedItemColor: const Color(0xFF1193d4),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.photo_camera), label: 'Camera'),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark, color: Color(0xFF1193d4)), label: 'Saved'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      currentIndex: 3,
      onTap: (i) {
        switch (i) {
          case 0:
            Navigator.of(context).pushReplacementNamed('/home');
            break;
          case 1:
            Navigator.of(context).pushReplacementNamed('/camera_translate');
            break;
          case 2:
            Navigator.of(context).pushReplacementNamed('/voice_translate');
            break;
          case 3:
            // Already on Saved
            break;
          case 4:
            Navigator.of(context).pushReplacementNamed('/settings');
            break;
        }
      },
    );
  }
}
