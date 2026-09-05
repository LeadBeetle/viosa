import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/split_transcription_job.dart';
import '../models/transcription_options.dart';
import '../models/transcription_result.dart';
import '../services/i_audio_splitter_service.dart';
import '../services/split_transcription_exceptions.dart';
import '../services/split_transcription_service.dart';

/// Outcome of a finished job, delivered once the transcript is persisted so
/// listeners never have to read a half written history entry
class SplitTranscriptionOutcome {
  final SplitTranscriptionJob job;

  /// Merged transcript, null when no split produced any text
  final TranscriptionResult? result;

  /// Error that ended the job, null when it ran through
  final Object? error;

  const SplitTranscriptionOutcome({
    required this.job,
    this.result,
    this.error,
  });
}

/// Provider for managing split transcription jobs state
class SplitTranscriptionProvider extends ChangeNotifier {
  final SplitTranscriptionService _service;
  final StreamController<SplitTranscriptionJob> _jobUpdateController;
  final StreamController<SplitTranscriptionOutcome> _outcomeController;

  SplitTranscriptionJob? _currentJob;
  String? _activeHistoryId;
  String? _activeFileName;
  String Function(int segmentNumber, String timeRange)? _failedSegmentLabel;
  Future<void> Function(String historyId, TranscriptionResult result)? _onResult;
  Object? _lastError;
  String? _apiKey;
  String? _model;
  TranscriptionOptions? _options;
  SplitProgress? _splitProgress;
  String? _pendingAutoPromptHistoryId;

  SplitTranscriptionProvider({
    SplitTranscriptionService? service,
  })  : _service = service ?? SplitTranscriptionService(),
        _jobUpdateController = StreamController<SplitTranscriptionJob>.broadcast(),
        _outcomeController =
            StreamController<SplitTranscriptionOutcome>.broadcast();

  SplitTranscriptionJob? get currentJob => _currentJob;
  SplitProgress? get splitProgress => _splitProgress;
  bool get isSplitting => _splitProgress != null && (_currentJob == null || _currentJob!.status == JobStatus.queued);

  /// Progress updates of the running job; a finished job is announced through
  /// [jobOutcomes] instead, so its transcript is stored before anyone reads it
  Stream<SplitTranscriptionJob> get jobUpdates => _jobUpdateController.stream;

  /// Emits once a job stopped, after its transcript has been persisted
  Stream<SplitTranscriptionOutcome> get jobOutcomes => _outcomeController.stream;

  /// Id of the history entry the running job belongs to
  String? get activeHistoryId => _activeHistoryId;

  /// Name of the file the running job transcribes
  String? get activeFileName => _activeFileName;

  /// Last error of a job that could not be processed
  Object? get lastError => _lastError;

  /// Returns true while a job is still being processed
  bool get isRunning {
    final job = _currentJob;
    if (job == null) return _splitProgress != null;
    return job.status == JobStatus.queued || job.status == JobStatus.processing;
  }

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Takes the pending auto prompt of [historyId] if a transcription of that
  /// entry finished without one having run yet
  /// Lets a session screen that was closed while the job ran still start the
  /// prompt the user selected
  bool consumePendingAutoPrompt(String historyId) {
    if (_pendingAutoPromptHistoryId != historyId) return false;
    _pendingAutoPromptHistoryId = null;
    return true;
  }

  /// Creates and starts a new split transcription job
  Future<SplitTranscriptionJob> startTranscription({
    required String audioPath,
    required String fileName,
    required String language,
    required String apiKey,
    required String historyId,
    required TranscriptionOptions options,
    String? model,
    String Function(int segmentNumber, String timeRange)? failedSegmentLabel,
    Future<void> Function(String historyId, TranscriptionResult result)? onResult,
    Duration maxDuration = const Duration(minutes: 10),
    Duration overlap = const Duration(seconds: 5),
  }) async {
    _apiKey = apiKey;
    _activeHistoryId = historyId;
    _activeFileName = fileName;
    _failedSegmentLabel = failedSegmentLabel;
    _onResult = onResult;
    _lastError = null;
    _model = model;
    _options = options;
    _pendingAutoPromptHistoryId = null;
    _splitProgress = const SplitProgress(currentSplit: 0, totalSplits: 0);
    notifyListeners();

    final job = await _service.createJob(
      audioPath: audioPath,
      fileName: fileName,
      language: language,
      maxDuration: maxDuration,
      overlap: overlap,
      onSplitProgress: (progress) {
        _splitProgress = progress;
        notifyListeners();
      },
    );

    _splitProgress = null;
    _currentJob = job;
    notifyListeners();
    _jobUpdateController.add(job);

    _processJobInBackground(job);

    return job;
  }

