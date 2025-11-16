# VIOSA Stage 2 - Zusätzliche Features
## Voice Recording, LLM Streaming & History

**Datum:** 2025-11-15
**Teil von:** Stage 2 Erweiterung

---

## Feature 1: Voice Recording (Audio-Aufnahme)

### 1.1 Übersicht

Nutzer können direkt in der App Audio aufnehmen, statt nur Dateien hochzuladen.

**Vorteile:**
- Schneller Workflow (keine externe Aufnahme-App nötig)
- Konsistente Audio-Qualität
- Direkt transkribieren nach Aufnahme
- Ideal für Notizen, Memos, Meetings

### 1.2 UI/UX Design

#### Home Screen - Recording-Option

```dart
// Erweiterter FAB mit zwei Optionen
FloatingActionButton(
  onPressed: _showUploadOptions,
  child: Icon(Icons.add),
)

// Bottom Sheet mit Optionen
void _showUploadOptions() {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.mic, color: Colors.red),
          title: Text('Audio aufnehmen'),
          subtitle: Text('Neue Aufnahme starten'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecordingScreen()),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.upload_file),
          title: Text('Datei hochladen'),
          subtitle: Text('MP3, WAV, MP4 auswählen'),
          onTap: () {
            Navigator.pop(context);
            _pickFile();
          },
        ),
      ],
    ),
  );
}
```

#### Recording Screen Layout

```
┌─────────────────────────────┐
│ ← Abbrechen   Aufnahme      │
├─────────────────────────────┤
│                             │
│     ⏺  Aufnahme-Button      │ ← 80dp, zentriert, Pulsing Animation
│                             │
│     00:03:24                │ ← Timer
│                             │
│  ▁▃▅▇▅▃▁▃▅▇▅▃▁             │ ← Waveform-Visualisierung
│                             │
│  [═══════════════○──]       │ ← Progress (nur wenn pausiert)
│                             │
│  [ Pause ] [ Stopp ]        │ ← Controls (nur während Aufnahme)
│                             │
│  Aufnahmequalität: Hoch     │ ← Info
│  Format: WAV, 48kHz         │
│                             │
│  [Speichern & Transkribieren]│ ← Primary Action (nach Stopp)
└─────────────────────────────┘
```

### 1.3 Technische Implementierung

#### Dependencies

```yaml
dependencies:
  record: ^5.0.4                # Audio Recording
  path_provider: ^2.1.1         # Dateipfade
  audio_waveforms: ^1.0.5       # Waveform-Visualisierung
```

#### RecordingService

```dart
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  String? _recordingPath;
  bool _isRecording = false;
  bool _isPaused = false;

  // Stream für Amplitude (für Waveform)
  Stream<Amplitude> get amplitudeStream => _recorder.onAmplitudeChanged;

  // Aufnahme starten
  Future<void> startRecording() async {
    // Permission check
    if (!await _recorder.hasPermission()) {
      throw Exception('Mikrofon-Berechtigung erforderlich');
    }

    // Pfad für Aufnahme
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _recordingPath = '${directory.path}/recording_$timestamp.wav';

    // Aufnahme-Konfiguration
    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 48000,
      bitRate: 128000,
      numChannels: 1,
    );

    await _recorder.start(config, path: _recordingPath!);
    _isRecording = true;
    _isPaused = false;
  }

  // Aufnahme pausieren
  Future<void> pauseRecording() async {
    if (_isRecording && !_isPaused) {
      await _recorder.pause();
      _isPaused = true;
    }
  }

  // Aufnahme fortsetzen
  Future<void> resumeRecording() async {
    if (_isRecording && _isPaused) {
      await _recorder.resume();
      _isPaused = false;
    }
  }

  // Aufnahme stoppen
  Future<String?> stopRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      _isRecording = false;
      _isPaused = false;
      return path;
    }
    return null;
  }

  // Aufnahme abbrechen (Datei löschen)
  Future<void> cancelRecording() async {
    await stopRecording();
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  // Status abfragen
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;

  void dispose() {
    _recorder.dispose();
  }
}
```

