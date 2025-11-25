import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/audio_split.dart';
import '../models/split_transcription_job.dart';
import '../models/transcription_result.dart';
import '../models/transcription_history.dart';
import '../repositories/model_repository.dart';
import 'audio_splitter_service.dart';
import 'i_audio_splitter_service.dart';
import 'llm_provider.dart';
import 'llm_provider_factory.dart';
import 'speaker_context_service.dart';
import 'speaker_extraction_service.dart';
import 'completion/openrouter_completion_service.dart';

/// Service for managing split transcription jobs
class SplitTranscriptionService {
  final AudioSplitterService _splitterService;
  final Map<String, SplitTranscriptionJob> _jobs = {};
  String _currentModel = ModelRepository.defaultModelId;
  ILLMProvider? _provider;
  ISpeakerContextService? _speakerContextService;

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  SplitTranscriptionService({
    AudioSplitterService? splitterService,
  })  : _splitterService = splitterService ?? AudioSplitterService();

  ILLMProvider _getProvider() {
    _provider ??= LLMProviderFactory.createForModel(_currentModel);
    return _provider!;
  }

  ISpeakerContextService _getSpeakerContextService() {
    _speakerContextService ??= SpeakerContextService(
      completionService: OpenRouterCompletionService(model: _currentModel),
    );
    return _speakerContextService!;
  }

  /// Creates a new split transcription job
  Future<SplitTranscriptionJob> createJob({
    required String audioPath,
    required String fileName,
    required String language,
    Duration maxDuration = const Duration(minutes: 10),
    Duration overlap = const Duration(seconds: 5),
    void Function(SplitProgress progress)? onSplitProgress,
  }) async {
    final splits = await _splitterService.splitAudio(
      audioPath,
      maxDuration: maxDuration,
      overlap: overlap,
      onProgress: onSplitProgress,
    );

    final job = SplitTranscriptionJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalAudioPath: audioPath,
      originalFileName: fileName,
      totalSplits: splits.length,
      splits: splits,
      language: language,
      createdAt: DateTime.now(),
      status: JobStatus.queued,
    );