  Future<void> _processJobInBackground(SplitTranscriptionJob job) async {
    final apiKey = _apiKey;
    final options = _options;

    if (apiKey == null || options == null) {
      _failJob(job, const MissingApiKeyException());
      return;
    }

    try {
      await _service.processJob(
        job,
        apiKey,
        options: options,
        model: _model,
        onProgress: _publishProgress,
      );
    } catch (e) {
      _failJob(job, e);
      return;
    }

    await _persistResult(job);
  }

  /// Forwards a progress update but holds back the finished job, so listeners
  /// only see it once [_persistResult] has stored the transcript
  void _publishProgress(SplitTranscriptionJob job) {
    _currentJob = job;
    if (!job.isFinished) {
      _jobUpdateController.add(job);
    }
    notifyListeners();
  }

  /// Ends a job that could not be processed, so no banner keeps spinning and
  /// the error reaches the screens instead of being swallowed
  void _failJob(SplitTranscriptionJob job, Object error) {
    _lastError = error;
    job.status = JobStatus.failed;
    job.lastUpdatedAt = DateTime.now();
    _currentJob = job;
    notifyListeners();
    _outcomeController.add(SplitTranscriptionOutcome(job: job, error: error));
  }

  /// Saves the result of a finished job, independent of any open screen, so a
  /// transcription survives when the user leaves the session
  Future<void> _persistResult(SplitTranscriptionJob job) async {
    if (job.status == JobStatus.cancelled) return;

    final result = _service.buildTranscriptionResult(
      job,
      failedSegmentLabel: _failedSegmentLabel,
    );
    final historyId = _activeHistoryId;
    final onResult = _onResult;
    Object? error;

    if (result != null && historyId != null && onResult != null) {
      try {
        await onResult(historyId, result);
        if (!job.hasFailures) {
          _pendingAutoPromptHistoryId = historyId;
        }
      } catch (e) {
        error = e;
        _lastError = e;
      }
    }

    if (!job.hasFailures) {
      await cleanupJob(job);
    }

    notifyListeners();
    _outcomeController.add(
      SplitTranscriptionOutcome(
        job: job,
        result: error == null ? result : null,
        error: error,
      ),
    );
  }

  Future<void> retryFailedSplit(String jobId, String splitId) async {
    final apiKey = _apiKey;
    final options = _options;

    if (apiKey == null || options == null) {
      throw const MissingApiKeyException();
    }

    final job = _currentJob;
    if (job == null || job.id != jobId) {
      throw JobNotFoundException(jobId);
    }

    await _service.retryFailedSplit(
      job,
      splitId,
      apiKey,
      options: options,
      onProgress: _publishProgress,
    );
  }

  /// Retries every split that failed in [jobId] and stores the repaired
  /// transcript, so a partial failure is not left broken in the history
  Future<void> retryAllFailedSplits(String jobId) async {
    final job = _currentJob;
    if (job == null || job.id != jobId) {
      throw JobNotFoundException(jobId);
    }

    for (final split in List.of(job.failedSplits)) {
      await retryFailedSplit(jobId, split.id);
    }

    await _persistResult(job);
  }

  Future<void> cancelJob(String jobId) async {
    if (_currentJob != null && _currentJob!.id == jobId) {
      _service.cancelJob(_currentJob!);
      _jobUpdateController.add(_currentJob!);
      notifyListeners();
    }
  }

  void clearCurrentJob() {
    _currentJob = null;
    notifyListeners();
  }

  Future<void> cleanupJob(SplitTranscriptionJob job) async {
    await _service.cleanupSplits(job);
    if (_currentJob?.id == job.id) {
      _currentJob = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _jobUpdateController.close();
    _outcomeController.close();
    super.dispose();
  }
}
