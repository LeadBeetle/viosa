import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/audio_config.dart';
import '../utils/audio_formats.dart';
import '../utils/path_utils.dart';
import 'i_audio_transcoder_service.dart';
import 'transcription_exceptions.dart';

/// Wandelt Importe über die Mediendecoder des Geräts in WAV um
///
/// Der Transkriptionsanbieter lehnt den MP4/AAC-Container ab, deshalb wird
/// alles außer WAV vor dem Upload einmal dekodiert. Das Ergebnis liegt im
/// Cache und wird bei einem zweiten Anlauf wiederverwendet
class AudioTranscoderService implements IAudioTranscoderService {
  static const MethodChannel _channel =
      MethodChannel('ai.viosa.app/audio_transcode');

  static const String _cacheDirectoryName = 'transcoded_audio';

  final MethodChannel _methodChannel;

  AudioTranscoderService({MethodChannel? channel})
      : _methodChannel = channel ?? _channel;

  @override
  bool needsTranscoding(String audioPath) {
    if (!Platform.isAndroid) return false;
    return AudioFormats.apiFormatForPath(audioPath) != 'wav';
  }

  @override
  Future<String> toWav(String audioPath) async {
    if (!needsTranscoding(audioPath)) return audioPath;

    final source = File(audioPath);
    if (!await source.exists()) throw AudioFileMissingException(audioPath);

    final target = await _targetFileFor(source);
    if (await target.exists() && await target.length() > 0) {
      debugPrint('Transcode: reusing ${target.path}');
      return target.path;
    }

    try {
      final path = await _methodChannel.invokeMethod<String>('toWav', {
        'sourcePath': audioPath,
        'targetPath': target.path,
        'sampleRate': AudioConfig.sampleRate,
      });

      if (path == null) throw const AudioTranscodeException('Kein Zielpfad');

      debugPrint('Transcode: $audioPath -> $path');
      return path;
    } on PlatformException catch (e) {
      throw AudioTranscodeException(e.message ?? e.code);
    }
  }

  /// Benennt die Zieldatei nach Name, Größe und Änderungszeitpunkt der Quelle,
  /// damit eine geänderte Datei nicht auf einen alten Cache-Eintrag trifft
  Future<File> _targetFileFor(File source) async {
    final statistics = await source.stat();
    final name = PathUtils.sanitizeFileName(PathUtils.fileNameOf(source.path));
    final fingerprint = '${name}_${statistics.size}_'
        '${statistics.modified.millisecondsSinceEpoch}';

    final cacheDirectory = Directory(
      '${(await getTemporaryDirectory()).path}/$_cacheDirectoryName',
    );
    await cacheDirectory.create(recursive: true);

    return File('${cacheDirectory.path}/$fingerprint.wav');
  }
}
