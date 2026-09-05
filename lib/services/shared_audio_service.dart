import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'i_shared_audio_service.dart';

/// Empfängt Audiodateien, die andere Apps per "Teilen" oder "Öffnen mit"
/// an VIOSA übergeben.
class SharedAudioService implements ISharedAudioService {
  static const MethodChannel _channel = MethodChannel('ai.viosa.app/shared_audio');

  final StreamController<String> _sharedFilesController =
      StreamController<String>.broadcast();

  SharedAudioService() {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  @override
  Future<String?> consumeInitialSharedFile() async {
    if (!Platform.isAndroid) return null;
    return _channel.invokeMethod<String>('getSharedAudioFile');
  }

  @override
  Stream<String> get sharedFiles => _sharedFilesController.stream;

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onSharedAudioFile') return;

    final path = call.arguments as String?;
    if (path != null && path.isNotEmpty) {
      _sharedFilesController.add(path);
    }
  }

  /// Schließt den Stream.
  @override
  void dispose() {
    _sharedFilesController.close();
  }
}
