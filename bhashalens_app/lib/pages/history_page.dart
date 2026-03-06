import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../models/history_item.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryService>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Translation History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Consumer<HistoryService>(
            builder: (context, historyService, _) => IconButton(
              icon: Icon(
                Icons.delete_sweep,
                color: historyService.history.isEmpty
                    ? Colors.white38
                    : Colors.white,
              ),
              onPressed: historyService.history.isEmpty
                  ? null
                  : () => _showClearConfirmDialog(context),
            ),
          ),
        ],
      ),
      body: Consumer<HistoryService>(
        builder: (context, historyService, child) {
          if (historyService.isLoading && historyService.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (historyService.error != null && historyService.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    historyService.error!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => historyService.fetchHistory(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (historyService.history.isEmpty) {
            return const Center(
              child: Text(
                'No translation history yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => historyService.fetchHistory(),
            child: ListView.builder(
              itemCount: historyService.history.length,
              itemBuilder: (context, index) {
                final item = historyService.history[index];
                return _buildHistoryCard(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryItem item) {
    final historyService = Provider.of<HistoryService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.sourceLang.toUpperCase()} → ${item.targetLang.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  DateFormat('MMM d, HH:mm').format(item.timestamp),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.sourceText,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Divider(color: Colors.white10, height: 24),
            Text(
              item.targetText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.white54, size: 20),
                  onPressed: () => historyService.deleteHistoryItem(item.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title:
            const Text('Clear History', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete all history? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<HistoryService>(context, listen: false)
                  .clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
