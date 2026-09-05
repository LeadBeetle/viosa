import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/split_transcription_job.dart';
import '../models/transcription_result.dart';
import '../services/i_audio_splitter_service.dart';
import '../services/split_transcription_service.dart';

/// Provider for managing split transcription jobs state
class SplitTranscriptionProvider extends ChangeNotifier {
  final SplitTranscriptionService _service;
  final StreamController<SplitTranscriptionJob> _jobUpdateController;

  SplitTranscriptionJob? _currentJob;
  String? _activeHistoryId;
  String? _activeFileName;
  String Function(int segmentNumber, String timeRange)? _failedSegmentLabel;
  Future<void> Function(String historyId, TranscriptionResult result)? _onResult;
  Object? _lastError;
  String? _apiKey;
  String? _model;
  bool _speakerDiarization = false;
  List<String> _keywords = const [];
  String? _transcribeStyle;
  SplitProgress? _splitProgress;

  SplitTranscriptionProvider({
    SplitTranscriptionService? service,
  })  : _service = service ?? SplitTranscriptionService(),
        _jobUpdateController = StreamController<SplitTranscriptionJob>.broadcast();

  SplitTranscriptionJob? get currentJob => _currentJob;
  SplitProgress? get splitProgress => _splitProgress;
  bool get isSplitting => _splitProgress != null && (_currentJob == null || _currentJob!.status == JobStatus.queued);

  Stream<SplitTranscriptionJob> get jobUpdates => _jobUpdateController.stream;

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

  /// Creates and starts a new split transcription job
  Future<SplitTranscriptionJob> startTranscription({
    required String audioPath,
    required String fileName,
    required String language,
    required String apiKey,
    required String historyId,
    String? model,
    bool speakerDiarization = false,
    List<String> keywords = const [],
    String? transcribeStyle,
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
    _speakerDiarization = speakerDiarization;
    _keywords = keywords;
    _transcribeStyle = transcribeStyle;
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
    if (_apiKey == null) {
      throw Exception('API key not set');
    }

    try {
      await _service.processJob(
        job,
        _apiKey!,
        model: _model,
        speakerDiarization: _speakerDiarization,
        keywords: _keywords,
        transcribeStyle: _transcribeStyle,
        onProgress: (updatedJob) {
          _currentJob = updatedJob;
          _jobUpdateController.add(updatedJob);
          notifyListeners();
        },
      );

      await _persistResult(job);
    } catch (e) {
      _lastError = e;
      _jobUpdateController.add(job);
      notifyListeners();
    }
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

    if (result != null && historyId != null && onResult != null) {
      try {
        await onResult(historyId, result);
      } catch (e) {
        _lastError = e;
      }
    }

    if (!job.hasFailures) {
      await cleanupJob(job);
    }

    _jobUpdateController.add(job);
    notifyListeners();
  }

  Future<void> retryFailedSplit(String jobId, String splitId) async {
    if (_apiKey == null) {
      throw Exception('API key not set');
    }

    if (_currentJob == null || _currentJob!.id != jobId) {
      throw Exception('Job not found');
    }

    await _service.retryFailedSplit(
      _currentJob!,
      splitId,
      _apiKey!,
      speakerDiarization: _speakerDiarization,
      keywords: _keywords,
      transcribeStyle: _transcribeStyle,
      onProgress: (updatedJob) {
        _currentJob = updatedJob;
        _jobUpdateController.add(updatedJob);
        notifyListeners();
      },
    );
  }

  /// Builds the transcription result of a finished job
  TranscriptionResult? buildTranscriptionResult(
    SplitTranscriptionJob job, {
    String Function(int segmentNumber, String timeRange)? failedSegmentLabel,
  }) {
    return _service.buildTranscriptionResult(
      job,
      failedSegmentLabel: failedSegmentLabel,
    );
  }

  /// Retries every split that failed in [jobId]
  Future<void> retryAllFailedSplits(String jobId) async {
    final job = _currentJob;
    if (job == null || job.id != jobId) {
      throw Exception('Job not found');
    }

    for (final split in job.failedSplits) {
      await retryFailedSplit(jobId, split.id);
    }
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
    super.dispose();
  }
}
