import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_file.dart';
import '../models/transcription_history.dart';
import '../providers/history_provider.dart' show HistoryProvider, SortOption;
import '../widgets/recording_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/app_bar_title_with_logo.dart';
import '../services/export/export_service.dart';
import '../utils/constants.dart';
import '../services/audio_service.dart';
import '../services/i_audio_service.dart';
import '../services/file_service.dart';
import '../services/i_file_service.dart';
import '../services/i_shared_audio_service.dart';
import '../services/shared_audio_service.dart';
import '../providers/settings_provider.dart';
import '../l10n/l10n.dart';
import 'package:just_audio/just_audio.dart';
import 'session_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final IFileService _fileService = FileService();
  final ISharedAudioService _sharedAudioService = SharedAudioService();

  StreamSubscription<String>? _sharedFilesSubscription;

  String? _currentlyPlayingId;
  bool _isFabExpanded = false;

  PopupMenuItem<SortOption> _buildSortMenuItem(
    BuildContext context,
    SortOption option,
    String label,
    IconData directionIcon,
    SortOption currentOption,
  ) {
    final isSelected = option == currentOption;
    final theme = Theme.of(context);
    return PopupMenuItem<SortOption>(
      value: option,
      child: Row(
        children: [
          Icon(
            directionIcon,
            size: 18,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.primary : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 18,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().initialize();
      _openInitialSharedFile();
    });

    _sharedFilesSubscription =
        _sharedAudioService.sharedFiles.listen(_openSharedFile);

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
    await _stopPlayback();
    if (!mounted) return;

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
      await context.read<HistoryProvider>().refresh();
    }
  }

  void _pickAudioFile() async {
    setState(() {
      _isFabExpanded = false;
    });

    final AudioFile? selectedFile;
    try {
      selectedFile = await _fileService.pickAudioFile(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorImportingFile(e.toString()))),
        );
      }
      return;
    }

    if (selectedFile != null && mounted) {
      await _stopPlayback();
      if (!mounted) return;

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
        await context.read<HistoryProvider>().refresh();
      }
    }
  }

  void _openSession(TranscriptionHistory history, {bool autoStartTranscription = false}) async {
    await _stopPlayback();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionScreen(
          historyId: history.id,
          initialFile: null, // Will be loaded from history
          autoStartTranscription: autoStartTranscription,
        ),
      ),
    );

    // Refresh history when returning from session
    if (mounted) {
      await context.read<HistoryProvider>().refresh();
    }
  }

  final IAudioService _audioService = AudioService();

  @override
  void dispose() {
    _sharedFilesSubscription?.cancel();
    _sharedAudioService.dispose();
    _audioService.dispose();
    super.dispose();
  }

  /// Öffnet eine Datei, mit der die App gestartet wurde.
  Future<void> _openInitialSharedFile() async {
    final path = await _sharedAudioService.consumeInitialSharedFile();
    if (path != null && path.isNotEmpty) {
      await _openSharedFile(path);
    }
  }

  /// Übernimmt eine aus einer anderen App geteilte Datei in eine neue Sitzung.
  Future<void> _openSharedFile(String path) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.importingFile)),
    );

    try {
      final audioFile = await _fileService.importFile(path);
      if (!mounted) return;

      await _stopPlayback();
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionScreen(initialFile: audioFile),
        ),
      );

      if (mounted) {
        await context.read<HistoryProvider>().refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorImportingFile(e.toString()))),
        );
      }
    }
  }

  /// Stops list playback so it never overlaps another screen's player
  Future<void> _stopPlayback() async {
    if (_currentlyPlayingId == null) return;

    await _audioService.pause();
    if (mounted) {
      setState(() {
        _currentlyPlayingId = null;
      });
    } else {
      _currentlyPlayingId = null;
    }
  }

  Future<void> _togglePlay(TranscriptionHistory history) async {
    if (history.audioPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.noAudioPath)),
        );
      }
      return;
    }

    final file = File(history.audioPath!);
    final exists = await file.exists();

    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.audioFileNotFound),
            action: SnackBarAction(
              label: context.l10n.relinkAudioFile,
              onPressed: () => _openSession(history),
            ),
          ),
        );
      }
      return;
    }

    try {
      if (_currentlyPlayingId == history.id) {
        setState(() {
          _currentlyPlayingId = null;
        });
        await _audioService.pause();
      } else {
        // Stop previous if any
        if (_currentlyPlayingId != null) {
          await _audioService.pause();
        }

        setState(() {
          _currentlyPlayingId = history.id;
        });

        await _audioService.loadAudio(history.audioPath!);
        await _audioService.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorPlaying(e.toString()))),
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
            SnackBar(content: Text(context.l10n.recordingRenamed)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorRenaming(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _deleteRecording(TranscriptionHistory history) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteRecording),
        content: Text(ctx.l10n.deleteConfirmation(history.audioFileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<HistoryProvider>().deleteHistory(history.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.recordingDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorDeleting(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _exportRecording(TranscriptionHistory history) async {
    final exportService = ExportService();
    await exportService.share(history);
  }

  Future<void> _openChat(TranscriptionHistory history) async {
    await _stopPlayback();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(historyId: history.id),
      ),
    );

    // Refresh history when returning from chat
    if (mounted) {
      await context.read<HistoryProvider>().refresh();
    }
  }

  void _openSettings() {
    setState(() {
      _isFabExpanded = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  /// Banner shown while no API key is configured
  Widget _buildApiKeyBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        0,
      ),
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Icon(Icons.key_off_outlined, color: theme.colorScheme.onTertiaryContainer),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.apiKeyMissingTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    context.l10n.apiKeyMissingDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            FilledButton(
              onPressed: _openSettings,
              child: Text(context.l10n.setUp),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFabExpanded,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _isFabExpanded = false;
        });
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitleWithLogo(),
        actions: [
          Consumer<HistoryProvider>(
            builder: (context, provider, _) => PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort),
              tooltip: context.l10n.sort,
              onSelected: (option) => provider.setSortOption(option),
              itemBuilder: (context) => [
                _buildSortMenuItem(context, SortOption.dateDesc, context.l10n.sortDateNewest, Icons.arrow_downward, provider.sortOption),
                _buildSortMenuItem(context, SortOption.dateAsc, context.l10n.sortDateOldest, Icons.arrow_upward, provider.sortOption),
                const PopupMenuDivider(),
                _buildSortMenuItem(context, SortOption.nameAsc, context.l10n.sortNameAZ, Icons.arrow_upward, provider.sortOption),
                _buildSortMenuItem(context, SortOption.nameDesc, context.l10n.sortNameZA, Icons.arrow_downward, provider.sortOption),
                const PopupMenuDivider(),
                _buildSortMenuItem(context, SortOption.durationDesc, context.l10n.sortDurationLongest, Icons.arrow_downward, provider.sortOption),
                _buildSortMenuItem(context, SortOption.durationAsc, context.l10n.sortDurationShortest, Icons.arrow_upward, provider.sortOption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () {
              Navigator.pushNamed(context, '/prompts');
            },
            tooltip: context.l10n.managePrompts,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: context.l10n.settings,
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasApiKey = context.select<SettingsProvider, bool>((s) => s.hasApiKey);

          if (historyProvider.history.isEmpty) {
            return Column(
              children: [
                if (!hasApiKey) _buildApiKeyBanner(context),
                Expanded(
                  child: EmptyStateWidget(
                    icon: Icons.mic,
                    title: context.l10n.noRecordings,
                    subtitle: context.l10n.noRecordingsSubtitle,
                    action: FilledButton.icon(
                      onPressed: _startNewRecording,
                      icon: const Icon(Icons.mic),
                      label: Text(context.l10n.recording),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              if (!hasApiKey) _buildApiKeyBanner(context),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  cacheExtent: 500,
                  itemCount: historyProvider.history.length,
                  itemBuilder: (context, index) {
                    final history = historyProvider.history[index];
                    return RecordingCard(
                      key: ValueKey(history.id),
                      history: history,
                      isPlaying: _currentlyPlayingId == history.id,
                      onPlay: () => _togglePlay(history),
                      onTranscribe: () => _openSession(history, autoStartTranscription: true),
                      onTap: () => _openSession(history),
                      onRename: () => _renameRecording(history),
                      onExport: () => _exportRecording(history),
                      onChat: history.transcription != null ? () => _openChat(history) : null,
                      onDelete: () => _deleteRecording(history),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
          if (_isFabExpanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _isFabExpanded = false;
                  });
                },
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.scrim.withValues(
                        alpha: AppOpacity.scrim,
                      ),
                ),
              ),
            ),
        ],
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
              label: Text(context.l10n.selectFile),
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
              label: Text(context.l10n.recording),
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
      title: Text(context.l10n.renameRecording),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: context.l10n.name,
          hintText: context.l10n.newName,
        ),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(context.l10n.rename),
        ),
      ],
    );
  }
}
