# VIOSA - Audio-Transkriptions-App
## Implementierungsplan

**Datum:** 2025-11-16
**Framework:** Flutter
**Zielplattform:** Android 14 (Android Studio Emulator)
**LLM Provider:** OpenRouter (Gemini Flash 2.5)
**Entwicklungszeit:** 3-6 Stunden

---

## 1. Projekt-Übersicht

### 1.1 Zielsetzung
Eine einfache, moderne Android-App zur Audio-Transkription mit folgenden Kernfunktionen:
- Audio-Dateien auswählen (MP4, MP3, WAV)
- Audio-Dateien abspielen
- Audio-Transkription via OpenRouter API (Gemini Flash 2.5 oder GLM 4.6 als Option)
- API-Key-Verwaltung in den Einstellungen
- Sprachauswahl: Deutsch, Englisch, Auto-Detect

### 1.2 Technologie-Stack
- **Framework:** Flutter 3.x
- **Sprache:** Dart
- **UI:** Material Design 3
- **Audio-Wiedergabe:** `just_audio` Package
- **Dateiauswahl:** `file_picker` Package
- **API-Aufrufe:** `dio` Package
- **Sichere Speicherung:** `flutter_secure_storage` Package
- **State Management:** Provider

---

## 2. Architektur-Übersicht

### 2.1 Ordnerstruktur
```
viosa/
├── lib/
│   ├── main.dart                      # App-Einstiegspunkt
│   ├── models/                        # Datenmodelle
│   │   ├── transcription_result.dart
│   │   └── audio_file.dart
│   ├── services/                      # Business Logic
│   │   ├── openrouter_service.dart    # OpenRouter API Integration
│   │   ├── audio_service.dart         # Audio-Wiedergabe
│   │   ├── file_service.dart          # Datei-Handling
│   │   └── settings_service.dart      # API-Key-Verwaltung
│   ├── screens/                       # UI-Screens
│   │   ├── home_screen.dart           # Hauptbildschirm
│   │   ├── settings_screen.dart       # Einstellungen
│   │   └── transcription_screen.dart  # Transkriptions-Ergebnis
│   ├── widgets/                       # Wiederverwendbare UI-Komponenten
│   │   ├── audio_player_widget.dart
│   │   ├── file_picker_button.dart
│   │   └── transcription_card.dart
│   └── utils/                         # Hilfsfunktionen
│       ├── constants.dart
│       └── audio_converter.dart       # Base64-Konvertierung
├── android/                           # Android-spezifische Konfiguration
├── pubspec.yaml                       # Abhängigkeiten
└── thoughts/                          # Dokumentation
    └── implementation-plan.md         # Dieser Plan
```

### 2.2 Datenfluss
```
User Input (Dateiauswahl)
    ↓
FileService (Datei laden)
    ↓
AudioService (Optional: Abspielen)
    ↓
OpenRouterService (Base64 + API-Aufruf)
    ↓
TranscriptionResult (Anzeige)
```

---

## 3. Detaillierte Implementierungsphasen

### Phase 1: Projekt-Setup (15-30 Minuten)

#### 3.1.1 Flutter-Projekt erstellen
```bash
flutter create viosa
cd viosa
```

#### 3.1.2 Abhängigkeiten in `pubspec.yaml` hinzufügen
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Audio
  just_audio: ^0.10.5

  # Dateiauswahl
  file_picker: ^10.3.6

  # HTTP
  dio: ^5.9.0

  # Sichere Speicherung
  flutter_secure_storage: ^9.2.4

  # State Management
  provider: ^6.1.5

  # UI Helpers
  flutter_spinkit: ^5.2.2  # Ladeanimationen

  # Utilities
  path_provider: ^2.1.5
  mime: ^2.0.0
```

#### 3.1.3 Android-Berechtigungen konfigurieren
**Datei:** `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

#### 3.1.4 Abhängigkeiten installieren
```bash
flutter pub get
```

#### 3.1.5 Android Studio Emulator-Verbindung testen
```bash
flutter devices
flutter run
```

---

### Phase 2: Core Services implementieren (60-90 Minuten)

