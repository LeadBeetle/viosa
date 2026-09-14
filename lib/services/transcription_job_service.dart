import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/transcription_options.dart';
import '../models/transcription_result.dart';
import '../repositories/model_repository.dart';
import 'audio_transcoder_service.dart';
import 'completion/openrouter_completion_service.dart';
import 'i_audio_transcoder_service.dart';
import 'i_transcription_job_service.dart';
import 'transcription_exceptions.dart';
import 'transcription_service.dart';

/// Transcribes a whole audio file in a single request
/// MAI-Transcribe 2 accepts the complete recording, so the audio reaches the
/// model unsplit and no segments have to be stitched back together
class TranscriptionJobService implements ITranscriptionJobService {
  final ITranscriptionService? _transcriptionService;
  final IAudioTranscoderService _transcoderService;

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  TranscriptionJobService({
    ITranscriptionService? transcriptionService,
    IAudioTranscoderService? transcoderService,
  })  : _transcriptionService = transcriptionService,
        _transcoderService = transcoderService ?? AudioTranscoderService();

  ITranscriptionService _serviceFor(String? model) {
    return _transcriptionService ??
        TranscriptionService(
          completionService: OpenRouterCompletionService(
            model: model ?? ModelRepository.defaultModelId,
          ),
        );
  }

  @override
  Future<TranscriptionResult> transcribeFile({
    required String audioPath,
    required String apiKey,
    required String language,
    required TranscriptionOptions options,
    String? model,
  }) async {
    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      throw AudioFileMissingException(audioPath);
    }

    final uploadPath = await _transcoderService.toWav(audioPath);
    final base64Audio = base64Encode(await File(uploadPath).readAsBytes());
    final service = _serviceFor(model);

    Object lastError = const TranscriptionPipelineException(
      'Transcription failed',
    );

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await service.transcribe(
          apiKey: apiKey,
          base64Audio: base64Audio,
          audioPath: uploadPath,
          language: language,
          options: options,
        );
      } catch (e) {
        lastError = e;
        debugPrint('Transcription attempt $attempt/$maxRetries failed: $e');

        if (attempt == maxRetries) break;

        await Future.delayed(
          Duration(seconds: retryDelay.inSeconds * attempt),
        );
      }
    }

    throw lastError;
  }
}
