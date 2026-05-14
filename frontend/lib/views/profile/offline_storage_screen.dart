import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/translation_service.dart';

class OfflineStorageScreen extends StatefulWidget {
  const OfflineStorageScreen({super.key});

  @override
  State<OfflineStorageScreen> createState() => _OfflineStorageScreenState();
}

class _OfflineStorageScreenState extends State<OfflineStorageScreen> {
  List<LanguageItem> _downloadedModels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() => _isLoading = true);
    final service = Provider.of<TranslationService>(context, listen: false);
    final models = await service.getDownloadedModels();
    setState(() {
      _downloadedModels = models;
      _isLoading = false;
    });
  }

  Future<void> _deleteModel(LanguageItem lang) async {
    final service = Provider.of<TranslationService>(context, listen: false);
    
    // Optimistic UI update
    setState(() {
      _downloadedModels.remove(lang);
    });

    final success = await service.deleteModel(lang);
    if (!success) {
      // Revert if failed
      _loadModels();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete ${lang.name} model.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lang.name} model deleted (Freed ~30MB).')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Offline Storage', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloadedModels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_done_outlined, size: 64, color: colorScheme.primary.withAlpha(150)),
                      const SizedBox(height: 16),
                      Text(
                        'No offline models downloaded.',
                        style: TextStyle(fontSize: 18, color: colorScheme.onSurface.withAlpha(150)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Models will download automatically when translating offline.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurface.withAlpha(100)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _downloadedModels.length,
                  itemBuilder: (context, index) {
                    final lang = _downloadedModels[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(lang.flag, style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(lang.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('~30 MB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Model?'),
                                content: Text('Are you sure you want to delete the ${lang.name} offline model? You will need internet to download it again.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _deleteModel(lang);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
