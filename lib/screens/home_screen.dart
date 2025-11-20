import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../models/audio_file.dart';
import '../models/transcription_result.dart';
import '../models/prompt_result.dart';
import '../models/transcription_history.dart';
import '../models/split_transcription_job.dart';
import '../services/file_service.dart';
import '../services/audio_service.dart';
import '../services/prompt_service.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../providers/session_state_provider.dart';
import '../providers/split_transcription_provider.dart';
import '../providers/prompts_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/file_info_card.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/prompt_selector_dialog.dart';
import '../widgets/speed_dial_fab.dart';
import '../widgets/new_transcription_button.dart';
import '../widgets/split_transcription_progress_card.dart';
import '../widgets/recording_name_dialog.dart';
import '../widgets/empty_audio_file_state.dart';
import '../widgets/transcription_button.dart';
import '../widgets/prompt_results_list.dart';
import '../widgets/app_bar_title_with_logo.dart';
import '../widgets/split_loading_card.dart';
import '../widgets/streaming_transcription_card.dart';
import '../widgets/completed_transcription_card.dart';
import '../widgets/streaming_prompt_card.dart';
import '../dialogs/session_discard_dialog.dart';
import '../dialogs/transcription_confirmation_dialog.dart';
import '../services/llm_provider.dart';
import '../services/llm_provider_factory.dart';
import '../repositories/model_repository.dart';
import '../utils/constants.dart';
import '../utils/audio_utils.dart';
import '../utils/screen_helpers.dart';
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

class _HomeScreenState extends State<HomeScreen> with ScreenHelpers {
  // Dependency injection for better testability (Dependency Inversion Principle)
  // Only keep services that are not managed by providers
  final IFileService _fileService = FileService();
  final IAudioService _audioService = AudioService();
  final IPromptService _promptService = PromptService();

  // Services that need the model from settings - created on demand
  ILLMProvider _getLLMProvider() {
    final model = context.read<SettingsProvider>().selectedModel;
    return LLMProviderFactory.createForModel(model);
  }

  AudioFile? _selectedFile;
  TranscriptionResult? _transcriptionResult;
  bool _isTranscribing = false;
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

  // Cancel token for transcription
  CancelToken? _transcriptionCancelToken;