#### RecordingScreen

```dart
class RecordingScreen extends StatefulWidget {
  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final RecordingService _recordingService = RecordingService();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  RecordingState _state = RecordingState.initial;
  String _duration = '00:00:00';

  @override
  void dispose() {
    _timer?.cancel();
    _recordingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _confirmCancel,
        ),
        title: Text('Aufnahme'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aufnahme-Button (groß, zentriert)
            _buildRecordButton(),
            SizedBox(height: 32),

            // Timer
            Text(
              _duration,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(height: 32),

            // Waveform-Visualisierung
            if (_state == RecordingState.recording || _state == RecordingState.paused)
              _buildWaveform(),
            SizedBox(height: 32),

            // Control Buttons
            if (_state == RecordingState.recording || _state == RecordingState.paused)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: Icon(_state == RecordingState.paused ? Icons.play_arrow : Icons.pause),
                    label: Text(_state == RecordingState.paused ? 'Fortsetzen' : 'Pause'),
                    onPressed: _togglePause,
                  ),
                  FilledButton.icon(
                    icon: Icon(Icons.stop),
                    label: Text('Stopp'),
                    onPressed: _stopRecording,
                  ),
                ],
              ),

            // Speichern-Button (nach Stopp)
            if (_state == RecordingState.stopped)
              FilledButton.icon(
                icon: Icon(Icons.check),
                label: Text('Speichern & Transkribieren'),
                onPressed: _saveAndTranscribe,
                style: FilledButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                ),
              ),

            SizedBox(height: 16),

            // Info
            if (_state != RecordingState.initial)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aufnahmequalität: Hoch', style: TextStyle(fontSize: 12)),
                      Text('Format: WAV, 48kHz, Mono', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    final isActive = _state == RecordingState.recording;

    return GestureDetector(
      onTap: _state == RecordingState.initial ? _startRecording : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.red : Colors.red[400],
          boxShadow: isActive
            ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)]
            : [],
        ),
        child: Icon(
          isActive ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return StreamBuilder<Amplitude>(
      stream: _recordingService.amplitudeStream,
      builder: (context, snapshot) {
        return Container(
          height: 100,
          child: AudioWaveforms(
            size: Size(MediaQuery.of(context).size.width - 48, 100),
            recorderController: _recorderController,
            waveStyle: WaveStyle(
              waveColor: Theme.of(context).colorScheme.primary,
              showDurationLabel: false,
              spacing: 4,
              showBottom: false,
              extendWaveform: true,
              showMiddleLine: false,
            ),
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    try {
      await _recordingService.startRecording();
      setState(() => _state = RecordingState.recording);

      _stopwatch.start();
      _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
        setState(() {
          _duration = _formatDuration(_stopwatch.elapsed);
        });
      });
    } catch (e) {
      _showError('Aufnahme fehlgeschlagen: $e');
    }
  }

  Future<void> _togglePause() async {
    if (_state == RecordingState.paused) {
      await _recordingService.resumeRecording();
      _stopwatch.start();
      setState(() => _state = RecordingState.recording);
    } else {
      await _recordingService.pauseRecording();
      _stopwatch.stop();
      setState(() => _state = RecordingState.paused);
    }
  }

  Future<void> _stopRecording() async {
    await _recordingService.stopRecording();
    _stopwatch.stop();
    _timer?.cancel();
    setState(() => _state = RecordingState.stopped);
  }

  Future<void> _saveAndTranscribe() async {
    final path = await _recordingService.stopRecording();
    if (path != null) {
      // Navigiere zurück und starte Transkription
      Navigator.pop(context, path);
    }
  }

  Future<void> _confirmCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aufnahme verwerfen?'),
        content: Text('Die aktuelle Aufnahme wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Verwerfen'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      await _recordingService.cancelRecording();
      Navigator.pop(context);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

enum RecordingState { initial, recording, paused, stopped }
```

#### Android Permissions

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

---

## Feature 2: LLM Streaming (Echtzeit-Antworten)

### 2.1 Übersicht

