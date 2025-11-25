import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_file.dart';
import '../models/transcription_result.dart';
import '../models/prompt_result.dart';
import '../models/transcription_history.dart';
import '../models/split_transcription_job.dart';
import '../services/audio_service.dart';
import '../services/speaker_extraction_service.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../providers/split_transcription_provider.dart';
import '../providers/prompts_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/mini_audio_player_widget.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/prompt_selector_bottom_sheet.dart';
import '../widgets/split_transcription_progress_card.dart';
import '../widgets/transcription_button.dart';
import '../widgets/prompt_results_list.dart';
import '../widgets/streaming_transcription_card.dart';
import '../widgets/completed_transcription_card.dart';
import '../widgets/streaming_prompt_card.dart';
import '../dialogs/transcription_confirmation_dialog.dart';
import '../services/llm_provider_factory.dart';
import '../repositories/model_repository.dart';
import '../utils/constants.dart';
import '../utils/audio_utils.dart';
import '../utils/screen_helpers.dart';
import '../services/snackbar_service.dart';
import 'chat_screen.dart';

class SessionScreen extends StatefulWidget {
  final AudioFile? initialFile;
  final bool autoStartRecording;
  final bool autoStartTranscription;
  final String? historyId;

  const SessionScreen({
    super.key,
    this.initialFile,
    this.autoStartRecording = false,
    this.autoStartTranscription = false,
    this.historyId,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with ScreenHelpers {
  final IAudioService _audioService = AudioService();

  AudioFile? _selectedFile;
  TranscriptionResult? _transcriptionResult;
  bool _isTranscribing = false;
  final List<PromptResult> _promptResults = [];
  bool _showRecorder = false;
  String? _currentHistoryId;
  Duration? _audioDuration;

  // Waveform data for new recordings
  List<double> _recordedAmplitudes = [];

  // Audio playback state for collapsible player
  Duration _audioPosition = Duration.zero;
  Duration _audioTotalDuration = Duration.zero;
  bool _isAudioPlaying = false;

  // Audio stream subscriptions
  final List<StreamSubscription> _audioSubscriptions = [];

  // Scroll state for collapsible player
  bool _isPlayerCollapsed = false;

  // Streaming state
  Stream<String>? _transcriptionStream;
  Stream<String>? _promptStream;
  final StringBuffer _promptBuffer = StringBuffer();
  String? _currentPromptName;

  // Split transcription state
  SplitTranscriptionJob? _activeSplitJob;
  bool _isSplitTranscription = false;

  bool _showTranscriptionSuccess = false;
  String? _currentPromptTemplate;

  @override
  void initState() {
    super.initState();
    _currentHistoryId = widget.historyId;
    _setupAudioListeners();

    if (widget.initialFile != null) {
      _loadInitialFile();
    } else if (widget.historyId != null) {
      // Load existing history entry
      _loadFromHistory();
    } else if (widget.autoStartRecording) {
      _showRecorder = true;
    } else {
      // Restore session if available and no specific file requested
      _restoreSessionState();
    }
  }

  void _setupAudioListeners() {
    Duration pendingPosition = _audioPosition;
    Duration pendingDuration = _audioTotalDuration;
    bool pendingPlaying = _isAudioPlaying;
    bool updateScheduled = false;

    void scheduleUpdate() {
      if (updateScheduled || !mounted) return;
      updateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _audioPosition = pendingPosition;
            _audioTotalDuration = pendingDuration;
            _isAudioPlaying = pendingPlaying;
          });
        }
        updateScheduled = false;
      });
    }

    _audioSubscriptions.add(
      _audioService.positionStream.listen((position) {
        pendingPosition = position;
        scheduleUpdate();
      }),
    );

    _audioSubscriptions.add(
      _audioService.durationStream.listen((duration) {
        pendingDuration = duration ?? Duration.zero;
        scheduleUpdate();
      }),
    );

    _audioSubscriptions.add(
      _audioService.playingStream.listen((playing) {
        pendingPlaying = playing;
        scheduleUpdate();
      }),
    );
  }

  Future<void> _togglePlayPause() async {
    if (_isAudioPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.play();
    }
  }

  Future<void> _loadFromHistory() async {
    if (_currentHistoryId == null) return;

    final historyProvider = context.read<HistoryProvider>();
    final history = historyProvider.getHistoryById(_currentHistoryId!);

    if (history == null) return;

    // Load audio file if path exists
    if (history.audioPath != null) {
      try {
        final file = File(history.audioPath!);
        if (await file.exists()) {
          final audioFile = AudioFile(
            path: file.path,
            name: history.audioFileName,
            base64Data: null,
            mimeType: 'audio/mp4',
            size: await file.length(),
          );

          setState(() {
            _selectedFile = audioFile;
            _audioDuration = history.duration;
            _transcriptionResult = history.transcription;
            _promptResults.clear();
            _promptResults.addAll(history.promptResults);
            // Load waveform data from history
            if (history.waveform != null && history.waveform!.isNotEmpty) {
              _recordedAmplitudes = List.from(history.waveform!);
            }
          });

          await _audioService.loadAudio(audioFile.path);

          // Auto-start transcription if requested and no transcription exists
          if (widget.autoStartTranscription && history.transcription == null && mounted) {
            _transcribe();
          }
        }
      } catch (e) {
        debugPrint('Error loading file from history: $e');
      }
    } else {
      // No audio path, just load transcription and prompts
      setState(() {
        _transcriptionResult = history.transcription;
        _promptResults.clear();
        _promptResults.addAll(history.promptResults);
      });
    }
  }

  Future<void> _loadInitialFile() async {
    setState(() {
      _selectedFile = widget.initialFile;
    });

    if (_selectedFile != null) {
      await _audioService.loadAudio(_selectedFile!.path);
      final duration = await AudioUtils.getAudioDuration(_selectedFile!.path);
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }

      // If we have a history ID, try to load existing results
      if (_currentHistoryId != null) {
        final historyProvider = context.read<HistoryProvider>();
        final history = historyProvider.getHistoryById(_currentHistoryId!);
        if (history != null) {
          if (_selectedFile == null && history.audioPath != null) {
             try {
               final file = File(history.audioPath!);
               if (await file.exists()) {
                 final audioFile = AudioFile(
                   path: file.path,
                   name: history.audioFileName,
                   base64Data: null,
                   mimeType: 'audio/mp4', // Assume mp4/m4a for now
                   size: await file.length(),
                 );
                 setState(() {
                   _selectedFile = audioFile;
                   _audioDuration = history.duration;
                 });
                 await _audioService.loadAudio(audioFile.path);
               }
             } catch (e) {
               debugPrint('Error loading file from history: $e');
             }
          }

          setState(() {
            _transcriptionResult = history.transcription;
            _promptResults.clear();
            _promptResults.addAll(history.promptResults);
            // Load waveform data from history
            if (history.waveform != null && history.waveform!.isNotEmpty) {
              _recordedAmplitudes = List.from(history.waveform!);
            }
          });
        }
      } else {
        // New file picked - save initial history entry with duration
        await _saveToHistory();
      }
    }
  }

  Future<void> _restoreSessionState() async {
    // Logic to restore session if needed, similar to HomeScreen
    // For now, we might skip this if we want to enforce clean sessions or specific history items
  }

  @override
  void dispose() {
    for (final subscription in _audioSubscriptions) {
      subscription.cancel();
    }
    _audioService.dispose();
    super.dispose();
  }

  void _onRecordingComplete(AudioFile file) async {
    setState(() {
      _selectedFile = file;
      _showRecorder = false;
    });

    await _audioService.loadAudio(file.path);
    final duration = await AudioUtils.getAudioDuration(file.path);
    
    setState(() {
      _audioDuration = duration;
    });

    // Save initial history entry with audio and waveform
    await _saveToHistory();
  }
  
  // Callback to receive waveform data from recorder
  void _onWaveformUpdate(List<double> amplitudes) {
    _recordedAmplitudes = List.from(amplitudes);
  }

  Future<void> _transcribe() async {
    if (_selectedFile == null) return;

    final settingsProvider = context.read<SettingsProvider>();
    final apiKey = settingsProvider.apiKey;

    if (apiKey == null || apiKey.isEmpty) {
      SnackBarService().showError(context, 'Bitte API-Key konfigurieren');
      return;
    }

    final duration = await AudioUtils.getAudioDuration(_selectedFile!.path);
    await _startSplitTranscription(duration);
  }

  Future<void> _retranscribe() async {
    setState(() {
      _transcriptionResult = null;
      _promptResults.clear();
    });
    await _saveToHistory();
    await _transcribe();
  }

  void _openChat() {
    if (_currentHistoryId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(historyId: _currentHistoryId!),
      ),
    );
  }

  Future<void> _startSplitTranscription(Duration duration) async {
    final settingsProvider = context.read<SettingsProvider>();
    final shouldSplit = duration > const Duration(minutes: 10);
    final splitCount = shouldSplit
        ? await AudioUtils.calculateSplitCount(_selectedFile!.path)
        : 1;

    final selectedModelId = settingsProvider.selectedModel;
    final selectedModel = ModelRepository.getModelByIdOrDefault(selectedModelId);
    final hasExistingData = _transcriptionResult != null || _promptResults.isNotEmpty;

    final confirmed = await TranscriptionConfirmationDialog.show(
      context,
      duration: duration,
      shouldSplit: shouldSplit,
      splitCount: splitCount,
      selectedModel: selectedModel,
      hasExistingData: hasExistingData,
    );

    if (!confirmed || !mounted) return;

    if (hasExistingData) {
      setState(() {
        _transcriptionResult = null;
        _promptResults.clear();
      });
    }

    final splitProvider = context.read<SplitTranscriptionProvider>();
    final apiKey = settingsProvider.apiKey!;
    final language = settingsProvider.language;

    try {
      splitProvider.setApiKey(apiKey);

      setState(() {
        _isSplitTranscription = true;
        _isTranscribing = true;
      });

      final job = await splitProvider.startTranscription(
        audioPath: _selectedFile!.path,
        fileName: _selectedFile!.name,
        language: language,
        apiKey: apiKey,
        model: selectedModelId,
      );

      if (mounted) {
        _listenToSplitJobUpdates(job.id);
        setState(() {
          _activeSplitJob = job;
        });
      }
    } catch (e) {
      safeSetState(() {
        _isTranscribing = false;
        _isSplitTranscription = false;
        _activeSplitJob = null;
      });
      if (mounted) {
        SnackBarService().showError(context, 'Fehler: $e');
      }
    }
  }

  void _listenToSplitJobUpdates(String jobId) {
    final splitProvider = context.read<SplitTranscriptionProvider>();
    bool completionHandled = false;

    splitProvider.jobUpdates.listen((job) {
      if (!mounted) return;
      if (job.id != jobId) return;

      setState(() {
        _activeSplitJob = job;
      });

      if (job.isFinished && !completionHandled) {
        completionHandled = true;
        _onSplitTranscriptionComplete(job);
      }
    });
  }

  Future<void> _onSplitTranscriptionComplete(SplitTranscriptionJob job) async {
    setState(() {
      _isTranscribing = false;
      _showTranscriptionSuccess = true;
    });

    if (job.isFullySuccessful || (job.completedCount > 0 && job.failedCount < job.totalSplits)) {
      final mergedText = job.mergedTranscription;

      if (mergedText != null && mergedText.isNotEmpty) {
        final settingsProvider = context.read<SettingsProvider>();
        final speakerExtractor = SpeakerExtractionService();
        final speakers = speakerExtractor.extractSpeakers(mergedText);
        final result = TranscriptionResult(
          text: mergedText,
          language: job.language,
          modelUsed: settingsProvider.selectedModel,
          timestamp: job.completedAt ?? DateTime.now(),
          speakers: speakers,
        );

        setState(() {
          _transcriptionResult = result;
          _activeSplitJob = null;
          _isSplitTranscription = false;
        });

        await _saveToHistory();
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _showTranscriptionSuccess = false;
            });
          }
        });
      }
    } else {
      setState(() {
        _activeSplitJob = null;
        _isSplitTranscription = false;
        _showTranscriptionSuccess = false;
      });
      SnackBarService().showError(context, 'Transkription fehlgeschlagen');
    }
  }

  Future<void> _saveToHistory() async {
    if (_selectedFile == null) return;

    try {
      final history = TranscriptionHistory(
        id: _currentHistoryId,
        audioFileName: _selectedFile!.name,
        transcription: _transcriptionResult,
        promptResults: _promptResults,
        duration: _audioDuration ?? Duration.zero,
        waveform: _recordedAmplitudes.isNotEmpty ? _recordedAmplitudes : null,
        audioPath: _selectedFile!.path,
      );

      final historyProvider = context.read<HistoryProvider>();
      await historyProvider.saveHistory(history);

      setState(() {
        _currentHistoryId = history.id;
      });
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  String _removeFileExtension(String fileName) {
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }

  Future<void> _applyPromptStreaming() async {
    if (_transcriptionResult == null) return;

    final result = await PromptSelectorBottomSheet.show(context);

    if (result != null && mounted) {
      final promptId = result['promptId']!;
      final promptName = result['promptName']!;
      final promptTemplate = result['promptTemplate']!;

      final promptsProvider = context.read<PromptsProvider>();
      await promptsProvider.incrementUsage(promptId);

      _startPromptStreaming(promptName, promptTemplate);
    }
  }

  void _startPromptStreaming(String promptName, String promptTemplate) {
    final settingsProvider = context.read<SettingsProvider>();
    final apiKey = settingsProvider.apiKey;

    if (apiKey == null || apiKey.isEmpty) return;

    setState(() {
      _currentPromptName = promptName;
      _currentPromptTemplate = promptTemplate;
      _promptBuffer.clear();
    });

    try {
      final model = settingsProvider.selectedModel;
      final llmProvider = LLMProviderFactory.createForModel(model);

      final stream = llmProvider.applyPromptStreaming(
        apiKey: apiKey,
        promptName: promptName,
        promptTemplate: promptTemplate,
        transcriptionText: _transcriptionResult!.text,
      );

      setState(() {
        _promptStream = stream.asBroadcastStream();
      });

      _promptStream!.listen(
        (chunk) {
          if (mounted) {
            _promptBuffer.write(chunk);
          }
        },
        onDone: () {
          _onPromptComplete(promptName, promptTemplate);
        },
        onError: (e) {
          SnackBarService().showError(context, 'Fehler: $e');
          setState(() {
            _promptStream = null;
          });
        },
      );
    } catch (e) {
      SnackBarService().showError(context, 'Fehler: $e');
    }
  }

  void _onPromptComplete(String name, String template) async {
    final settingsProvider = context.read<SettingsProvider>();
    final result = PromptResult(
      promptName: name,
      promptTemplate: template,
      transcriptionText: _transcriptionResult!.text,
      llmResponse: _promptBuffer.toString(),
      timestamp: DateTime.now(),
      modelUsed: settingsProvider.selectedModel,
    );

    setState(() {
      _promptResults.add(result);
      _promptStream = null;
      _promptBuffer.clear();
    });

    await _saveToHistory();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Neue Aufnahme';
    if (_selectedFile != null) {
      title = _removeFileExtension(_selectedFile!.name);
    } else if (_currentHistoryId != null) {
      final historyProvider = context.read<HistoryProvider>();
      final history = historyProvider.getHistoryById(_currentHistoryId!);
      if (history != null) {
        title = _removeFileExtension(history.audioFileName);
      }
    }

    if (_showRecorder) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: AudioRecorderWidget(
          onRecordingComplete: _onRecordingComplete,
          onWaveformUpdate: _onWaveformUpdate,
        ),
      );
    }

    final showChatFab = _transcriptionResult != null &&
        _promptStream == null &&
        _currentHistoryId != null;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _selectedFile != null
          ? _buildBodyWithCollapsiblePlayer(context)
          : _buildScrollableContent(context),
      floatingActionButton: showChatFab
          ? FloatingActionButton(
              onPressed: _openChat,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark ? 0.95 : 0.85,
              ),
              foregroundColor: Colors.white,
              child: const Icon(Icons.chat),
            )
          : null,
    );
  }

  Widget _buildBodyWithCollapsiblePlayer(BuildContext context) {
    const collapsedHeight = 64.0;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isPlayerCollapsed
              ? SizedBox(
                  height: collapsedHeight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPlayerCollapsed = false;
                      });
                    },
                    child: MiniAudioPlayerWidget(
                      recordedAmplitudes: _recordedAmplitudes.isNotEmpty
                          ? _recordedAmplitudes
                          : null,
                      position: _audioPosition,
                      duration: _audioTotalDuration,
                      isPlaying: _isAudioPlaying,
                      onPlayPause: _togglePlayPause,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: AudioPlayerWidget(
                    audioService: _audioService,
                    fileName: _selectedFile!.name,
                    filePath: _selectedFile!.path,
                    recordedAmplitudes: _recordedAmplitudes.isNotEmpty
                        ? _recordedAmplitudes
                        : null,
                  ),
                ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final pixels = notification.metrics.pixels;
              if (pixels > 20 && !_isPlayerCollapsed) {
                setState(() {
                  _isPlayerCollapsed = true;
                });
              }
              return false;
            },
            child: _buildScrollableContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isTranscribing) ...[
            if (_isSplitTranscription)
              _activeSplitJob != null
                  ? SplitTranscriptionProgressCard(job: _activeSplitJob!)
                  : Consumer<SplitTranscriptionProvider>(
                      builder: (context, provider, child) {
                        final progress = provider.splitProgress;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppConstants.defaultPadding),
                            child: Column(
                              children: [
                                if (progress != null && progress.totalSplits > 0) ...[
                                  LinearProgressIndicator(
                                    value: progress.progress,
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                  Text(progress.currentStatus ?? 'Audio wird aufgeteilt...'),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${progress.progressPercentage}%',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ] else ...[
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: AppSpacing.m),
                                  const Text('Audio wird vorbereitet...'),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    )
            else
              StreamingTranscriptionCard(
                textStream: _transcriptionStream,
                onStreamComplete: () {},
                onStreamError: (error) {
                  SnackBarService().showError(context, 'Fehler: $error');
                },
                onChunk: (chunk) {},
              ),
          ] else if (_transcriptionResult != null) ...[
            CompletedTranscriptionCard(
              transcriptionResult: _transcriptionResult!,
              isPromptActive: _promptStream != null,
              onApplyPrompt: _applyPromptStreaming,
              promptResultCount: _promptResults.length,
              onRetranscribe: _retranscribe,
            ),
            const SizedBox(height: AppSpacing.m),
            PromptResultsList(
              results: List.from(_promptResults)
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
              onDelete: (id) {
                setState(() {
                  _promptResults.removeWhere((r) => r.id == id);
                });
                _saveToHistory();
              },
            ),
            if (_promptStream != null)
              StreamingPromptCard(
                promptName: _currentPromptName ?? '',
                textStream: _promptStream,
                onStreamComplete: () {},
                onStreamError: (error) {
                  SnackBarService().showError(context, 'Fehler: $error');
                },
                onChunk: (chunk) {},
              ),
          ] else ...[
            Center(
              child: TranscriptionButton(
                onPressed: _transcribe,
                isTranscribing: _isTranscribing,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
