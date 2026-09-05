import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:viosa/utils/audio_formats.dart';
import 'package:viosa/utils/file_size_formatter.dart';
import 'package:viosa/utils/path_utils.dart';

void main() {
  group('AudioFormats', () {
    test('extrahiert die Erweiterung unabhängig vom Trennzeichen', () {
      expect(AudioFormats.extensionOf('/storage/Music/song.MP3'), 'mp3');
      expect(AudioFormats.extensionOf(r'C:\Musik\aufnahme.m4a'), 'm4a');
      expect(AudioFormats.extensionOf('ohne_endung'), '');
      expect(AudioFormats.extensionOf('.versteckt'), '');
      expect(AudioFormats.extensionOf('name.'), '');
    });

    test('erkennt unterstützte Formate', () {
      expect(AudioFormats.isSupportedPath('/tmp/a.flac'), isTrue);
      expect(AudioFormats.isSupportedPath('/tmp/a.txt'), isFalse);
    });

    test('liefert den für OpenRouter erwarteten MIME-Typ', () {
      expect(AudioFormats.mimeTypeForPath('a.m4a'), 'audio/mpeg');
      expect(AudioFormats.mimeTypeForPath('a.mp4'), 'audio/mpeg');
      expect(AudioFormats.mimeTypeForPath('a.wav'), 'audio/wav');
      expect(AudioFormats.mimeTypeForPath('a.unbekannt'), 'audio/mpeg');
    });

    test('meldet der Transkriptions-API den echten Container', () {
      expect(AudioFormats.apiFormatForPath('recording_1.m4a'), 'm4a');
      expect(AudioFormats.apiFormatForPath('clip.MP4'), 'm4a');
      expect(AudioFormats.apiFormatForPath('a.wav'), 'wav');
      expect(AudioFormats.apiFormatForPath('a.mpga'), 'mp3');
      expect(AudioFormats.apiFormatForPath('a.oga'), 'ogg');
      expect(AudioFormats.apiFormatForPath('ohne_endung'), 'mp3');
    });

    test('leitet ein AAC-Format nicht über den MIME-Typ ab', () {
      expect(AudioFormats.mimeTypeForPath('a.m4a'), 'audio/mpeg');
      expect(AudioFormats.apiFormatForPath('a.m4a'), isNot('mp3'));
    });
  });

  group('FileSizeFormatter', () {
    test('formatiert alle Größenordnungen', () {
      expect(FileSizeFormatter.format(512), '512 B');
      expect(FileSizeFormatter.format(2048), '2.0 KB');
      expect(FileSizeFormatter.format(5 * 1024 * 1024), '5.0 MB');
      expect(FileSizeFormatter.format(3 * 1024 * 1024 * 1024), '3.0 GB');
    });
  });

  group('PathUtils', () {
    test('normalisiert Trenner und abschließende Zeichen', () {
      final expected = Platform.isWindows ? '/storage/music' : '/storage/Music';
      expect(PathUtils.normalize('/storage/Music/'), expected);
      expect(PathUtils.normalize(r'\storage\Music'), expected);
    });

    test('entfernt unzulässige Zeichen aus Dateinamen', () {
      expect(PathUtils.sanitizeFileName('a/b:c?.m4a'), 'a_b_c_.m4a');
    });

    test('liefert den Dateinamen', () {
      expect(PathUtils.fileNameOf('/storage/Music/song.mp3'), 'song.mp3');
      expect(PathUtils.fileNameOf(r'C:\Musik\song.mp3'), 'song.mp3');
    });
  });
}
