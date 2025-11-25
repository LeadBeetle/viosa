import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'i_speech_recognition_service.dart';

/// Implementation of speech recognition using the speech_to_text package
/// Provides push-to-talk functionality with interim results
class SpeechRecognitionService implements ISpeechRecognitionService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  void Function(String)? _onResult;
  void Function(String)? _onPartialResult;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  @override
  Future<bool> get isAvailable async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  @override
  bool get isListening => _isListening;

  @override
  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function(String text) onPartialResult,
    String locale = 'de-DE',
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        throw Exception('Speech recognition not available');
      }
    }

    if (_isListening) {
      await stopListening();
    }

    _onResult = onResult;
    _onPartialResult = onPartialResult;
    _isListening = true;

    await _speechToText.listen(
      onResult: _handleResult,
      localeId: locale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;

    if (result.finalResult) {
      _onResult?.call(text);
      _isListening = false;
    } else {
      _onPartialResult?.call(text);
    }
  }

  @override
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  @override
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
    }
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _onResult = null;
    _onPartialResult = null;
  }
}
