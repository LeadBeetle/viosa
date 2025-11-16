# VIOSA - Planungs-Dokumentation
## Audio-Transkriptions-App mit Flutter

**Erstellt:** 2025-11-15
**Framework:** Flutter
**Zielplattform:** Android 14 (Genymotion)

---

## 📚 Dokumentations-Übersicht

Diese Planungsphase enthält **3 detaillierte Dokumente**:

### 1. [implementation-plan.md](implementation-plan.md) ⭐ **START HIER**
**Stage 1: Basis-App (MVP)**

Der Haupt-Implementierungsplan für die grundlegende Audio-Transkriptions-App.

**Enthält:**
- ✅ Flutter-Projekt-Setup
- ✅ Audio-Datei-Upload (MP3/WAV/MP4)
- ✅ Audio-Player mit Wiedergabe-Kontrollen
- ✅ OpenRouter-Integration (Gemini Flash 2.5)
- ✅ Audio-Transkription (Deutsch/Englisch/Auto-Detect)
- ✅ Settings-Screen (API-Key-Verwaltung)
- ✅ Komplette Code-Beispiele für alle Services
- ✅ Phase-für-Phase Checklisten

**Entwicklungszeit:** 3,5-6 Stunden

**Status:** ✅ Vollständig geplant, bereit zur Implementierung

---

### 2. [stage2-extension-plan.md](stage2-extension-plan.md)
**Stage 2: Prompt-Anwendung (Basis)**

Erweiterte Features für die Anwendung von Prompts auf Transkriptionen.

**Enthält:**
- ✅ UX-Research-Ergebnisse (Material Design 3, Mobile Best Practices)
- ✅ Vordefinierte Prompts (Zusammenfassen, Key Points, Action Items)
- ✅ Custom Prompt Management (CRUD)
- ✅ Modal Bottom Sheet mit Choice Chips für Prompt-Auswahl
- ✅ Results Screen mit Expandable Cards
- ✅ Markdown-Rendering (gpt_markdown)
- ✅ Copy & Share für beide Inhalte
- ✅ Vollständige Code-Beispiele
- ✅ UX-Design-Entscheidungen mit Begründungen

**Entwicklungszeit:** 2,5-4 Stunden

**Status:** ✅ Vollständig geplant

---

### 3. [stage2-additional-features.md](stage2-additional-features.md) 🆕
**Stage 2: Erweiterte Features**

Drei zusätzliche High-Impact Features für Stage 2.

**Feature 1: Voice Recording** (1,5-2h)
- Direkte Audio-Aufnahme in der App
- Waveform-Visualisierung während Aufnahme
- Pause/Resume/Stop-Funktionalität
- Speichern & direkt transkribieren
- Vollständige RecordingService & RecordingScreen Implementierung

**Feature 2: LLM Streaming** (1-1,5h)
- Echtzeit-Antworten (Typewriter-Effekt wie ChatGPT)
- Blinkender Cursor während Streaming
- Pause/Stop-Controls für Stream
- OpenRouter SSE (Server-Sent Events) Integration
- StreamingTextWidget mit Animation

**Feature 3: History-Funktion** (2-3h)
- SQLite-Datenbank für lokale Speicherung
- Suche & Filter (Datum, Stichwörter)
- Transkription-Details mit allen angewendeten Prompts
- Swipe-to-Delete mit Undo
- HistoryService mit vollem CRUD
- HistoryScreen & HistoryDetailScreen

**Entwicklungszeit:** 4,5-6,5 Stunden

**Status:** ✅ Vollständig geplant mit Code-Beispielen

---

## 🎯 Gesamtübersicht

### Vollständiger Feature-Umfang

**Stage 1 (MVP):**
1. Audio-Datei-Upload (MP3/WAV/MP4)
2. Audio-Player
3. Audio-Transkription (Gemini Flash 2.5)
4. API-Key-Verwaltung
5. Sprachauswahl (DE/EN/Auto)

**Stage 2 (Erweitert):**
6. Vordefinierte Prompts
7. Custom Prompt Management
8. Prompt-Anwendung auf Transkriptionen
9. Markdown-Rendering
10. Copy & Share
11. **Voice Recording** 🎤
12. **LLM Streaming** ⚡
13. **History-Funktion** 📚

### Zeitplan

| Phase | Umfang | Zeit |
|-------|--------|------|
| **Stage 1** | MVP (Features 1-5) | 3,5-6h |
| **Stage 2 Basis** | Prompts & Markdown (Features 6-10) | 2,5-4h |
| **Stage 2 Erweitert** | Recording, Streaming, History (11-13) | 4,5-6,5h |
| **TOTAL** | Alle 13 Features | **10,5-16,5h** |

