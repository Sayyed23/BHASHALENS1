import 'package:bhashalens_app/models/saved_translation.dart';
import 'package:bhashalens_app/services/firestore_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistorySavedPage extends StatefulWidget {
  final int initialIndex;

  const HistorySavedPage({super.key, this.initialIndex = 0});

  @override
  State<HistorySavedPage> createState() => _HistorySavedPageState();
}

class _HistorySavedPageState extends State<HistorySavedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FirestoreService _firestoreService;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.all_inclusive},
    {'label': 'Medical', 'icon': Icons.local_hospital},
    {'label': 'Travel', 'icon': Icons.flight},
    {'label': 'Business', 'icon': Icons.business_center},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _toggleStar(SavedTranslation item) async {
    if (item.id == null) return;
    try {
      await _firestoreService.toggleSavedStatus(item.id!, !item.isStarred);
      // Stream updates automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  List<SavedTranslation> _filterList(List<SavedTranslation> source) {
    return source.where((item) {
      final matchesSearch =
          item.originalText.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item.translatedText.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      // Filter logic: Check category (assuming simple string match or default)
      final matchesFilter =
          _selectedFilter == 'All' || item.category == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F172A); // Matches Home Page
    const cardColor = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "History & Saved",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF1E293B), // Same as bg to hide standard
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF136DEC), width: 2),
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "History"),
                Tab(text: "Saved"),
              ],
            ),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search history or saved items",
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                    onPressed: () {
                      // TODO: Implement advanced filter UI
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Advanced filters coming soon!"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter['label'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedFilter = filter['label']),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF136DEC)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF136DEC)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          filter['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filter['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // List Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _tabController.index == 0
                  ? _firestoreService.getHistoryStream()
                  : _firestoreService.getSavedStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No items found",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                List<SavedTranslation> items = snapshot.data!.docs.map((doc) {
                  return SavedTranslation.fromFirestore(doc);
                }).toList();

                List<SavedTranslation> filteredItems = _filterList(items);

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Text(
                      "No matching items",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildItemCard(item, cardColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(SavedTranslation item, Color cardColor) {
    // Grouping headers logic could go here if needed as per mock "TODAY"
    // For simplicity, just the card for now.
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3661), // Dark Blue tag
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${item.fromLanguage.length >= 2 ? item.fromLanguage.substring(0, 2).toUpperCase() : item.fromLanguage.toUpperCase()} \u2192 ${item.toLanguage.length >= 2 ? item.toLanguage.substring(0, 2).toUpperCase() : item.toLanguage.toUpperCase()}",
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd().format(
                      item.dateTime,
                    ), // or 2 mins ago logic
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Options: Delete, Share
                  _showOptionsMs(item);
                },
              ),
            ],
          ),
          // Category Tag (Mock shows icons like Hospital, Restaurant)
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getCategoryIcon(item.category),
                color: const Color(0xFF22C55E),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                item.category.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.originalText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Left Bordered Result
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF136DEC), width: 3),
              ),
            ),
            child: Text(
              item.translatedText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Speak
                    final voiceService = Provider.of<VoiceTranslationService>(
                      context,
                      listen: false,
                    );
                    voiceService.speakText(
                      item.translatedText,
                      item.toLanguage,
                    );
                  },
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: const Text("Speak"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF136DEC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Explain
                    Navigator.pushNamed(
                      context,
                      '/explain_mode',
                      arguments: item.originalText,
                    ); // Pass text
                  },
                  icon: const Icon(Icons.psychology, size: 18),
                  label: const Text("Explain"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.8),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptionsMs(SavedTranslation item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text(
                "Copy Translation",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: item.translatedText));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Translation copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                item.isStarred ? Icons.bookmark_remove : Icons.bookmark_add,
                color: Colors.white,
              ),
              title: Text(
                item.isStarred ? "Unsave" : "Save",
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _toggleStar(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                if (item.id != null) {
                  try {
                    await _firestoreService.deleteTranslation(item.id!);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return Icons.local_hospital;
      case 'travel':
        return Icons.flight;
      case 'business':
        return Icons.business_center;
      default:
        return Icons.category;
    }
  }
}