Statt auf die komplette LLM-Antwort zu warten, wird der Text Wort für Wort angezeigt (wie ChatGPT).

**Vorteile:**
- Bessere UX (sofortiges Feedback)
- Gefühl von schnellerer Verarbeitung
- User kann abbrechen wenn Antwort ausreichend
- Moderne, erwartete Funktionalität

### 2.2 UI/UX Design

#### Streaming Text Widget

```
AI-Antwort Card (während Streaming):
┌─────────────────────────────┐
│ ✨ AI-Antwort              │
│ Prompt: Zusammenfassen      │
├─────────────────────────────┤
│                             │
│ Die Transkription beschreibt│
│ eine Diskussion über█       │ ← Blinkender Cursor
│                             │
│ ⏸ Pause  ⏹ Stopp           │ ← Stream Controls
└─────────────────────────────┘

Nach Streaming (vollständig):
┌─────────────────────────────┐
│ ✨ AI-Antwort ✓             │ ← Checkmark
│ Prompt: Zusammenfassen      │
├─────────────────────────────┤
│                             │
│ Die Transkription beschreibt│
│ eine Diskussion über die    │
│ Implementierung einer       │
│ Flutter-App...              │
│                             │
│ [📋 Kopieren] [↗️ Teilen]   │
└─────────────────────────────┘
```

### 2.3 Technische Implementierung

#### OpenRouter Streaming API

OpenRouter unterstützt Server-Sent Events (SSE) für Streaming:

```dart
class OpenRouterService {
  final Dio _dio = Dio();

  // NEUE Methode: Stream-basiert
  Stream<String> applyPromptToTranscriptionStream({
    required String apiKey,
    required String transcription,
    required String promptContent,
    String model = 'google/gemini-flash-1.5',
  }) async* {
    final request = {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': '$promptContent\n\nTRANSKRIPTION:\n$transcription',
        },
      ],
      'max_tokens': 4000,
      'temperature': 0.7,
      'stream': true,  // ← WICHTIG: Streaming aktivieren
    };

    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        data: request,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://viosa-app.local',
            'X-Title': 'VIOSA Prompt Application',
          },
          responseType: ResponseType.stream,  // ← Stream-Response
        ),
      );

      // SSE Stream parsen
      final stream = response.data.stream as Stream<List<int>>;

      await for (final chunk in stream) {
        final lines = utf8.decode(chunk).split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);

            // Stream-Ende
            if (data == '[DONE]') {
              break;
            }

            // JSON parsen
            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'];

              if (content != null) {
                yield content as String;  // ← Text-Chunk ausgeben
              }
            } catch (e) {
              // Parsing-Fehler ignorieren
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Streaming fehlgeschlagen: $e');
    }
  }

  // BESTEHENDE Methode bleibt für Fallback
  Future<String> applyPromptToTranscription({...}) async {
    // ... wie vorher (ohne streaming)
  }
}
```

#### StreamingTextWidget

```dart
class StreamingTextWidget extends StatefulWidget {
  final Stream<String> textStream;
  final MarkdownStyleSheet styleSheet;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const StreamingTextWidget({
    required this.textStream,
    required this.styleSheet,
    this.onComplete,
    this.onCancel,
  });

  @override
  _StreamingTextWidgetState createState() => _StreamingTextWidgetState();
}

class _StreamingTextWidgetState extends State<StreamingTextWidget>
    with SingleTickerProviderStateMixin {

  String _fullText = '';
  bool _isStreaming = true;
  bool _isPaused = false;
  StreamSubscription? _subscription;

  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();

    // Blinkender Cursor
    _cursorController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _startStreaming();
  }

  void _startStreaming() {
    _subscription = widget.textStream.listen(
      (chunk) {
        if (!_isPaused) {
          setState(() {
            _fullText += chunk;
          });

          // Auto-scroll nach unten
          _scrollToBottom();
        }
      },
      onDone: () {
        setState(() => _isStreaming = false);
        _cursorController.stop();
        widget.onComplete?.call();
      },
      onError: (error) {
        setState(() => _isStreaming = false);
        _showError(error.toString());
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streaming Content mit Cursor
        MarkdownBody(
          data: _fullText + (_isStreaming ? _buildCursor() : ''),
          styleSheet: widget.styleSheet,
          selectable: !_isStreaming,  // Nur selectable wenn fertig
        ),

        // Stream Controls (während Streaming)
        if (_isStreaming) ...[
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(_isPaused ? 'Fortsetzen' : 'Pause'),
                onPressed: _togglePause,
              ),
              SizedBox(width: 8),
              TextButton.icon(
                icon: Icon(Icons.stop),
                label: Text('Stopp'),
                onPressed: _stopStreaming,
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _buildCursor() {
    return _cursorController.value > 0.5 ? '█' : ' ';
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _stopStreaming() {
    _subscription?.cancel();
    setState(() => _isStreaming = false);
    _cursorController.stop();
    widget.onCancel?.call();
  }

  void _scrollToBottom() {
    // Implementierung abhängig von ScrollController
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fehler: $message')),
    );
  }
}
```

