import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transcription_history.dart';
import '../providers/history_provider.dart';
import '../widgets/recording_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/app_bar_title_with_logo.dart';
import '../services/export/export_service.dart';
import '../utils/constants.dart';
import '../services/audio_service.dart';
import '../services/file_service.dart';
import 'package:just_audio/just_audio.dart';
import 'session_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentlyPlayingId;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    // Ensure history is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().initialize();
    });

    // Listen for playback completion to reset playing state
    _audioService.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _currentlyPlayingId = null;
          });
        }
      }
    });
  }

  void _startNewRecording() async {
    setState(() {
      _isFabExpanded = false;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionScreen(
          autoStartRecording: true,
        ),
      ),
    );

    // Refresh history when returning from session
    if (mounted) {
      debugPrint('=== Refreshing History on HomeScreen (new recording) ===');
      final provider = context.read<HistoryProvider>();
      debugPrint('History count before refresh: ${provider.count}');
      await provider.refresh();
      debugPrint('History count after refresh: ${provider.count}');
    }
  }

  void _pickAudioFile() async {
    setState(() {
      _isFabExpanded = false;
    });

    final fileService = FileService();
    final selectedFile = await fileService.pickAudioFile(context);

    if (selectedFile != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionScreen(
            initialFile: selectedFile,
          ),
        ),
      );

      // Refresh history when returning from session
      if (mounted) {
        debugPrint('=== Refreshing History on HomeScreen (file picker) ===');
        final provider = context.read<HistoryProvider>();
        debugPrint('History count before refresh: ${provider.count}');
        await provider.refresh();
        debugPrint('History count after refresh: ${provider.count}');
      }
    }
  }

  void _openSession(TranscriptionHistory history) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionScreen(
          historyId: history.id,
          initialFile: null, // Will be loaded from history
        ),
      ),
    );
    
    // Refresh history when returning from session
    if (mounted) {
      debugPrint('=== Refreshing History on HomeScreen (existing session) ===');
      final provider = context.read<HistoryProvider>();
      debugPrint('History count before refresh: ${provider.count}');
      await provider.refresh();
      debugPrint('History count after refresh: ${provider.count}');
    }
  }

  final IAudioService _audioService = AudioService();

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(TranscriptionHistory history) async {
    debugPrint('=== Audio Playback Debug ===');
    debugPrint('History ID: ${history.id}');
    debugPrint('Audio Path: ${history.audioPath}');
    debugPrint('Currently Playing ID: $_currentlyPlayingId');
    
    if (history.audioPath == null) {
      debugPrint('ERROR: Audio path is null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kein Audiopfad verfügbar')),
        );
      }
      return;
    }

    // Check if file exists
    final file = File(history.audioPath!);
    final exists = await file.exists();
    debugPrint('File exists: $exists');
    
    if (!exists) {
      debugPrint('ERROR: Audio file does not exist at path: ${history.audioPath}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audiodatei nicht gefunden')),
        );
      }
      return;
    }

    try {
      if (_currentlyPlayingId == history.id) {
        debugPrint('Pausing current audio');
        setState(() {
          _currentlyPlayingId = null;
        });
        await _audioService.pause();
      } else {
        // Stop previous if any
        if (_currentlyPlayingId != null) {
          debugPrint('Stopping previous audio');
          await _audioService.pause();
        }

        setState(() {
          _currentlyPlayingId = history.id;
        });

        debugPrint('Loading audio from: ${history.audioPath}');
        await _audioService.loadAudio(history.audioPath!);

        debugPrint('Playing audio');
        await _audioService.play();

        debugPrint('Audio playback started successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR playing audio: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Abspielen: $e')),
        );
        setState(() {
          _currentlyPlayingId = null;
        });
      }
    }
  }

  Future<void> _renameRecording(TranscriptionHistory history) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initialName: history.audioFileName),
    );

    if (newName != null && newName.isNotEmpty && newName != history.audioFileName && mounted) {
      try {
        await context.read<HistoryProvider>().renameRecording(history.id, newName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aufnahme umbenannt')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Umbenennen: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteRecording(TranscriptionHistory history) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aufnahme löschen'),
        content: Text('Möchten Sie "${history.audioFileName}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<HistoryProvider>().deleteHistory(history.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aufnahme gelöscht')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportRecording(TranscriptionHistory history) async {
    final exportService = ExportService();
    await exportService.share(history);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitleWithLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () {
              Navigator.pushNamed(context, '/prompts');
            },
            tooltip: 'Prompts verwalten',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (historyProvider.history.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.mic,
              title: 'Keine Aufnahmen',
              subtitle: 'Starten Sie eine neue Aufnahme mit dem + Button',
            );
          }

          // Sort by date descending
          final sortedHistory = List<TranscriptionHistory>.from(historyProvider.history)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            cacheExtent: 500,
            itemCount: sortedHistory.length,
            itemBuilder: (context, index) {
              final history = sortedHistory[index];
              return RecordingCard(
                key: ValueKey(history.id),
                history: history,
                isPlaying: _currentlyPlayingId == history.id,
                onPlay: () => _togglePlay(history),
                onTranscribe: () => _openSession(history),
                onTap: () => _openSession(history),
                onRename: () => _renameRecording(history),
                onExport: () => _exportRecording(history),
                onDelete: () => _deleteRecording(history),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabExpanded) ...[
            FloatingActionButton.extended(
              heroTag: 'fab_pick_file',
              onPressed: _pickAudioFile,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark ? 0.95 : 0.85,
              ),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.folder_open),
              label: const Text('Datei wählen'),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'fab_record',
              onPressed: _startNewRecording,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark ? 0.95 : 0.85,
              ),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.mic),
              label: const Text('Aufnahme'),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? 0.95 : 0.85,
            ),
            foregroundColor: Colors.white,
            child: Icon(_isFabExpanded ? Icons.close : Icons.add),
          ),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  final String initialName;

  const _RenameDialog({required this.initialName});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  String _getBaseNameWithoutExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  @override
  void initState() {
    super.initState();
    final baseName = _getBaseNameWithoutExtension(widget.initialName);
    _controller = TextEditingController(text: baseName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Umbenennen'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'Neuer Name',
        ),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Umbenennen'),
        ),
      ],
    );
  }
}