### Empfohlene Umsetzung (3 Sprints)

#### Sprint 1: MVP (Stage 1) - 3,5-6h
**Ziel:** Funktionierende Basis-App
- Flutter-Projekt aufsetzen
- Audio-Upload implementieren
- Audio-Player erstellen
- OpenRouter-Integration
- Transkription implementieren
- Settings-Screen

**Ergebnis:** App kann Audio-Dateien transkribieren ✅

---

#### Sprint 2: Prompts (Stage 2 Basis) - 2,5-4h
**Ziel:** Prompt-Anwendung auf Transkriptionen
- Prompt-Models & Service
- Bottom Sheet mit Chip-Auswahl
- Custom Prompt Management
- Results Screen mit Expandable Cards
- Markdown-Rendering
- Copy & Share

**Ergebnis:** App kann Prompts auf Transkriptionen anwenden ✅

---

#### Sprint 3: Erweiterte Features - 4,5-6,5h
**Ziel:** Professionelle User Experience

**Phase A: LLM Streaming** (1-1,5h) - Hoher Impact, leicht
- OpenRouter SSE-Integration
- StreamingTextWidget
- Cursor-Animation

**Phase B: History** (2-3h) - Wichtig für Produktivität
- SQLite-Setup
- HistoryService
- HistoryScreen mit Suche

**Phase C: Voice Recording** (1,5-2h) - Optional, aber praktisch
- RecordingService
- RecordingScreen mit Waveform
- Integration in Upload-Flow

**Ergebnis:** Vollständige, produktionsreife App ✅

---

## 🛠 Technologie-Stack

### Flutter Packages

```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter

  # Audio
  just_audio: ^0.9.36           # Audio-Wiedergabe
  record: ^5.0.4                # Audio-Aufnahme
  audio_waveforms: ^1.0.5       # Waveform-Visualisierung

  # Files
  file_picker: ^6.1.1           # Dateiauswahl
  path_provider: ^2.1.1         # Pfade

  # Network
  dio: ^5.4.0                   # HTTP-Client

  # Storage
  flutter_secure_storage: ^9.0.0  # API-Keys
  sqflite: ^2.3.0               # History-Datenbank

  # UI
  gpt_markdown: ^0.8.0          # Markdown-Rendering
  share_plus: ^7.2.1            # Native Share
  url_launcher: ^6.2.2          # Links öffnen
  flutter_spinkit: ^5.2.0       # Ladeanimationen

  # State Management
  provider: ^6.1.1

  # Utilities
  uuid: ^4.2.2                  # Unique IDs
  path: ^1.8.3
  mime: ^1.0.4
```

### API & Services
- **OpenRouter:** https://openrouter.ai/api/v1
- **Model:** google/gemini-flash-1.5 (oder gemini-2.0-flash-exp)
- **Audio-Formate:** MP3, WAV, MP4, M4A
- **Transkriptions-Sprachen:** Deutsch, Englisch, Auto-Detect

---

## 📋 Architektur-Überblick

### Ordnerstruktur (Final)

```
viosa/
├── lib/
│   ├── main.dart
│   │
│   ├── models/
│   │   ├── audio_file.dart
│   │   ├── transcription_result.dart
│   │   ├── prompt.dart
│   │   ├── prompt_application_result.dart
│   │   ├── history_entry.dart
│   │   └── recording_state.dart
│   │
│   ├── services/
│   │   ├── openrouter_service.dart       # Transkription + Streaming
│   │   ├── audio_service.dart            # Wiedergabe
│   │   ├── recording_service.dart        # Aufnahme
│   │   ├── file_service.dart             # Upload
│   │   ├── prompt_service.dart           # Prompt-Management
│   │   ├── settings_service.dart         # Einstellungen
│   │   └── history_service.dart          # Datenbank
│   │
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── results_screen.dart
│   │   ├── recording_screen.dart
│   │   ├── custom_prompt_screen.dart
│   │   ├── prompt_library_screen.dart
│   │   └── history_screen.dart
│   │
│   ├── widgets/
│   │   ├── audio_player_widget.dart
│   │   ├── file_info_card.dart
│   │   ├── expandable_card.dart
│   │   ├── prompt_selector_bottom_sheet.dart
│   │   ├── streaming_text_widget.dart
│   │   ├── recording_controls_widget.dart
│   │   ├── waveform_widget.dart
│   │   └── history_list_item.dart
│   │
│   └── utils/
│       ├── constants.dart
│       ├── audio_converter.dart
│       └── database_helper.dart
│
├── android/
│   └── app/src/main/AndroidManifest.xml  # Berechtigungen
│
├── pubspec.yaml
└── thoughts/                              # Diese Dokumentation
    ├── README.md                          # ← Du bist hier
    ├── implementation-plan.md
    ├── stage2-extension-plan.md
    └── stage2-additional-features.md
```

