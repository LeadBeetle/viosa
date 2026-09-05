# CLAUDE.md - VIOSA Project Guidelines

## Project Overview

VIOSA (Voice Intelligent Output and Speech Analyzer) is a Flutter app for audio transcription via the OpenRouter API. Android is the primary target; iOS, macOS, Windows, Linux and web build directories exist (see `docs/DEPLOYMENT_MACOS_IOS.md`).

**Key Features:**
- Audio file transcription (MP3, WAV, MP4, M4A) with segment timestamps, speaker diarization, language identification and keyword biasing
- Voice recording with live transcription
- Prompt-based text processing
- History management

## Git Workflow

- **Work exclusively from `main`.** Start every change from an up-to-date `main` and commit there; do not open long-lived feature branches.
- Pull `main` before starting work and push `main` when the change is done.

## Quick Commands

```bash
flutter pub get
flutter analyze          # flutter_lints 6.0, must be clean
flutter test

# Generate Hive adapters after modifying models
dart run build_runner build --delete-conflicting-outputs

# Regenerate localizations after editing lib/l10n/*.arb
flutter gen-l10n

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

## Directory Map

- `lib/services/` — flat services plus `completion/`, `transcription/`, `export/` sub-layers, each with an `i_*.dart` interface
- `lib/providers/` — 5 ChangeNotifiers; 4 wired in `main.dart` MultiProvider, `ChatProvider` created locally in `lib/screens/chat_screen.dart`
- `lib/repositories/model_repository.dart` — model IDs (see Models)
- `lib/utils/constants.dart`, `app_theme.dart` — design tokens (see `docs/UI_GUIDELINES.md`)

## Models

`ModelRepository` is the only place model IDs live. LLM (prompts, chat, speaker context, post-processing): `google/gemini-3.8-flash`. Speech-to-text: `microsoft/mai-transcribe-2`. Never hardcode a model ID elsewhere.

The transcription request asks MAI-Transcribe 2 for `response_format: verbose_json` with segment timestamps, and passes the Azure provider options for diarization, keyword biasing (`phraseList`) and transcript style. Provider-side speaker labels replace the LLM diarization pass; the LLM clean-up only runs for the `clean` style without labels.

## Architecture Principles

### State Management
- Use **Provider** pattern with `ChangeNotifier`
- Access state via `Provider.of<T>()` or `Consumer<T>` widgets
- Keep providers focused on single responsibility

### Service Layer (SOLID Principles)
- **Always create an abstract interface first**, then implement it
- Services handle business logic, providers handle state
- Inject dependencies through constructors for testability

```dart
// Pattern to follow
abstract class IExampleService {
  Future<void> doSomething();
}

class ExampleService implements IExampleService {
  @override
  Future<void> doSomething() {
    // Implementation
  }
}
```

### Data Access
- Use **Repository pattern** for data sources
- Use **Factory pattern** for creating provider instances

## Code Style Guidelines

### Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/Methods: `camelCase`
- Private members: prefix with underscore `_privateField`
- Constants: `static const` with descriptive names

### Documentation
- Use `///` doc comments for public APIs
- Never add inline comments

### Widget Patterns
- Check `mounted` before `setState` in async operations
- Always implement `dispose()` for controllers and streams
- Prefer `StatelessWidget` when no local state needed

## Design Patterns

### Error Handling
- Create custom exception classes for specific error types
- Catch exceptions and show user-friendly messages via snackbar service
- Use `debugPrint` for non-critical silent failures

### Async Patterns
- Use `async/await` consistently
- Handle loading states in providers with `_isLoading` flag
- Notify listeners after state changes

### UI Patterns
- Follow Material Design 3 guidelines
- Use centralized constants for padding, colors, border radius
- Card-based layouts with consistent elevation
- Snackbar service for user notifications

## Key Conventions

### Data Persistence
- **Hive** for local storage (history, session state, prompts)
- Models require `@HiveType` and `@HiveField` annotations
- Regenerate adapters after modifying model fields
- **Secure storage** for sensitive data (API keys)

### API Integration
- Use SSE (Server-Sent Events) for streaming LLM responses
- Handle authentication errors with specific exception types
- Implement retry logic for transient failures

### Localization
- ARB-based: `lib/l10n/app_de.arb` (template) and `app_en.arb`, generated into `lib/generated/`
- Never hardcode UI strings. Add a key to both ARB files, run `flutter gen-l10n`, read via `context.l10n.<key>` (extension in `lib/l10n/l10n.dart`)
- German is the template locale; docs and code comments follow suit

## Gotchas

- **Hive typeIds in use: 0–11. Next free: 12.** Reusing an id corrupts stored data silently.
- `permission_handler` pinned to ^12: 13.x pulls permission_handler_android 14, which needs AGP 9 / compileSdk 37.
- UI design tokens (`AppSpacing`, `AppOpacity`, `AppIconSize`) documented in `docs/UI_GUIDELINES.md` — use them, don't invent values.

## Development Guidelines

### Adding New Features
1. Define the interface first
2. Implement the service
3. Create or update provider if state is needed
4. Build UI components
5. Run code generation if Hive models changed

### Permissions
- Request permissions at point of use
- Handle permission denial gracefully with user feedback
- Audio recording requires microphone permission
