import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transcription_options.dart';
import '../models/transcription_result.dart';
import '../services/i_transcription_job_service.dart';
import '../services/transcription_exceptions.dart';
import '../services/transcription_job_service.dart';

/// Outcome of a finished transcription, delivered once the transcript is
/// persisted so listeners never have to read a half written history entry
class TranscriptionJobOutcome {
  /// Id of the job this outcome belongs to
  final String jobId;

  /// Transcript, null when the job produced no text
  final TranscriptionResult? result;

  /// Error that ended the job, null when it ran through
  final Object? error;

  const TranscriptionJobOutcome({
    required this.jobId,
    this.result,
    this.error,
  });
}

/// Holds the transcription that runs in the background, independent of any
/// open screen
class TranscriptionJobProvider extends ChangeNotifier {
  final ITranscriptionJobService _service;
  final StreamController<TranscriptionJobOutcome> _outcomeController;

  String? _activeJobId;
  String? _activeHistoryId;
  String? _activeFileName;
  Object? _lastError;
  String? _pendingAutoPromptHistoryId;
  bool _isRunning = false;

  TranscriptionJobProvider({ITranscriptionJobService? service})
      : _service = service ?? TranscriptionJobService(),
        _outcomeController =
            StreamController<TranscriptionJobOutcome>.broadcast();

  /// Emits once a transcription stopped, after its transcript was persisted
  Stream<TranscriptionJobOutcome> get jobOutcomes => _outcomeController.stream;

  /// Id of the running transcription
  String? get activeJobId => _activeJobId;

  /// Id of the history entry the running transcription belongs to
  String? get activeHistoryId => _activeHistoryId;

  /// Name of the file the running transcription processes
  String? get activeFileName => _activeFileName;

  /// Last error of a transcription that could not be processed
  Object? get lastError => _lastError;

  /// Returns true while a transcription is still running
  bool get isRunning => _isRunning;

  /// Takes the pending auto prompt of [historyId] if a transcription of that
  /// entry finished without one having run yet
  /// Lets a session screen that was closed while the job ran still start the
  /// prompt the user selected
  bool consumePendingAutoPrompt(String historyId) {
    if (_pendingAutoPromptHistoryId != historyId) return false;
    _pendingAutoPromptHistoryId = null;
    return true;
  }

  /// Starts transcribing [audioPath] in the background and returns the job id
  String startTranscription({
    required String audioPath,
    required String fileName,
    required String language,
    required String apiKey,
    required String historyId,
    required TranscriptionOptions options,
    String? model,
    Future<void> Function(String historyId, TranscriptionResult result)?
        onResult,
  }) {
    final jobId = DateTime.now().millisecondsSinceEpoch.toString();

    _activeJobId = jobId;
    _activeHistoryId = historyId;
    _activeFileName = fileName;
    _lastError = null;
    _pendingAutoPromptHistoryId = null;
    _isRunning = true;
    notifyListeners();

    unawaited(_run(
      jobId: jobId,
      audioPath: audioPath,
      language: language,
      apiKey: apiKey,
      historyId: historyId,
      options: options,
      model: model,
      onResult: onResult,
    ));

    return jobId;
  }

  Future<void> _run({
    required String jobId,
    required String audioPath,
    required String language,
    required String apiKey,
    required String historyId,
    required TranscriptionOptions options,
    String? model,
    Future<void> Function(String historyId, TranscriptionResult result)?
        onResult,
  }) async {
    if (apiKey.isEmpty) {
      _finish(jobId, error: const MissingApiKeyException());
      return;
    }

    TranscriptionResult result;

    try {
      result = await _service.transcribeFile(
        audioPath: audioPath,
        apiKey: apiKey,
        language: language,
        options: options,
        model: model,
      );
    } catch (e) {
      _finish(jobId, error: e);
      return;
    }

    if (_activeJobId != jobId) return;

    try {
      await onResult?.call(historyId, result);
    } catch (e) {
      _finish(jobId, error: e);
      return;
    }

    if (_activeJobId != jobId) return;

    _pendingAutoPromptHistoryId = historyId;
    _finish(jobId, result: result);
  }

  /// Ends a transcription, so no banner keeps spinning and the error reaches
  /// the screens instead of being swallowed
  void _finish(String jobId, {TranscriptionResult? result, Object? error}) {
    if (_activeJobId != jobId) return;

    _lastError = error;
    _isRunning = false;
    notifyListeners();

    _outcomeController.add(
      TranscriptionJobOutcome(jobId: jobId, result: result, error: error),
    );
  }

  /// Drops the running transcription, its result is discarded when it arrives
  void cancel() {
    if (!_isRunning) return;

    _activeJobId = null;
    _activeHistoryId = null;
    _activeFileName = null;
    _isRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _outcomeController.close();
    super.dispose();
  }
}
