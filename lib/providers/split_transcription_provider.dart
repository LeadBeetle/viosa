import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/split_transcription_job.dart';
import '../services/i_audio_splitter_service.dart';
import '../services/split_transcription_service.dart';

/// Provider for managing split transcription jobs state
class SplitTranscriptionProvider extends ChangeNotifier {
  final SplitTranscriptionService _service;
  final StreamController<SplitTranscriptionJob> _jobUpdateController;

  SplitTranscriptionJob? _currentJob;
  String? _apiKey;
  String? _model;
  bool _speakerDiarization = false;
  SplitProgress? _splitProgress;

  SplitTranscriptionProvider({
    SplitTranscriptionService? service,
  })  : _service = service ?? SplitTranscriptionService(),
        _jobUpdateController = StreamController<SplitTranscriptionJob>.broadcast();

  SplitTranscriptionJob? get currentJob => _currentJob;
  SplitProgress? get splitProgress => _splitProgress;
  bool get isSplitting => _splitProgress != null && (_currentJob == null || _currentJob!.status == JobStatus.queued);

  Stream<SplitTranscriptionJob> get jobUpdates => _jobUpdateController.stream;

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Creates and starts a new split transcription job
  Future<SplitTranscriptionJob> startTranscription({
    required String audioPath,
    required String fileName,
    required String language,
    required String apiKey,
    String? model,
    bool speakerDiarization = false,
    Duration maxDuration = const Duration(minutes: 10),
    Duration overlap = const Duration(seconds: 5),
  }) async {
    _apiKey = apiKey;
    _model = model;
    _speakerDiarization = speakerDiarization;
    _splitProgress = const SplitProgress(currentSplit: 0, totalSplits: 0, currentStatus: 'Vorbereiten...');
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
        onProgress: (updatedJob) {
          _currentJob = updatedJob;
          _jobUpdateController.add(updatedJob);
          notifyListeners();
        },
      );
    } catch (e) {
      _jobUpdateController.add(job);
      notifyListeners();
    }
  }

  Stream<SplitTranscriptionJob> watchJob(String jobId) async* {
    if (_currentJob != null && _currentJob!.id == jobId) {
      yield _currentJob!;
    }

    await for (final update in _jobUpdateController.stream) {
      if (update.id == jobId) {
        yield update;
      }
    }
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
      onProgress: (updatedJob) {
        _currentJob = updatedJob;
        _jobUpdateController.add(updatedJob);
        notifyListeners();
      },
    );
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
