import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transcription_history.dart';
import '../providers/history_provider.dart';
import '../utils/constants.dart';
import '../widgets/history_item_card.dart';
import '../services/snackbar_service.dart';
import '../widgets/empty_state_widget.dart';

/// Screen for displaying transcription history with search and filters
/// Follows Single Responsibility Principle: Manages history UI
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<TranscriptionHistory> _filteredHistory = [];
  String _selectedLanguageFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterHistory);
    // Initialize filter with all history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterHistory() {
    final historyProvider = context.read<HistoryProvider>();
    final query = _searchController.text;

    setState(() {
      _filteredHistory = historyProvider.history.where((history) {
        final matchesSearch = query.isEmpty ||
            history.audioFileName.toLowerCase().contains(query.toLowerCase()) ||
            history.transcription.text.toLowerCase().contains(query.toLowerCase());

        final matchesLanguage = _selectedLanguageFilter == 'all' ||
            history.transcription.language == _selectedLanguageFilter;

        return matchesSearch && matchesLanguage;
      }).toList();
    });
  }

  Future<void> _deleteHistory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen'),
        content: const Text('Möchten Sie diesen Eintrag wirklich aus der Historie löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final historyProvider = context.read<HistoryProvider>();
        await historyProvider.deleteHistory(id);
        _filterHistory();
        if (mounted) {
          _showSuccessSnackBar('Eintrag gelöscht');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Fehler beim Löschen: $e');
        }
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gesamte Historie löschen'),
        content: const Text(
          'Möchten Sie wirklich die gesamte Historie löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Alles löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final historyProvider = context.read<HistoryProvider>();
        await historyProvider.clearAllHistory();
        _filterHistory();
        if (mounted) {
          _showSuccessSnackBar('Historie gelöscht');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Fehler beim Löschen: $e');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    SnackBarService().showError(context, message);
  }

  void _showSuccessSnackBar(String message) {
    SnackBarService().showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Historie'),
            actions: [
              if (historyProvider.history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: _clearAllHistory,
                  tooltip: 'Alles löschen',
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Suchen...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Sprache filtern',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.filter_list),
                      ),
                      value: _selectedLanguageFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Alle Sprachen')),
                        DropdownMenuItem(value: 'auto', child: Text('Auto-Detect')),
                        DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLanguageFilter = value;
                          });
                          _filterHistory();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: historyProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                : _filteredHistory.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.history,
                        title: _searchController.text.isNotEmpty || _selectedLanguageFilter != 'all'
                            ? 'Keine Ergebnisse gefunden'
                            : 'Noch keine Transkriptionen',
                        subtitle: _searchController.text.isNotEmpty || _selectedLanguageFilter != 'all'
                            ? 'Versuchen Sie eine andere Suche oder Filter'
                            : 'Ihre Transkriptionen werden hier gespeichert',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final history = _filteredHistory[index];
                          return HistoryItemCard(
                            history: history,
                            onDelete: () => _deleteHistory(history.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
