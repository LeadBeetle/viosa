import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_file.dart';
import '../models/transcription_result.dart';
import '../models/prompt_result.dart';
import '../models/transcription_history.dart';
import '../services/file_service.dart';
import '../services/audio_service.dart';
import '../services/openrouter_service.dart';
import '../services/prompt_service.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../providers/session_state_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/file_info_card.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/streaming_text_display.dart';
import '../widgets/collapsible_text_section.dart';
import '../widgets/prompt_selector_dialog.dart';
import '../widgets/speed_dial_fab.dart';
import '../widgets/new_transcription_button.dart';
import '../services/streaming_llm_service.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';
import 'prompts_screen.dart';
import 'history_screen.dart';

/// Main screen of the application
/// Follows Single Responsibility Principle: Manages UI state and user interactions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dependency injection for better testability (Dependency Inversion Principle)
  // Only keep services that are not managed by providers
  final IFileService _fileService = FileService();
  final IAudioService _audioService = AudioService();
  final ITranscriptionService _transcriptionService = OpenRouterService();
  final IStreamingLLMService _streamingLLMService = StreamingLLMService();
  final IPromptService _promptService = PromptService();

  AudioFile? _selectedFile;
  TranscriptionResult? _transcriptionResult;
  bool _isTranscribing = false;
  String? _errorMessage;
  final List<PromptResult> _promptResults = [];
  bool _showRecorder = false;
  String? _currentHistoryId;
  final ScrollController _scrollController = ScrollController();

  // Streaming state
  Stream<String>? _transcriptionStream;
  final StringBuffer _transcriptionBuffer = StringBuffer();
  Stream<String>? _promptStream;
  final StringBuffer _promptBuffer = StringBuffer();
  String? _currentPromptName;
  String? _currentPromptTemplate;

  @override
  void initState() {
    super.initState();
    _restoreSessionState();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Restore session state from SessionStateProvider
  Future<void> _restoreSessionState() async {
    final sessionProvider = context.read<SessionStateProvider>();

    // Wait for session to be initialized if not already
    if (!sessionProvider.isInitialized) {
      await sessionProvider.initialize();
    }

    // Restore state from session
    setState(() {
      _selectedFile = sessionProvider.selectedFile;
      _transcriptionResult = sessionProvider.transcriptionResult;
      _promptResults.clear();
      _promptResults.addAll(sessionProvider.promptResults);
      _currentHistoryId = sessionProvider.currentHistoryId;
    });

    // Load audio if file was restored
    if (_selectedFile != null) {
      try {
        await _audioService.loadAudio(_selectedFile!.path);
      } catch (e) {
        // File might not exist anymore, clear session
        if (mounted) {
          setState(() {
            _selectedFile = null;
            _transcriptionResult = null;
            _promptResults.clear();
            _currentHistoryId = null;
          });
          await sessionProvider.clearSession();
        }
      }
    }
  }

  /// Shows confirmation dialog if there's an active session
  Future<bool> _confirmDiscardSession() async {
    // If no active session, no need to confirm
    if (_selectedFile == null && _transcriptionResult == null) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aktuelle Session verwerfen?'),
          content: const Text(
            'Sie haben bereits eine Audiodatei ausgewählt oder transkribiert. '
            'Möchten Sie diese Session verwerfen und eine neue starten?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Neue Session starten'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Scroll to top of the page with smooth animation
  Future<void> _scrollToTop() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickFile() async {
    // Confirm if there's an active session
    final shouldProceed = await _confirmDiscardSession();
    if (!shouldProceed || !mounted) return;

    try {
      setState(() {
        _errorMessage = null;
      });

      final file = await _fileService.pickAudioFile(context);

      if (file != null && mounted) {
        setState(() {
          _selectedFile = file;
          _transcriptionResult = null;
          _promptResults.clear();
          _currentHistoryId = null;
        });

        await _audioService.loadAudio(file.path);

        // Update session state
        if (mounted) {
          final sessionProvider = context.read<SessionStateProvider>();
          await sessionProvider.updateSession(
            selectedFile: file,
            transcriptionResult: null,
            promptResults: [],
            currentHistoryId: null,
          );

          // Scroll to top and show success
          await _scrollToTop();
          _showSuccessSnackBar('Datei erfolgreich geladen');
        }
      }
    } catch (e) {
      String errorMsg = 'Fehler beim Laden der Datei: $e';

      // Better error message for permission issues
      if (e.toString().contains('Speicherberechtigung')) {
        errorMsg = 'Zugriff auf Dateien verweigert. Bitte erlauben Sie den Zugriff in den App-Einstellungen.';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMsg;
        });
        _showErrorSnackBar(_errorMessage!);
      }
    }
  }

  Future<void> _transcribe() async {
    if (_selectedFile == null) {
      _showErrorSnackBar('Bitte wählen Sie zuerst eine Audio-Datei aus');
      return;
    }

    // Get API key and language from SettingsProvider
    final settingsProvider = context.read<SettingsProvider>();
    final apiKey = settingsProvider.apiKey;

    if (apiKey == null || apiKey.isEmpty) {
      _showErrorSnackBar('Bitte konfigurieren Sie Ihren API-Key in den Einstellungen');
      return;
    }

    setState(() {
      _isTranscribing = true;
      _errorMessage = null;
      _transcriptionResult = null;
      _transcriptionBuffer.clear();
    });

    try {
      final language = settingsProvider.language;

      // Start streaming transcription
      final stream = _transcriptionService.transcribeAudioStreaming(
        apiKey: apiKey,
        base64Audio: _selectedFile!.base64Data,
        mimeType: _selectedFile!.mimeType,
        language: language,
      );

      setState(() {
        _transcriptionStream = stream;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isTranscribing = false;
        _transcriptionStream = null;
      });
      if (mounted) {
        _showErrorSnackBar(_errorMessage!);
      }
    }
  }

  void _onTranscriptionComplete() async {
    setState(() {
      _isTranscribing = false;
    });

    final transcribedText = _transcriptionBuffer.toString();

    if (transcribedText.isNotEmpty) {
      final settingsProvider = context.read<SettingsProvider>();
      final result = TranscriptionResult(
        text: transcribedText,
        language: settingsProvider.language,
        modelUsed: AppConstants.llmModel,
        timestamp: DateTime.now(),
      );

      setState(() {
        _transcriptionResult = result;
        _transcriptionStream = null;
      });

      // Update SessionStateProvider with transcription result
      if (mounted) {
        final sessionProvider = context.read<SessionStateProvider>();
        await sessionProvider.setTranscriptionResult(result);

        // Save to history using HistoryProvider
        await _saveToHistory();
      }

      if (mounted) {
        _showSuccessSnackBar('Transkription erfolgreich abgeschlossen');
      }
    }
  }

  void _onTranscriptionError(String error) {
    setState(() {
      _errorMessage = error;
      _isTranscribing = false;
      _transcriptionStream = null;
    });
    if (mounted) {
      _showErrorSnackBar(error);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _navigateToPrompts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PromptsScreen()),
    );
  }

  Future<void> _navigateToHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  Future<void> _saveToHistory() async {
    if (_selectedFile == null || _transcriptionResult == null) {
      return;
    }

    try {
      final history = TranscriptionHistory(
        id: _currentHistoryId,
        audioFileName: _selectedFile!.name,
        transcription: _transcriptionResult!,
        promptResults: _promptResults,
      );

      // Save using HistoryProvider
      if (mounted) {
        final historyProvider = context.read<HistoryProvider>();
        await historyProvider.saveHistory(history);

        // Update current history ID
        setState(() {
          _currentHistoryId = history.id;
        });

        // Update session state with current history ID
        if (mounted) {
          final sessionProvider = context.read<SessionStateProvider>();
          await sessionProvider.setCurrentHistoryId(history.id);
        }
      }
    } catch (e) {
      // Silent fail - don't interrupt user workflow
    }
  }

  Future<void> _applyPromptStreaming() async {
    if (_transcriptionResult == null) {
      return;
    }

    // Show dialog to select prompt
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const PromptSelectorDialog(),
    );

    if (result != null && mounted) {
      final promptName = result['promptName']!;
      final promptTemplate = result['promptTemplate']!;

      // Start streaming prompt response on main page
      _startPromptStreaming(promptName, promptTemplate);
    }
  }

  void _startPromptStreaming(String promptName, String promptTemplate) {
    final settingsProvider = context.read<SettingsProvider>();
    final apiKey = settingsProvider.apiKey;

    if (apiKey == null || apiKey.isEmpty) {
      _showErrorSnackBar('Bitte konfigurieren Sie Ihren API-Key in den Einstellungen');
      return;
    }

    if (_transcriptionResult == null) return;

    setState(() {
      _currentPromptName = promptName;
      _currentPromptTemplate = promptTemplate;
      _promptBuffer.clear();
    });

    try {
      // Apply template with auto-injection support to replace {transcription} placeholder
      final promptText = _promptService.applyPromptTemplate(
        promptTemplate,
        _transcriptionResult!.text,
      );

      final stream = _streamingLLMService.applyPromptStreaming(
        apiKey: apiKey,
        promptName: promptName,
        promptTemplate: promptText,
        transcriptionText: _transcriptionResult!.text,
      );

      setState(() {
        _promptStream = stream;
      });
    } catch (e) {
      _showErrorSnackBar('Fehler beim Starten des Prompts: $e');
      setState(() {
        _currentPromptName = null;
        _currentPromptTemplate = null;
      });
    }
  }

  void _onPromptComplete() async {
    final promptResponse = _promptBuffer.toString();

    if (promptResponse.isNotEmpty && _currentPromptName != null) {
      final result = PromptResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        promptName: _currentPromptName!,
        promptTemplate: _currentPromptTemplate!,
        transcriptionText: _transcriptionResult!.text,
        llmResponse: promptResponse,
        modelUsed: AppConstants.llmModel,
        timestamp: DateTime.now(),
      );

      setState(() {
        _promptResults.add(result);
        _promptStream = null;
        _currentPromptName = null;
        _currentPromptTemplate = null;
      });

      // Update SessionStateProvider with new prompt result
      if (mounted) {
        final sessionProvider = context.read<SessionStateProvider>();
        await sessionProvider.addPromptResult(result);

        // Update history with new prompt result using HistoryProvider
        await _saveToHistory();

        _showSuccessSnackBar('Prompt erfolgreich angewendet');
      }
    }
  }

  void _onPromptError(String error) {
    _showErrorSnackBar('Prompt-Fehler: $error');
    setState(() {
      _promptStream = null;
      _currentPromptName = null;
      _currentPromptTemplate = null;
    });
  }

  void _removePromptResult(String resultId) {
    setState(() {
      _promptResults.removeWhere((r) => r.id == resultId);
    });

    // Update session state
    final sessionProvider = context.read<SessionStateProvider>();
    sessionProvider.setPromptResults(List.from(_promptResults));
  }

  void _onRecordingComplete(AudioFile audioFile) async {
    setState(() {
      _selectedFile = audioFile;
      _transcriptionResult = null;
      _promptResults.clear();
      _currentHistoryId = null;
      _showRecorder = false;
    });

    await _audioService.loadAudio(audioFile.path);

    // Update session state
    if (mounted) {
      final sessionProvider = context.read<SessionStateProvider>();
      await sessionProvider.updateSession(
        selectedFile: audioFile,
        transcriptionResult: null,
        promptResults: [],
        currentHistoryId: null,
      );

      // Scroll to top and show success
      await _scrollToTop();
      _showSuccessSnackBar('Aufnahme erfolgreich abgeschlossen');
    }
  }

  Future<void> _startNewRecording() async {
    // Confirm if there's an active session
    final shouldProceed = await _confirmDiscardSession();
    if (!shouldProceed || !mounted) return;

    // Clear session and show recorder
    setState(() {
      _selectedFile = null;
      _transcriptionResult = null;
      _promptResults.clear();
      _currentHistoryId = null;
      _showRecorder = true;
    });

    // Update session state
    if (mounted) {
      final sessionProvider = context.read<SessionStateProvider>();
      await sessionProvider.clearSession();

      // Scroll to top to show recorder
      await _scrollToTop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/viosa_icon.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'Historie',
          ),
          IconButton(
            icon: const Icon(Icons.text_snippet),
            onPressed: _navigateToPrompts,
            tooltip: 'Prompts',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Einstellungen',
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showRecorder) ...[
              AudioRecorderWidget(
                onRecordingComplete: _onRecordingComplete,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ] else if (_selectedFile != null) ...[
              FileInfoCard(file: _selectedFile!),
              const SizedBox(height: AppConstants.defaultPadding),
              AudioPlayerWidget(
                audioService: _audioService,
                fileName: _selectedFile!.name,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              ElevatedButton.icon(
                onPressed: _isTranscribing ? null : _transcribe,
                icon: _isTranscribing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.transcribe),
                label: Text(_isTranscribing ? 'Transkribiere...' : 'Transkribieren'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/viosa_icon.png',
                        width: 120,
                        height: 120,
                        opacity: const AlwaysStoppedAnimation(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Keine Audio-Datei ausgewählt',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tippen Sie auf das Symbol unten rechts, um eine Audio-Datei auszuwählen',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            // Streaming transcription display
            if (_transcriptionStream != null) ...[
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => StreamingTextDisplay(
                  title: 'Transkription',
                  textStream: _transcriptionStream,
                  contentStyle: TextStyle(
                    fontSize: settings.textSize,
                    height: 1.5,
                  ),
                  metadata: Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('Sprache: ${settings.language}'),
                        avatar: const Icon(Icons.language, size: 16),
                      ),
                      Chip(
                        label: Text('Modell: ${AppConstants.llmModel}'),
                        avatar: const Icon(Icons.memory, size: 16),
                      ),
                    ],
                  ),
                  onStreamComplete: _onTranscriptionComplete,
                  onStreamError: _onTranscriptionError,
                  onChunk: (chunk) => _transcriptionBuffer.write(chunk),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ] else if (_transcriptionResult != null) ...[
              // Completed transcription (collapsible)
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => CollapsibleTextSection(
                  title: 'Transkription',
                  content: _transcriptionResult!.text,
                  isExpanded: true,
                  contentStyle: TextStyle(
                    fontSize: settings.textSize,
                    height: 1.5,
                  ),
                  metadata: Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('Sprache: ${_transcriptionResult!.language}'),
                        avatar: const Icon(Icons.language, size: 16),
                      ),
                      Chip(
                        label: Text('Modell: ${_transcriptionResult!.modelUsed}'),
                        avatar: const Icon(Icons.memory, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              // Apply prompt button
              ElevatedButton.icon(
                onPressed: _promptStream == null ? _applyPromptStreaming : null,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Prompt anwenden'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],
            // Streaming prompt response display
            if (_promptStream != null) ...[
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => StreamingTextDisplay(
                  title: 'Prompt: $_currentPromptName',
                  textStream: _promptStream,
                  contentStyle: TextStyle(
                    fontSize: settings.textSize,
                    height: 1.5,
                  ),
                  metadata: Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('Modell: ${AppConstants.llmModel}'),
                        avatar: const Icon(Icons.memory, size: 16),
                      ),
                    ],
                  ),
                  onStreamComplete: _onPromptComplete,
                  onStreamError: _onPromptError,
                  onChunk: (chunk) => _promptBuffer.write(chunk),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],
            // Completed prompt results (collapsible)
            if (_promptResults.isNotEmpty) ...[
              Text(
                'Prompt-Ergebnisse',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Consumer<SettingsProvider>(
                builder: (context, settings, _) => Column(
                  children: _promptResults.map(
                    (result) => Dismissible(
                      key: Key(result.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Prompt-Ergebnis löschen?'),
                              content: Text(
                                'Möchten Sie das Ergebnis "${result.promptName}" wirklich löschen?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Abbrechen'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Löschen'),
                                ),
                              ],
                            );
                          },
                        ) ?? false;
                      },
                      onDismissed: (direction) {
                        _removePromptResult(result.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${result.promptName} gelöscht'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: CollapsibleTextSection(
                        title: 'Prompt: ${result.promptName}',
                        content: result.llmResponse,
                        isExpanded: false,
                        contentStyle: TextStyle(
                          fontSize: settings.textSize,
                          height: 1.5,
                        ),
                        metadata: Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text('Modell: ${result.modelUsed}'),
                              avatar: const Icon(Icons.memory, size: 16),
                            ),
                            Chip(
                              label: Text(
                                '${result.timestamp.day}.${result.timestamp.month}.${result.timestamp.year} ${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}',
                              ),
                              avatar: const Icon(Icons.access_time, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],
            // "Neue Transkription" button - only show when transcription is complete
            if (_transcriptionResult != null && _promptStream == null) ...[
              NewTranscriptionButton(
                onRecordTap: _startNewRecording,
                onFileTap: _pickFile,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ],
          ],
        ),
      ),
      floatingActionButton: SpeedDialFAB(
        onRecordTap: _startNewRecording,
        onFileTap: _pickFile,
      ),
    );
  }
}
