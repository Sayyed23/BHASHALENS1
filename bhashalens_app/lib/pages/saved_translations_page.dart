import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bhashalens_app/models/saved_translation.dart'; // Import the model
import 'package:bhashalens_app/theme/app_theme.dart'; // Import custom colors

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
  const SavedTranslationsPage({super.key});

  @override
  State<SavedTranslationsPage> createState() => _SavedTranslationsPageState();
}

class _SavedTranslationsPageState extends State<SavedTranslationsPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavedTranslationsProvider>(context);
    final grouped = _groupByDate(provider.translations);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: Text(
          'Saved Translations',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onBackground,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onBackground),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                hintText: 'Search translations',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...entry.value
                        .where(_matchesSearch)
                        .map((t) => _buildTranslationCard(context, t, theme)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  bool _matchesSearch(SavedTranslation t) {
    if (searchQuery.isEmpty) return true;
    return t.originalText.toLowerCase().contains(searchQuery.toLowerCase()) ||
        t.translatedText.toLowerCase().contains(searchQuery.toLowerCase());
  }

  Map<String, List<SavedTranslation>> _groupByDate(
    List<SavedTranslation> list,
  ) {
    final now = DateTime.now();
    final Map<String, List<SavedTranslation>> map = {};
    for (var t in list) {
      String label;
      if (_isSameDay(t.dateTime, now)) {
        label = 'Today';
      } else if (_isSameDay(
        t.dateTime,
        now.subtract(const Duration(days: 1)),
      )) {
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

  Widget _buildTranslationCard(
    BuildContext context,
    SavedTranslation t,
    ThemeData theme,
  ) {
    final provider = Provider.of<SavedTranslationsProvider>(
      context,
      listen: false,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
                      Text(
                        t.originalText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        t.translatedText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.translate,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${t.fromLanguage} to ${t.toLanguage}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('h:mm a').format(t.dateTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: theme.colorScheme.onSurface,
                  ),
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
                    color: t.isStarred
                        ? CustomColors.of(context).warning
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  onPressed: () {
                    provider.toggleStar(t);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.content_copy,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  onPressed: () {
                    // TODO: Copy translation
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  onPressed: () {
                    // TODO: Share translation
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
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

  Widget _buildBottomNavBar(ThemeData theme) {
    return BottomNavigationBar(
      backgroundColor: theme.colorScheme.background,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.7),
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_camera),
          label: 'Camera',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark, color: theme.colorScheme.primary),
          label: 'Saved',
        ),
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