#### Integration in Results Screen

```dart
// In ExpandableCard für AI-Antwort
ExpandableCard(
  title: 'AI-Antwort',
  subtitle: _isStreaming ? 'Wird generiert...' : 'Prompt: ${widget.promptUsed}',
  icon: Icons.auto_awesome,
  isExpanded: _aiResponseExpanded,
  onExpandToggle: () {
    setState(() => _aiResponseExpanded = !_aiResponseExpanded);
  },
  content: _isStreaming
    ? StreamingTextWidget(
        textStream: _aiResponseStream,
        styleSheet: markdownStyleSheet,
        onComplete: () {
          setState(() => _isStreaming = false);
        },
      )
    : MarkdownBody(
        data: _aiResponse,
        styleSheet: markdownStyleSheet,
        selectable: true,
      ),
  actions: !_isStreaming ? [
    TextButton.icon(
      icon: Icon(Icons.copy),
      label: Text('Kopieren'),
      onPressed: () => _copyToClipboard(_aiResponse),
    ),
    TextButton.icon(
      icon: Icon(Icons.share),
      label: Text('Teilen'),
      onPressed: () => _share(_aiResponse),
    ),
  ] : [],
)
```

---

## Feature 3: History (Transkriptions-Historie)

### 3.1 Übersicht

Alle Transkriptionen und Prompt-Anwendungen werden lokal gespeichert und können durchsucht werden.

**Vorteile:**
- Zugriff auf vergangene Transkriptionen
- Wiederverwendung von Prompts
- Suche nach Stichwörtern
- Daten bleiben lokal (Privacy)

### 3.2 UI/UX Design

#### History Screen Layout

```
┌─────────────────────────────┐
│ ← Zurück     Verlauf    🔍  │
├─────────────────────────────┤
│ 🔍 Suchen...                │ ← Such-Feld
│ [Alle] [Heute] [Diese Woche]│ ← Filter-Chips
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │ 📝 Meeting-Notizen      │ │ ← History Item
│ │ Heute, 14:23            │ │
│ │ "Die Diskussion über..."│ │
│ │ Prompt: Zusammenfassen  │ │
│ │ [Details] [Löschen]     │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 📝 Podcast-Transkript   │ │
│ │ Gestern, 09:15          │ │
│ │ "In dieser Episode..."  │ │
│ │ Keine Prompts angewendet│ │
│ │ [Details] [Löschen]     │ │
│ └─────────────────────────┘ │
│                             │
│ ... mehr Items ...          │
│                             │
└─────────────────────────────┘
```

#### History Detail View