---

## 🎨 Design-Prinzipien

### Material Design 3
- **useMaterial3: true** in ThemeData
- Elevated/Outlined/Filled Cards
- Choice Chips für Auswahl
- Modal Bottom Sheets für Kontext-Aktionen
- Expandable Cards (Accordion)

### Mobile UX Best Practices
- **48dp** Minimum Touch Targets
- **Progressive Disclosure** (Features zur richtigen Zeit zeigen)
- **Immediate Feedback** (< 100ms Reaktionszeit)
- **Familiar Patterns** (System-native Gesten)

### Accessibility
- Screen Reader Support
- Color Contrast 4.5:1+
- Scalable Text
- Haptic Feedback

---

## 🚀 Nächste Schritte

### Option 1: Alles auf einmal (10,5-16,5h)
Implementiere alle 3 Sprints nacheinander für eine vollständige App.

**Vorteile:**
- Keine technische Schuld
- Konsistente Architektur
- Alle Features von Anfang an

**Nachteile:**
- Längere Zeit bis zum ersten funktionierenden Prototyp
- Höheres Risiko bei Architektur-Fehlern

---

### Option 2: Iterativ (empfohlen)
Implementiere Sprint für Sprint, teste nach jedem Sprint.

**Sprint 1 → Testen → Sprint 2 → Testen → Sprint 3**

**Vorteile:**
- Schnelles Feedback
- Frühzeitige Fehlererkennung
- Motivierender durch sichtbare Fortschritte
- Flexibilität (kann nach jedem Sprint pausieren)

**Nachteile:**
- Möglicherweise Refactoring zwischen Sprints

---

### Option 3: MVP-First
Nur Sprint 1, dann entscheiden.

**Vorteile:**
- Minimale Investition für funktionierenden Prototyp
- Kann Technologie-Entscheidungen validieren
- Frühe Demo möglich

**Nachteile:**
- Mehrere Implementierungs-Phasen
- Eventuell Architektur-Anpassungen später

---

## 💡 Empfehlung

**Für Ihr Projekt (schnelle Entwicklung, Prototyp):**

➡️ **Option 2: Iterativ**

**Begründung:**
1. Sie haben klare Zeitfenster (3,5-6h pro Sprint)
2. Sie können nach jedem Sprint auf Genymotion testen
3. UX-Feedback kann noch einfließen
4. Sie haben Flexibilität (z.B. Voice Recording weglassen wenn Zeit knapp)

**Konkrete Umsetzung:**
- **Tag 1:** Sprint 1 (MVP) → Testen
- **Tag 2:** Sprint 2 (Prompts) → Testen
- **Tag 3:** Sprint 3 (Advanced) → Finalisieren

**Oder in einem Tag:**
- **Vormittag (4h):** Sprint 1
- **Nachmittag (4h):** Sprint 2
- **Abend (2h):** Sprint 3 (nur LLM Streaming + History, Voice Recording weglassen)

---

## 📞 Support & Ressourcen

### Dokumentation
- Flutter Docs: https://docs.flutter.dev/
- Material Design 3: https://m3.material.io/
- OpenRouter API: https://openrouter.ai/docs

### Packages
- just_audio: https://pub.dev/packages/just_audio
- gpt_markdown: https://pub.dev/packages/gpt_markdown
- record: https://pub.dev/packages/record
- sqflite: https://pub.dev/packages/sqflite

### Community
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: [flutter] tag

---

## ✅ Bereit zur Implementierung?

Alle Pläne sind vollständig! Sie können jetzt:

1. ✅ Plan reviewed und verstanden
2. ⏭️ **NÄCHSTER SCHRITT:** Plan-Mode beenden & mit Implementierung starten
3. ⏭️ Flutter-Projekt erstellen in `viosa/`
4. ⏭️ Dependencies installieren
5. ⏭️ Sprint 1 beginnen (Stage 1: MVP)

**Viel Erfolg! 🚀**

---

**Erstellt mit:** Claude Code (Sonnet 4.5)
**Datum:** 2025-11-15
**Gesamt-Dokumentation:** ~150 Seiten detaillierte Planung
