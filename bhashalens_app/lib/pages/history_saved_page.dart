import 'package:bhashalens_app/models/history_item.dart';
import 'package:bhashalens_app/services/history_service.dart';
import 'package:bhashalens_app/services/saved_translations_service.dart';
import 'package:bhashalens_app/services/voice_translation_service.dart';

import 'package:flutter/material.dart';
import 'package:bhashalens_app/widgets/common_bottom_nav_bar.dart';
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

    // Fetch data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryService>(context, listen: false).fetchHistory();
      Provider.of<SavedTranslationsService>(context, listen: false)
          .fetchSavedTranslations();
    });
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

  Future<void> _toggleSave(HistoryItem item) async {
    final savedService =
        Provider.of<SavedTranslationsService>(context, listen: false);
    final isSaved = savedService.savedItems.any((i) => i.id == item.id);

    try {
      if (isSaved) {
        await savedService.deleteSavedItem(item.id);
      } else {
        await savedService.saveItem(item);
      }
    } catch (e) {
      debugPrint('Failed to toggle saved status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update saved status')),
        );
      }
    }
  }

  List<HistoryItem> _filterList(List<HistoryItem> source) {
    return source.where((item) {
      final matchesSearch = item.sourceText
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item.targetText.toLowerCase().contains(_searchQuery.toLowerCase());

      // Match category by type for now, or assume General
      final matchesFilter = _selectedFilter == 'All' ||
          (item.type?.toLowerCase() == _selectedFilter.toLowerCase());

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F172A);
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
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 3),
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
              indicator: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
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
            child: _tabController.index == 0
                ? Consumer<HistoryService>(
                    builder: (context, service, _) {
                      if (service.isLoading && service.history.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final filtered = _filterList(service.history);
                      if (filtered.isEmpty) {
                        return const Center(
                            child: Text("No history items",
                                style: TextStyle(color: Colors.white70)));
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          await service.fetchHistory();
                          await service.syncLocalHistoryWithCloud();
                        },
                        child: Stack(
                          children: [
                            ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildItemCard(filtered[index], cardColor),
                            ),
                            if (service.isSyncing)
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF136DEC),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Syncing with cloud...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  )
                : Consumer<SavedTranslationsService>(
                    builder: (context, service, _) {
                      if (service.isLoading && service.savedItems.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final filtered = _filterList(service.savedItems);
                      if (filtered.isEmpty) {
                        return const Center(
                            child: Text("No saved items",
                                style: TextStyle(color: Colors.white70)));
                      }
                      return RefreshIndicator(
                        onRefresh: () => service.fetchSavedTranslations(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildItemCard(filtered[index], cardColor),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(HistoryItem item, Color cardColor) {
    bool isSaved = Provider.of<SavedTranslationsService>(context)
        .savedItems
        .any((i) => i.id == item.id);

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
                      "${item.sourceLang.toUpperCase()} \u2192 ${item.targetLang.toUpperCase()}",
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd().format(item.timestamp),
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
                  _showOptionsMs(item);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getCategoryIcon(item.type ?? 'General'),
                color: const Color(0xFF22C55E),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                (item.type ?? 'General').toUpperCase(),
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
              item.sourceText,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF136DEC), width: 3),
              ),
            ),
            child: Text(
              item.targetText,
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
                    final voiceService = Provider.of<VoiceTranslationService>(
                        context,
                        listen: false);
                    voiceService.speakText(item.targetText, item.targetLang);
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
              GestureDetector(
                onTap: () => _toggleSave(item),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSaved
                        ? const Color(0xFF136DEC)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptionsMs(HistoryItem item) {
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
              title: const Text("Copy Translation",
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: item.targetText));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Copied!')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                if (_tabController.index == 0) {
                  Provider.of<HistoryService>(context, listen: false)
                      .deleteHistoryItem(item.id);
                } else {
                  Provider.of<SavedTranslationsService>(context, listen: false)
                      .deleteSavedItem(item.id);
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