  // Split transcription state
  SplitTranscriptionJob? _activeSplitJob;
  bool _isSplitTranscription = false;

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
        // Reload the audio file from disk to restore base64Data
        final reloadedFile = await _fileService.reloadAudioFile(_selectedFile!);
        if (reloadedFile != null && mounted) {
          setState(() {
            _selectedFile = reloadedFile;
          });
          // Update session with reloaded file (but don't persist base64Data)
          await sessionProvider.setSelectedFile(reloadedFile);
          await _audioService.loadAudio(reloadedFile.path);
        }
      } catch (e) {
        // File might not exist anymore, clear session
        safeSetState(() {
          _selectedFile = null;
          _transcriptionResult = null;
          _promptResults.clear();
          _currentHistoryId = null;
        });
        if (mounted) {
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

    return await SessionDiscardDialog.show(context);
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

  Future<void> _clearSessionState() async {
    setState(() {
      _selectedFile = null;
      _transcriptionResult = null;
      _promptResults.clear();
      _currentHistoryId = null;
      _showRecorder = false;
    });

    if (mounted) {
      final sessionProvider = context.read<SessionStateProvider>();
      await sessionProvider.clearSession();
    }
  }

  Future<void> _pickFile() async {
    final shouldProceed = await _confirmDiscardSession();
    if (!shouldProceed || !mounted) return;

    final context = this.context;
    try {
      await _clearSessionState();
      final file = await _fileService.pickAudioFile(context);

      if (file != null && mounted) {
        setState(() {
          _selectedFile = file;
        });

        await _audioService.loadAudio(file.path);
        await _updateSessionState(
          selectedFile: file,
          transcriptionResult: null,
          promptResults: [],
          currentHistoryId: null,
        );

        if (mounted) {
          await _scrollToTop();
          showSuccessSnackBar('Datei erfolgreich geladen');
        }
      }
    } catch (e) {
      String errorMsg = 'Fehler beim Laden der Datei: $e';
      if (e.toString().contains('Speicherberechtigung')) {
        errorMsg = 'Zugriff auf Dateien verweigert. Bitte erlauben Sie den Zugriff in den App-Einstellungen.';
      }
      if (mounted) {
        showErrorSnackBar(errorMsg);
      }
    }
  }

  Future<void> _transcribe() async {
    if (_selectedFile == null) {
      showErrorSnackBar('Bitte wählen Sie zuerst eine Audio-Datei aus');
      return;
    }

    // Get API key and language from SettingsProvider
    final settingsProvider = context.read<SettingsProvider>();
    final apiKey = settingsProvider.apiKey;

    if (apiKey == null || apiKey.isEmpty) {
      showErrorSnackBar('Bitte konfigurieren Sie Ihren API-Key in den Einstellungen');
      return;
    }

    // Get audio duration and show transcription dialog
    final duration = await AudioUtils.getAudioDuration(_selectedFile!.path);

    // Always show the transcription dialog with model info
    await _startSplitTranscription(duration);
  }

  void _cancelTranscription() {
    if (_transcriptionCancelToken != null && !_transcriptionCancelToken!.isCancelled) {
      _transcriptionCancelToken!.cancel('Transkription vom Benutzer abgebrochen');
    }

    setState(() {
      _isTranscribing = false;
      _transcriptionStream = null;
      _transcriptionBuffer.clear();
      _transcriptionCancelToken = null;
    });

    showErrorSnackBar('Transkription abgebrochen');
  }

  void _onTranscriptionComplete() async {
    setState(() {
      _isTranscribing = false;
      _transcriptionCancelToken = null;
    });

    final transcribedText = _transcriptionBuffer.toString();

    if (transcribedText.isNotEmpty) {
      final settingsProvider = context.read<SettingsProvider>();
      final result = TranscriptionResult(
        text: transcribedText,
        language: settingsProvider.language,
        modelUsed: settingsProvider.selectedModel,
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
        showSuccessSnackBar('Transkription erfolgreich abgeschlossen');
      }
    }
  }

  void _onTranscriptionError(String error) {
    // Check if error is due to cancellation
    if (error.contains('abgebrochen') || error.contains('cancelled')) {
      // Already handled by _cancelTranscription
      return;
    }

    setState(() {
      _isTranscribing = false;
      _transcriptionStream = null;
      _transcriptionCancelToken = null;
    });
    if (mounted) {
      showErrorSnackBar(error);
    }
  }

  /// Shows dialog and starts transcription
  Future<void> _startSplitTranscription(Duration duration) async {
    if (_selectedFile == null) return;

    final settingsProvider = context.read<SettingsProvider>();
    final shouldSplit = duration > const Duration(minutes: 10);
    final splitCount = shouldSplit
        ? await AudioUtils.calculateSplitCount(_selectedFile!.path)
        : 1;

    // Get selected model info for display
    final selectedModelId = settingsProvider.selectedModel;
    final selectedModel = ModelRepository.getModelByIdOrDefault(selectedModelId);

    // Show confirmation dialog
    final confirmed = await TranscriptionConfirmationDialog.show(
      context,
      duration: duration,
      shouldSplit: shouldSplit,
      splitCount: splitCount,
      selectedModel: selectedModel,
    );

    if (!confirmed || !mounted) return;

    // Get provider before async operations
    final splitProvider = context.read<SplitTranscriptionProvider>();
    final apiKey = settingsProvider.apiKey!;
    final language = settingsProvider.language;
    final audioPath = _selectedFile!.path;
    final fileName = _selectedFile!.name;

    try {
      splitProvider.setApiKey(apiKey);

      // Start job creation and immediately set state to show UI
      setState(() {
        _isSplitTranscription = true;
        _isTranscribing = true;
      });

      final model = context.read<SettingsProvider>().selectedModel;
      final job = await splitProvider.startTranscription(
        audioPath: audioPath,
        fileName: fileName,
        language: language,
        apiKey: apiKey,
        model: model,
      );

      if (mounted) {
        // Listen for job updates FIRST (before setting state)
        _listenToSplitJobUpdates(job.id);

        setState(() {
          _activeSplitJob = job;
        });

        showSuccessSnackBar('Split-Transkription gestartet');
      }
    } catch (e) {
      safeSetState(() {
        _isTranscribing = false;
        _isSplitTranscription = false;
        _activeSplitJob = null;
      });
      if (mounted) {
        showErrorSnackBar('Fehler beim Starten der Split-Transkription: $e');
      }
    }
  }

  /// Listens to split job updates and handles completion
  void _listenToSplitJobUpdates(String jobId) {
    final splitProvider = context.read<SplitTranscriptionProvider>();
    bool completionHandled = false;

    splitProvider.jobUpdates.listen((job) {
      if (!mounted) return;
      if (job.id != jobId) return;

      setState(() {
        _activeSplitJob = job;
      });

      // Handle job completion (only once)
      if (job.isFinished && !completionHandled) {
        completionHandled = true;
        _onSplitTranscriptionComplete(job);
      }
    });
  }

  /// Handles split transcription completion
  Future<void> _onSplitTranscriptionComplete(SplitTranscriptionJob job) async {
    setState(() {
      _isTranscribing = false;
    });

    if (job.isFullySuccessful || (job.completedCount > 0 && job.failedCount < job.totalSplits)) {
      final mergedText = job.mergedTranscription;

      if (mergedText != null && mergedText.isNotEmpty) {
        final settingsProvider = context.read<SettingsProvider>();
        final result = TranscriptionResult(
          text: mergedText,
          language: job.language,
          modelUsed: settingsProvider.selectedModel,
          timestamp: job.completedAt ?? DateTime.now(),
        );

        setState(() {
          _transcriptionResult = result;
          // Clear split job UI elements now that we have the result
          _activeSplitJob = null;
          _isSplitTranscription = false;
        });

        // Save to history
        if (mounted) {
          final sessionProvider = context.read<SessionStateProvider>();
          await sessionProvider.setTranscriptionResult(result);

          await _saveSplitJobToHistory(job, result);
        }

        if (job.failedCount > 0) {
          showSuccessSnackBar(
            'Transkription abgeschlossen mit ${job.failedCount} fehlgeschlagenen Segmenten',
          );
        } else {
          showSuccessSnackBar('Transkription erfolgreich abgeschlossen');
        }
      }
    } else {
      setState(() {
        // Clear split job UI on failure too
        _activeSplitJob = null;
        _isSplitTranscription = false;
      });
      showErrorSnackBar('Transkription fehlgeschlagen');
    }
  }

  /// Saves split job to history
  Future<void> _saveSplitJobToHistory(
    SplitTranscriptionJob job,
    TranscriptionResult result,
  ) async {
    if (_selectedFile == null) return;

    try {
      final history = TranscriptionHistory(
        id: _currentHistoryId,
        audioFileName: _selectedFile!.name,
        transcription: result,
        promptResults: _promptResults,
        splitJobId: job.id,
        isSplitTranscription: true,
      );

      if (mounted) {
        final historyProvider = context.read<HistoryProvider>();
        await historyProvider.saveHistory(history);

        setState(() {
          _currentHistoryId = history.id;
        });

        if (mounted) {
          final sessionProvider = context.read<SessionStateProvider>();
          await sessionProvider.setCurrentHistoryId(history.id);
        }
      }
    } catch (e) {
      // Silent fail
      debugPrint('Error saving split job to history: $e');
    }
  }

  /// Updates the session state with current data
  /// Centralizes session state updates to avoid duplication
  Future<void> _updateSessionState({
    AudioFile? selectedFile,
    TranscriptionResult? transcriptionResult,
    List<PromptResult>? promptResults,
    String? currentHistoryId,
  }) async {
    if (!mounted) return;

    final sessionProvider = context.read<SessionStateProvider>();
    await sessionProvider.updateSession(
      selectedFile: selectedFile ?? _selectedFile,
      transcriptionResult: transcriptionResult ?? _transcriptionResult,
      promptResults: promptResults ?? _promptResults,
      currentHistoryId: currentHistoryId ?? _currentHistoryId,
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
      final promptId = result['promptId']!;
      final promptName = result['promptName']!;
      final promptTemplate = result['promptTemplate']!;

      // Track prompt usage
      final promptsProvider = context.read<PromptsProvider>();
      await promptsProvider.incrementUsage(promptId);

      // Start streaming prompt response on main page
      _startPromptStreaming(promptName, promptTemplate);
    }
  }

  void _startPromptStreaming(String promptName, String promptTemplate) {
    final settingsProvider = context.read<SettingsProvider>();
    final apiKey = settingsProvider.apiKey;

    if (apiKey == null || apiKey.isEmpty) {
      showErrorSnackBar('Bitte konfigurieren Sie Ihren API-Key in den Einstellungen');
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

      final stream = _getLLMProvider().applyPromptStreaming(
        apiKey: apiKey,
        promptName: promptName,
        promptTemplate: promptText,
        transcriptionText: _transcriptionResult!.text,
      );

      setState(() {
        _promptStream = stream;
      });
    } catch (e) {
      showErrorSnackBar('Fehler beim Starten des Prompts: $e');
      setState(() {
        _currentPromptName = null;
        _currentPromptTemplate = null;
      });
    }
  }

  void _onPromptComplete() async {
    final promptResponse = _promptBuffer.toString();

    if (promptResponse.isNotEmpty && _currentPromptName != null) {
      final settingsProvider = context.read<SettingsProvider>();
      final result = PromptResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        promptName: _currentPromptName!,
        promptTemplate: _currentPromptTemplate!,
        transcriptionText: _transcriptionResult!.text,
        llmResponse: promptResponse,
        modelUsed: settingsProvider.selectedModel,
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

        showSuccessSnackBar('Prompt erfolgreich angewendet');
      }
    }
  }

  void _onPromptError(String error) {
    showErrorSnackBar('Prompt-Fehler: $error');
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
    await _updateSessionState(
      selectedFile: audioFile,
      transcriptionResult: null,
      promptResults: [],
      currentHistoryId: null,
    );

    if (mounted) {

      // Scroll to top and show success with recording name
      await _scrollToTop();
      // Extract display name without extension for user-friendly message
      final displayName = audioFile.name.endsWith('.m4a')
          ? audioFile.name.substring(0, audioFile.name.length - 4)
          : audioFile.name;
      showSuccessSnackBar('Aufnahme "$displayName" gespeichert');
    }
  }

  Future<void> _renameRecording() async {
    if (_selectedFile == null) return;

    final newName = await RecordingNameDialog.show(
      context,
      initialName: _selectedFile!.name,
    );

    if (newName == null || !mounted) return;

    try {
      // Use FileService to rename the file
      final updatedFile = await _fileService.renameAudioFile(_selectedFile!, newName);

      // Reload audio in player with new path
      await _audioService.loadAudio(updatedFile.path);

      setState(() {
        _selectedFile = updatedFile;
      });

      // Update session state
      await _updateSessionState(selectedFile: updatedFile);

      if (mounted) {
        showSuccessSnackBar('Aufnahme umbenannt zu "$newName"');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar('Fehler beim Umbenennen: $e');
      }
    }
  }

  Future<void> _startNewRecording() async {
    final shouldProceed = await _confirmDiscardSession();
    if (!shouldProceed || !mounted) return;

    await _clearSessionState();
    setState(() {
      _showRecorder = true;
    });

    if (mounted) {
      await _scrollToTop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitleWithLogo(),
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
              FileInfoCard(
                file: _selectedFile!,
                onRename: _renameRecording,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              AudioPlayerWidget(
                audioService: _audioService,
                fileName: _selectedFile!.name,
                filePath: _selectedFile!.path,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TranscriptionButton(
                isTranscribing: _isTranscribing,
                onPressed: _isTranscribing ? _cancelTranscription : _transcribe,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
            ] else
              const EmptyAudioFileState(),
            // Split transcription progress card
            if (_isSplitTranscription) ...[
              if (_activeSplitJob != null)
                SplitTranscriptionProgressCard(
                  job: _activeSplitJob!,
                  onCancel: () async {
                    final splitProvider = context.read<SplitTranscriptionProvider>();
                    await splitProvider.cancelJob(_activeSplitJob!.id);
                    setState(() {
                      _activeSplitJob = null;
                      _isSplitTranscription = false;
                      _isTranscribing = false;
                    });
                  },
                  onViewMerged: _activeSplitJob!.mergedTranscription != null
                      ? () {
                          // Transcription is already set, just scroll to it
                          _scrollToTop();
                        }
                      : null,
                )
              else
                const SplitLoadingCard(),
              const SizedBox(height: AppConstants.defaultPadding),
            ],
            // Streaming transcription display
            if (_transcriptionStream != null)
              StreamingTranscriptionCard(
                textStream: _transcriptionStream,
                onStreamComplete: _onTranscriptionComplete,
                onStreamError: _onTranscriptionError,
                onChunk: (chunk) => _transcriptionBuffer.write(chunk),
              )
            else if (_transcriptionResult != null)
              CompletedTranscriptionCard(
                transcriptionResult: _transcriptionResult!,
                isPromptActive: _promptStream != null,
                onApplyPrompt: _applyPromptStreaming,
              ),
            // Streaming prompt response display
            if (_promptStream != null)
              StreamingPromptCard(
                promptName: _currentPromptName ?? '',
                textStream: _promptStream,
                onStreamComplete: _onPromptComplete,
                onStreamError: _onPromptError,
                onChunk: (chunk) => _promptBuffer.write(chunk),
              ),
            // Completed prompt results (collapsible)
            PromptResultsList(
              results: _promptResults,
              onDelete: _removePromptResult,
            ),
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
