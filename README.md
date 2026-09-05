# VIOSA - Audio Transcription App

VIOSA is a Flutter app for audio transcription using the OpenRouter API. Android is the primary target; iOS, macOS, Windows, Linux and web build directories exist (see [macOS/iOS deployment](docs/DEPLOYMENT_MACOS_IOS.md)).

Models are defined in one place, `lib/repositories/model_repository.dart`: `google/gemini-3.8-flash` for LLM work (prompts, chat, speaker context, transcription post-processing) and `microsoft/mai-transcribe-2` for speech-to-text.

## Features

- Audio file selection (MP3, WAV, MP4, M4A)
- Audio playback
- Audio transcription via OpenRouter API (segment timestamps, automatic language identification, keyword biasing, verbatim or clean style)
- Voice recording with live transcription (foreground service, survives screen off)
- Long-recording splitting and per-chunk transcription
- Prompt-based text processing and chat over a transcript
- Speaker diarization from the transcription model, speaker extraction and speaker context
- Transcription keeps running in the background when the session screen is closed
- Timestamp list with jump-to-position playback
- History search, management and export/sharing (Markdown or SRT subtitles)
- Secure API key storage
- Language selection (German, English, Auto-detect)
- Localized UI (German, English)

## Prerequisites

- Flutter SDK with Dart SDK ^3.10.0
- Android Studio with Android SDK
- Android emulator or physical Android device
- An [OpenRouter](https://openrouter.ai/) API key

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Start the Android Emulator

Start your Android emulator from Android Studio, or use the command line:

```bash
flutter emulators --launch Medium_Phone_API_36.1
```

To see all available emulators:

```bash
flutter emulators
```

### 3. Run the Application with Hot Reload

To run the app on the emulator with hot reload enabled:

```bash
flutter run
```

Or to run on a specific device:

```bash
flutter devices                    # List all connected devices
flutter run -d <device-id>        # Run on specific device
```

### Hot Reload Commands

While the app is running, you can use these keyboard shortcuts:

- **`r`** - Hot reload (reload code changes instantly)
- **`R`** - Hot restart (restart the entire app)
- **`h`** - List all available interactive commands
- **`d`** - Detach (keep app running but stop flutter run)
- **`c`** - Clear the screen
- **`q`** - Quit (terminate the application)

### Development Workflow

1. Start the emulator
2. Run `flutter run` from the `viosa` directory
3. Make changes to your code
4. Press `r` in the terminal to hot reload your changes
5. The app will update instantly on the emulator

### Checks and Code Generation

```bash
flutter analyze          # must be clean
flutter test

# Regenerate Hive adapters after changing a model in lib/models/
dart run build_runner build --delete-conflicting-outputs

# Regenerate localizations after editing lib/l10n/*.arb
flutter gen-l10n
```

## Project Structure

```
viosa/
├── lib/
│   ├── main.dart                      # App entry point, provider wiring
│   ├── models/                        # Hive-annotated data models (+ .g.dart)
│   ├── providers/                     # ChangeNotifier state
│   ├── repositories/                  # model_repository.dart: model IDs
│   ├── services/                      # Business logic (i_*.dart interface per service)
│   │   ├── completion/                # LLM completion (OpenRouter)
│   │   ├── transcription/             # Speech-to-text
│   │   └── export/                    # Export formatters
│   ├── screens/                       # UI screens
│   ├── dialogs/                       # Dialogs
│   ├── widgets/                       # Reusable UI components
│   ├── mixins/                        # Shared widget behavior
│   ├── l10n/                          # ARB translation sources
│   ├── generated/                     # Generated AppLocalizations
│   └── utils/                         # Theme, constants, helpers
├── android/                           # Android-specific configuration
├── ios/ macos/ windows/ linux/ web/   # Other platform targets
├── docs/                              # Deployment documentation
├── thoughts/                          # Planning documentation
└── pubspec.yaml                       # Dependencies
```

## Configuration

Before using the app, you'll need to:

1. Get an API key from [OpenRouter](https://openrouter.ai/)
2. Enter the API key in the app's Settings screen
3. Select your preferred transcription language

## Development

For detailed implementation plans and architecture documentation, see:
- [Implementation Plan](thoughts/implementation-plan.md)
- [Project guidelines for contributors and Claude Code](CLAUDE.md)
- [UI/UX guidelines and design tokens](docs/UI_GUIDELINES.md)

UI strings are not hardcoded: add a key to both `lib/l10n/app_de.arb` and
`lib/l10n/app_en.arb`, run `flutter gen-l10n`, then read it via `context.l10n.<key>`.

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [OpenRouter API Documentation](https://openrouter.ai/docs)