    _jobs[job.id] = job;
    return job;
  }

  /// Processes a split transcription job with progress callback
  Future<void> processJob(
    SplitTranscriptionJob job,
    String apiKey, {
    String? model,
    void Function(SplitTranscriptionJob)? onProgress,
  }) async {
    if (model != null) {
      _currentModel = model;
      _provider = LLMProviderFactory.createForModel(_currentModel);
      _speakerContextService = null;
    }
    job.status = JobStatus.processing;
    job.lastUpdatedAt = DateTime.now();
    onProgress?.call(job);

    TranscriptionContext? currentContext;

    for (final split in job.splits) {
      if (job.status == JobStatus.cancelled) {
        break;
      }

      if (split.status == SplitStatus.completed) {
        continue;
      }

      await _transcribeSplitWithRetry(
        job,
        split,
        apiKey,
        speakerContext: currentContext,
        onProgress: onProgress,
      );

      if (split.status == SplitStatus.completed) {
        job.completedCount++;

        if (split.transcriptionText != null && split.transcriptionText!.isNotEmpty) {
          currentContext = await _extractContextSafely(
            apiKey,
            split.transcriptionText!,
            job.language,
            currentContext,
          );
        }
      } else if (split.status == SplitStatus.failed) {
        job.failedCount++;
      }

      job.lastUpdatedAt = DateTime.now();
      onProgress?.call(job);
    }

    if (job.status != JobStatus.cancelled) {
      if (job.failedCount > 0) {
        job.status = JobStatus.partialFailure;
      } else {
        job.status = JobStatus.completed;
      }
      job.completedAt = DateTime.now();
      onProgress?.call(job);
    }
  }

  Future<TranscriptionContext?> _extractContextSafely(
    String apiKey,
    String transcription,
    String language,
    TranscriptionContext? existingContext,
  ) async {
    try {
      final newContext = await _getSpeakerContextService().extractContext(
        apiKey: apiKey,
        transcription: transcription,
        language: language,
      );

      if (newContext.isEmpty) {
        return existingContext;
      }

      if (existingContext == null || existingContext.isEmpty) {
        return newContext;
      }

      return _mergeContexts(existingContext, newContext);
    } catch (e) {
      debugPrint('Failed to extract speaker context: $e');
      return existingContext;
    }
  }

  TranscriptionContext _mergeContexts(
    TranscriptionContext existing,
    TranscriptionContext newContext,
  ) {
    final mergedSpeakers = <String, SpeakerContext>{};

    for (final speaker in existing.speakers) {
      mergedSpeakers[speaker.label] = speaker;
    }

    for (final speaker in newContext.speakers) {
      if (mergedSpeakers.containsKey(speaker.label)) {
        final existingSummary = mergedSpeakers[speaker.label]!.summary;
        mergedSpeakers[speaker.label] = SpeakerContext(
          label: speaker.label,
          summary: '$existingSummary ${speaker.summary}',
        );
      } else {
        mergedSpeakers[speaker.label] = speaker;
      }
    }

    return TranscriptionContext(speakers: mergedSpeakers.values.toList());
  }

  /// Transcribes a single split with retry logic
  Future<void> _transcribeSplitWithRetry(
    SplitTranscriptionJob job,
    AudioSplit split,
    String apiKey, {
    TranscriptionContext? speakerContext,
    void Function(SplitTranscriptionJob)? onProgress,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        split.status = SplitStatus.processing;
        split.attemptCount = attempt;
        split.errorMessage = null;
        onProgress?.call(job);

        final audioFile = File(split.filePath);
        final audioBytes = await audioFile.readAsBytes();
        final base64Audio = base64Encode(audioBytes);

        final result = await _getProvider().transcribeAudio(
          apiKey: apiKey,
          base64Audio: base64Audio,
          mimeType: split.mimeType,
          language: job.language,
          speakerContext: speakerContext,
        );

        split.transcriptionText = result.text;
        split.status = SplitStatus.completed;
        split.completedAt = DateTime.now();
        onProgress?.call(job);

        return;
      } catch (e) {
        split.errorMessage = e.toString();

        if (attempt == maxRetries) {
          split.status = SplitStatus.failed;
          onProgress?.call(job);
          return;
        }

        final delay = Duration(seconds: retryDelay.inSeconds * attempt);
        await Future.delayed(delay);
      }
    }
  }

  /// Retries a failed split
  Future<void> retryFailedSplit(
    SplitTranscriptionJob job,
    String splitId,
    String apiKey, {
    void Function(SplitTranscriptionJob)? onProgress,
  }) async {
    final split = job.splits.firstWhere(
      (s) => s.id == splitId,
      orElse: () => throw Exception('Split not found: $splitId'),
    );

    if (split.status != SplitStatus.failed) {
      throw Exception('Split is not in failed state');
    }

    split.status = SplitStatus.pending;
    split.attemptCount = 0;
    split.errorMessage = null;

    if (job.status == JobStatus.partialFailure) {
      job.failedCount--;
    }

    final speakerContext = await _buildContextFromPreviousSplits(job, split.index, apiKey);

    await _transcribeSplitWithRetry(
      job,
      split,
      apiKey,
      speakerContext: speakerContext,
      onProgress: onProgress,
    );

    if (split.status == SplitStatus.completed) {
      job.completedCount++;

      if (job.completedCount == job.totalSplits) {
        job.status = JobStatus.completed;
        job.completedAt = DateTime.now();
      }
    } else if (split.status == SplitStatus.failed) {
      job.failedCount++;
    }

    job.lastUpdatedAt = DateTime.now();
    onProgress?.call(job);
  }

  Future<TranscriptionContext?> _buildContextFromPreviousSplits(
    SplitTranscriptionJob job,
    int currentIndex,
    String apiKey,
  ) async {
    TranscriptionContext? context;

    final previousSplits = job.splits
        .where((s) => s.index < currentIndex && s.status == SplitStatus.completed)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    for (final split in previousSplits) {
      if (split.transcriptionText != null && split.transcriptionText!.isNotEmpty) {
        context = await _extractContextSafely(
          apiKey,
          split.transcriptionText!,
          job.language,
          context,
        );
      }
    }

    return context;
  }

  /// Cancels a job
  void cancelJob(SplitTranscriptionJob job) {
    job.status = JobStatus.cancelled;
    job.lastUpdatedAt = DateTime.now();
  }

  /// Gets a job by ID
  SplitTranscriptionJob? getJob(String jobId) {
    return _jobs[jobId];
  }

  /// Creates a TranscriptionHistory entry from a completed job
  TranscriptionHistory? createHistoryFromJob(SplitTranscriptionJob job) {
    if (job.status != JobStatus.completed &&
        job.status != JobStatus.partialFailure) {
      return null;
    }

    final mergedText = job.mergedTranscription;
    if (mergedText == null || mergedText.isEmpty) {
      return null;
    }

    final speakerExtractor = SpeakerExtractionService();
    final speakers = speakerExtractor.extractSpeakers(mergedText);

    return TranscriptionHistory(
      audioFileName: job.originalFileName,
      transcription: TranscriptionResult(
        text: mergedText,
        language: job.language,
        modelUsed: _currentModel,
        timestamp: job.completedAt ?? DateTime.now(),
        speakers: speakers,
      ),
      createdAt: job.createdAt,
      splitJobId: job.id,
      isSplitTranscription: true,
    );
  }

  /// Cleans up split files
  Future<void> cleanupSplits(SplitTranscriptionJob job) async {
    await _splitterService.cleanupSplits(job.splits);
    _jobs.remove(job.id);
  }
}