```
┌─────────────────────────────┐
│ ← Zurück     Details    ⋮   │
├─────────────────────────────┤
│ Meeting-Notizen             │
│ Heute, 14:23                │
│ Dauer: 15:32                │
├─────────────────────────────┤
│                             │
│ [Transkription] [Prompts]   │ ← Tabs
│                             │
│ Original-Transkription:     │
│ "Die Diskussion begann..."  │
│                             │
│ [📋 Kopieren] [↗️ Teilen]   │
│                             │
│ Angewendete Prompts (2):    │
│ ┌─────────────────────────┐ │
│ │ Zusammenfassen          │ │
│ │ "Die wichtigsten..."    │ │
│ │ [Anzeigen]              │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

### 3.3 Technische Implementierung

#### Dependencies

```yaml
dependencies:
  sqflite: ^2.3.0           # SQLite Database
  path: ^1.8.3              # Pfad-Utilities
```

#### Datenbank-Schema

```dart
// utils/database_helper.dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('viosa_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabelle: Transkriptionen
    await db.execute('''
      CREATE TABLE transcriptions (
        id TEXT PRIMARY KEY,
        audio_file_name TEXT NOT NULL,
        audio_file_path TEXT NOT NULL,
        transcription_text TEXT NOT NULL,
        language TEXT NOT NULL,
        model_used TEXT NOT NULL,
        duration_seconds INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabelle: Prompt-Anwendungen
    await db.execute('''
      CREATE TABLE prompt_applications (
        id TEXT PRIMARY KEY,
        transcription_id TEXT NOT NULL,
        prompt_id TEXT NOT NULL,
        prompt_name TEXT NOT NULL,
        prompt_content TEXT NOT NULL,
        ai_response TEXT NOT NULL,
        model_used TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (transcription_id) REFERENCES transcriptions (id)
          ON DELETE CASCADE
      )
    ''');

    // Index für schnellere Suche
    await db.execute('''
      CREATE INDEX idx_transcriptions_created_at
      ON transcriptions(created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_prompt_applications_transcription_id
      ON prompt_applications(transcription_id)
    ''');
  }
}
```

#### HistoryEntry Model

```dart
class HistoryEntry {
  final String id;
  final String audioFileName;
  final String audioFilePath;
  final String transcriptionText;
  final String language;
  final String modelUsed;
  final int? durationSeconds;
  final DateTime createdAt;
  final List<PromptApplication> promptApplications;

  HistoryEntry({
    required this.id,
    required this.audioFileName,
    required this.audioFilePath,
    required this.transcriptionText,
    required this.language,
    required this.modelUsed,
    this.durationSeconds,
    required this.createdAt,
    this.promptApplications = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audio_file_name': audioFileName,
      'audio_file_path': audioFilePath,
      'transcription_text': transcriptionText,
      'language': language,
      'model_used': modelUsed,
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'],
      audioFileName: json['audio_file_name'],
      audioFilePath: json['audio_file_path'],
      transcriptionText: json['transcription_text'],
      language: json['language'],
      modelUsed: json['model_used'],
      durationSeconds: json['duration_seconds'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Getter für Vorschau-Text (erste 100 Zeichen)
  String get preview {
    if (transcriptionText.length <= 100) {
      return transcriptionText;
    }
    return '${transcriptionText.substring(0, 100)}...';
  }

  // Getter für formatierte Zeit
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Heute, ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Gestern, ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} Tage her';
    } else {
      return '${createdAt.day}.${createdAt.month}.${createdAt.year}';
    }
  }
}

class PromptApplication {
  final String id;
  final String transcriptionId;
  final String promptId;
  final String promptName;
  final String promptContent;
  final String aiResponse;
  final String modelUsed;
  final DateTime createdAt;

  PromptApplication({
    required this.id,
    required this.transcriptionId,
    required this.promptId,
    required this.promptName,
    required this.promptContent,
    required this.aiResponse,
    required this.modelUsed,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transcription_id': transcriptionId,
      'prompt_id': promptId,
      'prompt_name': promptName,
      'prompt_content': promptContent,
      'ai_response': aiResponse,
      'model_used': modelUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PromptApplication.fromJson(Map<String, dynamic> json) {
    return PromptApplication(
      id: json['id'],
      transcriptionId: json['transcription_id'],
      promptId: json['prompt_id'],
      promptName: json['prompt_name'],
      promptContent: json['prompt_content'],
      aiResponse: json['ai_response'],
      modelUsed: json['model_used'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
```

#### HistoryService

```dart
class HistoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Transkription speichern
  Future<String> saveTranscription(HistoryEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert('transcriptions', entry.toJson());
    return entry.id;
  }

  // Prompt-Anwendung speichern
  Future<void> savePromptApplication(PromptApplication application) async {
    final db = await _dbHelper.database;
    await db.insert('prompt_applications', application.toJson());
  }

  // Alle Transkriptionen abrufen (mit Limit und Offset für Pagination)
  Future<List<HistoryEntry>> getAllTranscriptions({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;

    final transcriptions = await db.query(
      'transcriptions',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    final entries = <HistoryEntry>[];

    for (final t in transcriptions) {
      final entry = HistoryEntry.fromJson(t);

      // Lade zugehörige Prompt-Anwendungen
      final prompts = await db.query(
        'prompt_applications',
        where: 'transcription_id = ?',
        whereArgs: [entry.id],
        orderBy: 'created_at DESC',
      );

      final promptApplications = prompts
        .map((p) => PromptApplication.fromJson(p))
        .toList();

      entries.add(HistoryEntry(
        id: entry.id,
        audioFileName: entry.audioFileName,
        audioFilePath: entry.audioFilePath,
        transcriptionText: entry.transcriptionText,
        language: entry.language,
        modelUsed: entry.modelUsed,
        durationSeconds: entry.durationSeconds,
        createdAt: entry.createdAt,
        promptApplications: promptApplications,
      ));
    }

    return entries;
  }

  // Suche in Transkriptionen
  Future<List<HistoryEntry>> searchTranscriptions(String query) async {
    final db = await _dbHelper.database;

    final transcriptions = await db.query(
      'transcriptions',
      where: 'transcription_text LIKE ? OR audio_file_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: 50,
    );

    return transcriptions.map((t) => HistoryEntry.fromJson(t)).toList();
  }

  // Transkription löschen (+ zugehörige Prompts durch CASCADE)
  Future<void> deleteTranscription(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'transcriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transkription nach ID abrufen
  Future<HistoryEntry?> getTranscriptionById(String id) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'transcriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final entry = HistoryEntry.fromJson(results.first);

    // Lade Prompts
    final prompts = await db.query(
      'prompt_applications',
      where: 'transcription_id = ?',
      whereArgs: [id],
    );

    return HistoryEntry(
      id: entry.id,
      audioFileName: entry.audioFileName,
      audioFilePath: entry.audioFilePath,
      transcriptionText: entry.transcriptionText,
      language: entry.language,
      modelUsed: entry.modelUsed,
      durationSeconds: entry.durationSeconds,
      createdAt: entry.createdAt,
      promptApplications: prompts
        .map((p) => PromptApplication.fromJson(p))
        .toList(),
    );
  }

  // Filter nach Datum
  Future<List<HistoryEntry>> getTranscriptionsByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _dbHelper.database;

    final transcriptions = await db.query(
      'transcriptions',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    return transcriptions.map((t) => HistoryEntry.fromJson(t)).toList();
  }
}
```

#### HistoryScreen

```dart
class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final TextEditingController _searchController = TextEditingController();

  List<HistoryEntry> _entries = [];
  List<HistoryEntry> _filteredEntries = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterEntries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final entries = await _historyService.getAllTranscriptions();
      setState(() {
        _entries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Fehler beim Laden: $e');
    }
  }

  void _filterEntries() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredEntries = _entries;
      } else {
        _filteredEntries = _entries.where((entry) {
          return entry.audioFileName.toLowerCase().contains(query) ||
                 entry.transcriptionText.toLowerCase().contains(query);
        }).toList();
      }

      // Zusätzlicher Datumsfilter
      if (_selectedFilter == 'today') {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        _filteredEntries = _filteredEntries.where((e) {
          return e.createdAt.isAfter(today);
        }).toList();
      } else if (_selectedFilter == 'week') {
        final weekAgo = DateTime.now().subtract(Duration(days: 7));
        _filteredEntries = _filteredEntries.where((e) {
          return e.createdAt.isAfter(weekAgo);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verlauf'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: _confirmDeleteAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchfeld
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suchen...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              ),
            ),
          ),

          // Filter-Chips
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Alle'),
                  selected: _selectedFilter == 'all',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'all');
                    _filterEntries();
                  },
                ),
                ChoiceChip(
                  label: Text('Heute'),
                  selected: _selectedFilter == 'today',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'today');
                    _filterEntries();
                  },
                ),
                ChoiceChip(
                  label: Text('Diese Woche'),
                  selected: _selectedFilter == 'week',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'week');
                    _filterEntries();
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Liste
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _filteredEntries.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: ListView.builder(
                      itemCount: _filteredEntries.length,
                      itemBuilder: (context, index) {
                        return HistoryListItem(
                          entry: _filteredEntries[index],
                          onTap: () => _showDetails(_filteredEntries[index]),
                          onDelete: () => _deleteEntry(_filteredEntries[index]),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Noch keine Transkriptionen',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showDetails(HistoryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailScreen(entry: entry),
      ),
    );
  }

  Future<void> _deleteEntry(HistoryEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eintrag löschen?'),
        content: Text('${entry.audioFileName} wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Löschen'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _historyService.deleteTranscription(entry.id);
      await _loadHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eintrag gelöscht'),
          action: SnackBarAction(
            label: 'Rückgängig',
            onPressed: () {
              // Undo-Logik hier
            },
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAll() async {
    // Ähnlich wie _deleteEntry, aber für alle
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

#### HistoryListItem Widget

```dart
class HistoryListItem extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryListItem({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Löschen?'),
            content: Text('Eintrag unwiderruflich löschen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Löschen'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.audioFileName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  entry.formattedTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  entry.preview,
                  style: TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                if (entry.promptApplications.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.purple),
                      Text(
                        '${entry.promptApplications.length} Prompt(s) angewendet',
                        style: TextStyle(fontSize: 12, color: Colors.purple),
                      ),
                    ],
                  )
                else
                  Text(
                    'Keine Prompts angewendet',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Zusammenfassung: Erweiterte Stage 2

### Entwicklungszeit-Schätzung

| Feature | Zeit |
|---------|------|
| **Basis Stage 2** (Prompts, Markdown) | 2,5-4h |
| **Voice Recording** | 1,5-2h |
| **LLM Streaming** | 1-1,5h |
| **History** | 2-3h |
| **TOTAL Stage 2** | **7-10,5h** |

### Erweiterte Dependencies

```yaml
dependencies:
  # Stage 1 (Basis)
  flutter:
    sdk: flutter
  just_audio: ^0.9.36
  file_picker: ^6.1.1
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  provider: ^6.1.1
  path_provider: ^2.1.1

  # Stage 2 (Basis)
  gpt_markdown: ^0.8.0
  share_plus: ^7.2.1
  url_launcher: ^6.2.2
  uuid: ^4.2.2

  # NEU: Voice Recording
  record: ^5.0.4
  audio_waveforms: ^1.0.5

  # NEU: History
  sqflite: ^2.3.0
  path: ^1.8.3
```

### Prioritäten

**Must-Have (Stage 2 Kern):**
1. ✅ Prompt-Management
2. ✅ Markdown-Rendering
3. ✅ Copy & Share

**High Priority (erweiterte Stage 2):**
1. ✅ **LLM Streaming** - Moderne UX, erwartet von Nutzern
2. ✅ **History** - Essentiell für wiederholte Nutzung
3. ⚠️ **Voice Recording** - Nice-to-have, aber sehr praktisch

**Empfohlene Reihenfolge:**
1. Stage 2 Basis (Prompts + Markdown)
2. LLM Streaming (relativ einfach zu integrieren)
3. History (wichtig für Produktivität)
4. Voice Recording (optional, aber rundet App ab)

---

**Erstellt mit:** Claude Code (Sonnet 4.5)
**Teil von:** VIOSA Stage 2 Implementierungsplan