#### 3.2.1 SettingsService - API-Key-Verwaltung
**Datei:** `lib/services/settings_service.dart`

**Funktionen:**
- API-Key sicher speichern (FlutterSecureStorage)
- API-Key abrufen
- Sprache speichern/abrufen (Deutsch, Englisch, Auto)
- Base URL für OpenRouter (https://openrouter.ai/api/v1)

**Wichtige Implementierungsdetails:**
```dart
class SettingsService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // API Key
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: 'openrouter_api_key', value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: 'openrouter_api_key');
  }

  // Language preference
  Future<void> saveLanguage(String language) async {
    await _storage.write(key: 'transcription_language', value: language);
  }

  Future<String> getLanguage() async {
    return await _storage.read(key: 'transcription_language') ?? 'auto';
  }
}
```

#### 3.2.2 FileService - Dateiauswahl und Base64-Konvertierung
**Datei:** `lib/services/file_service.dart`

**Funktionen:**
- Datei-Picker öffnen (nur Audio-Dateien: MP3, WAV, MP4)
- Datei zu Base64 konvertieren
- MIME-Type erkennen
- Datei-Validierung (Größe, Format)

**Wichtige Implementierungsdetails:**
```dart
class FileService {
  Future<AudioFile?> pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'mp4', 'm4a'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);
      final mimeType = _getMimeType(result.files.single.extension);

      return AudioFile(
        path: file.path,
        name: result.files.single.name,
        base64Data: base64Audio,
        mimeType: mimeType,
        size: bytes.length,
      );
    }
    return null;
  }

  String _getMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'mp4': return 'audio/mp4';
      case 'm4a': return 'audio/mp4';
      default: return 'audio/mpeg';
    }
  }
}
```

#### 3.2.3 AudioService - Audio-Wiedergabe
**Datei:** `lib/services/audio_service.dart`

**Funktionen:**
- Audio-Datei laden
- Abspielen/Pausieren
- Position verfolgen
- Dauer abrufen

**Wichtige Implementierungsdetails:**
```dart
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> loadAudio(String filePath) async {
    await _player.setFilePath(filePath);
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void dispose() {
    _player.dispose();
  }
}
```

#### 3.2.4 OpenRouterService - API-Integration
**Datei:** `lib/services/openrouter_service.dart`

**Funktionen:**
- Multimodal-Request an OpenRouter senden
- Gemini Flash 2.5 als Model verwenden
- Sprach-Parameter übergeben
- Fehlerbehandlung
- Response parsen

**API-Struktur basierend auf aeon-Implementierung:**
```dart
class OpenRouterService {
  final String baseUrl = 'https://openrouter.ai/api/v1';
  final Dio _dio = Dio();

  Future<TranscriptionResult> transcribeAudio({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  }) async {
    final String model = 'google/gemini-flash-1.5';

    // Prompt basierend auf Sprache
    String prompt = _getPromptForLanguage(language);

    final request = {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt,
            },
            {
              'type': 'audio_url',
              'audio_url': {
                'url': 'data:$mimeType;base64,$base64Audio',
              },
            },
          ],
        },
      ],
      'max_tokens': 4000,
      'temperature': 0.3,
    };

    try {
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://viosa-app.local',
            'X-Title': 'VIOSA Audio Transcription',
          },
        ),
      );

      final transcribedText = response.data['choices'][0]['message']['content'];

      return TranscriptionResult(
        text: transcribedText,
        language: language,
        modelUsed: model,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Transkription fehlgeschlagen: $e');
    }
  }

  String _getPromptForLanguage(String language) {
    switch (language) {
      case 'de':
        return 'Transkribiere die folgende Audiodatei auf Deutsch. Gib nur den transkribierten Text zurück, ohne zusätzliche Erklärungen.';
      case 'en':
        return 'Transcribe the following audio file in English. Return only the transcribed text without additional explanations.';
      case 'auto':
      default:
        return 'Transcribe the following audio file in its original language. Return only the transcribed text without additional explanations.';
    }
  }
}
```

---

### Phase 3: Datenmodelle (15-20 Minuten)

#### 3.3.1 AudioFile Model
**Datei:** `lib/models/audio_file.dart`

```dart
class AudioFile {
  final String path;
  final String name;
  final String base64Data;
  final String mimeType;
  final int size;

  AudioFile({
    required this.path,
    required this.name,
    required this.base64Data,
    required this.mimeType,
    required this.size,
  });

  String get sizeInMB => (size / (1024 * 1024)).toStringAsFixed(2);
}
```

#### 3.3.2 TranscriptionResult Model
**Datei:** `lib/models/transcription_result.dart`

```dart
class TranscriptionResult {
  final String text;
  final String language;
  final String modelUsed;
  final DateTime timestamp;

  TranscriptionResult({
    required this.text,
    required this.language,
    required this.modelUsed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'language': language,
      'modelUsed': modelUsed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
```

---

### Phase 4: UI-Screens (60-90 Minuten)

#### 3.4.1 Main App Entry Point
**Datei:** `lib/main.dart`

```dart
void main() {
  runApp(const VIOSAApp());
}

class VIOSAApp extends StatelessWidget {
  const VIOSAApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIOSA',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}
```

#### 3.4.2 HomeScreen - Hauptbildschirm
**Datei:** `lib/screens/home_screen.dart`

**UI-Komponenten:**
- AppBar mit Titel "VIOSA" und Settings-Icon
- Floating Action Button zum Datei-Auswahl
- Liste der ausgewählten Dateien (falls vorhanden)
- Audio-Player-Widget (wenn Datei ausgewählt)
- "Transkribieren"-Button
- Fortschrittsanzeige während API-Aufruf

**Layout-Struktur:**
```dart
Scaffold(
  appBar: AppBar(
    title: Text('VIOSA'),
    actions: [
      IconButton(
        icon: Icon(Icons.settings),
        onPressed: () => Navigator.push(...SettingsScreen),
      ),
    ],
  ),
  body: Column(
    children: [
      // Audio Player Widget (falls Datei vorhanden)
      if (selectedFile != null) AudioPlayerWidget(file: selectedFile),

      // File Info Card
      if (selectedFile != null) FileInfoCard(file: selectedFile),

      // Transcribe Button
      if (selectedFile != null)
        ElevatedButton.icon(
          icon: Icon(Icons.transcribe),
          label: Text('Transkribieren'),
          onPressed: _transcribe,
        ),

      // Transcription Result
      if (transcriptionResult != null)
        TranscriptionCard(result: transcriptionResult),
    ],
  ),
  floatingActionButton: FloatingActionButton(
    child: Icon(Icons.audio_file),
    onPressed: _pickFile,
  ),
)
```

#### 3.4.3 SettingsScreen - Einstellungen
**Datei:** `lib/screens/settings_screen.dart`

**UI-Komponenten:**
- TextField für API-Key (obscured)
- Dropdown für Sprachauswahl (Deutsch, Englisch, Auto-Detect)
- "Speichern"-Button
- Info-Text mit Link zu OpenRouter

**Layout-Struktur:**
```dart
Scaffold(
  appBar: AppBar(title: Text('Einstellungen')),
  body: Padding(
    padding: EdgeInsets.all(16.0),
    child: Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'OpenRouter API-Key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          controller: _apiKeyController,
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Sprache',
            border: OutlineInputBorder(),
          ),
          value: _selectedLanguage,
          items: [
            DropdownMenuItem(value: 'auto', child: Text('Auto-Detect')),
            DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) => setState(() => _selectedLanguage = value!),
        ),
        SizedBox(height: 24),
        ElevatedButton(
          child: Text('Speichern'),
          onPressed: _saveSettings,
        ),
      ],
    ),
  ),
)
```

---

### Phase 5: Widgets (30-45 Minuten)

#### 3.5.1 AudioPlayerWidget
**Datei:** `lib/widgets/audio_player_widget.dart`

**Features:**
- Play/Pause-Button
- Fortschrittsbalken (Slider)
- Zeitanzeige (aktuelle Position / Gesamtdauer)
- Schönes Material Design 3 Layout

#### 3.5.2 TranscriptionCard
**Datei:** `lib/widgets/transcription_card.dart`

**Features:**
- Transkribierter Text in Card
- Kopieren-Button
- Metadaten (Sprache, Model, Zeitstempel)
- Teilen-Funktion (optional)

#### 3.5.3 FileInfoCard
**Datei:** `lib/widgets/file_info_card.dart`

**Features:**
- Dateiname
- Dateigröße
- Format (MIME-Type)
- Icon basierend auf Dateityp

---

### Phase 6: Testing & Polish (30-45 Minuten)

#### 3.6.1 Funktionstests
- API-Key speichern/laden
- Datei auswählen (MP3, WAV, MP4)
- Audio abspielen/pausieren
- Transkription mit allen Sprachen testen
- Fehlerbehandlung (kein API-Key, ungültige Datei, Netzwerkfehler)

#### 3.6.2 UI-Verbesserungen
- Ladeanimationen (SpinKit)
- Fehler-Snackbars
- Validierung (API-Key-Format)
- Dark Mode Support (optional)

#### 3.6.3 Performance
- Base64-Konvertierung für große Dateien optimieren
- Memory Management für Audio-Player

---

## 4. OpenRouter API-Details

### 4.1 Endpoint
```
POST https://openrouter.ai/api/v1/chat/completions
```

### 4.2 Request-Struktur (Multimodal Audio)
```json
{
  "model": "google/gemini-flash-1.5",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Transkribiere die folgende Audiodatei..."
        },
        {
          "type": "audio_url",
          "audio_url": {
            "url": "data:audio/mpeg;base64,<BASE64_DATA>"
          }
        }
      ]
    }
  ],
  "max_tokens": 4000,
  "temperature": 0.3
}
```

### 4.3 Headers
```
Authorization: Bearer <API_KEY>
Content-Type: application/json
HTTP-Referer: https://viosa-app.local
X-Title: VIOSA Audio Transcription
```

### 4.4 Response-Struktur
```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Transkribierter Text hier..."
      }
    }
  ],
  "model": "google/gemini-flash-1.5",
  "usage": {
    "prompt_tokens": 1234,
    "completion_tokens": 567
  }
}
```

---

## 5. Entwicklungs-Checkliste

### Phase 1: Setup
- [x] Flutter-Projekt erstellen
- [x] Dependencies in pubspec.yaml hinzufügen
- [x] Android-Berechtigungen konfigurieren
- [x] flutter pub get ausführen
- [ ] Android Studio Emulator-Verbindung testen

### Phase 2: Services
- [ ] SettingsService implementieren
- [ ] FileService implementieren
- [ ] AudioService implementieren
- [ ] OpenRouterService implementieren
- [ ] Services testen (Unit Tests optional)

### Phase 3: Models
- [ ] AudioFile Model erstellen
- [ ] TranscriptionResult Model erstellen

### Phase 4: UI Screens
- [ ] main.dart erstellen
- [ ] HomeScreen implementieren
- [ ] SettingsScreen implementieren

### Phase 5: Widgets
- [ ] AudioPlayerWidget erstellen
- [ ] TranscriptionCard erstellen
- [ ] FileInfoCard erstellen

### Phase 6: Testing & Polish
- [ ] End-to-End-Test mit echten Audiodateien
- [ ] Fehlerbehandlung verfeinern
- [ ] UI-Feedback verbessern
- [ ] Performance testen

---

## 6. Potenzielle Herausforderungen & Lösungen

### 6.1 Base64-Encoding großer Dateien
**Problem:** Große Audio-Dateien (>10MB) können OutOfMemory-Fehler verursachen
**Lösung:**
- Dateigröße vor Upload prüfen (max. 25MB empfohlen)
- Streaming-Upload implementieren (falls nötig)
- Kompression erwägen (MP3 statt WAV bevorzugen)

### 6.2 API-Rate-Limits
**Problem:** OpenRouter hat Rate-Limits
**Lösung:**
- Retry-Logik mit exponential backoff
- User-Feedback bei Rate-Limit-Fehlern
- API-Antworten cachen (optional)

### 6.3 Audio-Format-Kompatibilität
**Problem:** Nicht alle Audio-Formate werden von Gemini unterstützt
**Lösung:**
- Nur unterstützte Formate im File-Picker erlauben
- Format-Konvertierung (falls nötig, z.B. mit FFmpeg)
- Klare Fehlermeldungen bei inkompatiblen Formaten

### 6.4 API-Key-Sicherheit
**Problem:** API-Keys sollten nicht im Code stehen
**Lösung:**
- FlutterSecureStorage verwenden (bereits geplant)
- User-Hinweise auf API-Key-Sicherheit
- Keine API-Keys in Git committen

---

## 7. Erweiterungsmöglichkeiten

### Stage 2: Prompt-Anwendung auf Transkriptionen (GEPLANT)

**Siehe detaillierte Pläne:**
- [stage2-extension-plan.md](stage2-extension-plan.md) - Basis-Features
- [stage2-additional-features.md](stage2-additional-features.md) - Erweiterte Features

**Kernfeatures (Basis):**
1. **Vordefinierte Prompts:** Zusammenfassen, Wichtige Punkte, Action Items
2. **Eigene Prompts:** Erstellen, bearbeiten, speichern
3. **Prompt auf Transkription anwenden** mit einem Klick
4. **Ergebnisanzeige:** Expandable Cards für Transkription + AI-Antwort
5. **Markdown-Rendering:** Schöne Formatierung der LLM-Antworten
6. **Kopieren & Teilen:** Beide Inhalte separat kopierbar

**Erweiterte Features:**
7. **Voice Recording:** Audio direkt in der App aufnehmen (statt nur Upload)
8. **LLM Streaming:** Antworten in Echtzeit sehen (Typewriter-Effekt)
9. **History-Funktion:** Alle Transkriptionen durchsuchen & wiederverwenden

**Entwicklungszeit:**
- Basis: 2,5 - 4 Stunden
- Erweitert (inkl. Recording, Streaming, History): 7-10,5 Stunden
- **TOTAL:** 10,5-16,5 Stunden (Stage 1 + Stage 2 komplett)

### Stage 3+: Weitere Ideen (nach MVP)

Falls Sie später noch mehr Features wollen:

1. **History-Funktion:** Vergangene Transkriptionen speichern
2. **Export:** Transkriptionen als TXT/JSON/PDF exportieren
3. **Batch-Processing:** Mehrere Dateien gleichzeitig transkribieren
4. **Offline-Modus:** Lokale Transkription mit On-Device-Modellen
5. **Cloud-Sync:** Transkriptionen in Cloud speichern
6. **Voice-Recording:** Direkt in der App aufnehmen
7. **Weitere Sprachen:** Alle von Gemini unterstützten Sprachen
8. **Model-Auswahl:** Zwischen verschiedenen OpenRouter-Modellen wählen
9. **LLM-Streaming:** Antwort in Echtzeit anzeigen (Typewriter-Effekt)
10. **Prompt-Sharing:** Prompts mit anderen Nutzern teilen

---

## 8. Zeitplan

**Geschätzte Gesamtzeit:** 3,5 - 6 Stunden

| Phase | Aufgabe | Zeit |
|-------|---------|------|
| 1 | Setup | 15-30 Min |
| 2 | Services | 60-90 Min |
| 3 | Models | 15-20 Min |
| 4 | UI Screens | 60-90 Min |
| 5 | Widgets | 30-45 Min |
| 6 | Testing & Polish | 30-45 Min |

**Optimistische Schätzung:** 3,5 Stunden
**Realistische Schätzung:** 4,5 Stunden
**Mit Puffer für Debugging:** 6 Stunden

---

## 9. Nächste Schritte

1. ✅ Dieser Plan wurde erstellt
2. ✅ Plan vom Benutzer bestätigt
3. ✅ Flutter-Projekt in `viosa/` initialisiert
4. ✅ Dependencies installiert
5. ⏳ Mit Phase 2 (Services) beginnen

---

**Erstellt mit:** Claude Code (Sonnet 4.5)
**Autor:** Claude
**Für:** VIOSA Audio Transcription App
