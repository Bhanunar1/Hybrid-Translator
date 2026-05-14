import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/translation_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _entries = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all' | 'cloud' | 'offline' | 'voice'

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final service = context.read<TranslationService>();
    final entries = await service.fetchHistory();
    if (mounted) setState(() { _entries = entries; _isLoading = false; });
  }

  List<HistoryEntry> get _filtered {
    switch (_filter) {
      case 'cloud':  return _entries.where((e) => e.engine == 'cloud').toList();
      case 'offline': return _entries.where((e) => e.engine == 'offline').toList();
      case 'voice':  return _entries.where((e) => e.wasVoiceInput).toList();
      default: return _entries;
    }
  }

  Future<void> _deleteItem(HistoryEntry entry, int localIndex) async {
    final service = context.read<TranslationService>();
    if (entry.id != null) await service.deleteHistoryItem(entry.id!);
    setState(() => _entries.removeAt(localIndex));
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All History?'),
        content: const Text('This will permanently delete all translation records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<TranslationService>().clearHistory();
      setState(() => _entries.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Translation History',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: theme.colorScheme.primary)),
            Text('${_entries.length} records',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(128))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAll,
              color: Colors.red,
              tooltip: 'Clear All',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('All', 'all', Icons.list_rounded, theme),
                const SizedBox(width: 8),
                _filterChip('Cloud', 'cloud', Icons.cloud_rounded, theme),
                const SizedBox(width: 8),
                _filterChip('Offline', 'offline', Icons.offline_bolt_rounded, theme),
                const SizedBox(width: 8),
                _filterChip('Voice', 'voice', Icons.mic_rounded, theme),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState(theme)
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final entry = filtered[i];
                            final globalIndex = _entries.indexOf(entry);
                            return FadeInDown(
                              duration: Duration(milliseconds: 200 + i * 30),
                              child: _HistoryCard(
                                entry: entry,
                                theme: theme,
                                isDark: isDark,
                                onDelete: () => _deleteItem(entry, globalIndex),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, IconData icon, ThemeData theme) {
    final selected = _filter == value;
    return FilterChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: selected ? Colors.white : theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      backgroundColor: theme.colorScheme.primary.withAlpha(15),
      side: BorderSide(color: theme.colorScheme.primary.withAlpha(60)),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 72, color: theme.colorScheme.primary.withAlpha(80)),
          const SizedBox(height: 16),
          Text('No history yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Translate something to see it here',
            style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(128))),
        ],
      ),
    );
  }
}

// ── History Card ───────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.entry,
    required this.theme,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final engineColor = entry.engine == 'cloud'
        ? Colors.blue
        : entry.engine == 'offline'
            ? Colors.orange
            : Colors.green;

    return Dismissible(
      key: Key('hist_${entry.id ?? entry.createdAt.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surface.withAlpha(200)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _chip('${entry.sourceLang} → ${entry.targetLang}', theme.colorScheme.primary),
                const SizedBox(width: 8),
                _chip(entry.engine.toUpperCase(), engineColor),
                if (entry.wasVoiceInput) ...[
                  const SizedBox(width: 8),
                  _chip('🎤 VOICE', Colors.purple),
                ],
                const Spacer(),
                Text(
                  _formatTime(entry.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Source
            Text(
              entry.sourceText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 1,
              color: theme.colorScheme.outlineVariant.withAlpha(60),
            ),
            // Translation
            Text(
              entry.translatedText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            if (entry.latencyMs != null) ...[
              const SizedBox(height: 8),
              Text(
                '⚡ ${entry.latencyMs!.toStringAsFixed(0)}ms',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withAlpha(100),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}
