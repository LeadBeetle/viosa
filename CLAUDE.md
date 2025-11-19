# CLAUDE.md - VIOSA Project Guidelines

## Project Overview

VIOSA (Voice Intelligent Output and Speech Analyzer) is an Android application for audio transcription using the OpenRouter API with Gemini models. Built with Flutter/Dart.

**Key Features:**
- Audio file transcription (MP3, WAV, MP4, M4A)
- Voice recording with live transcription
- Prompt-based text processing
- History management

## Quick Commands

```bash
# Generate Hive adapters after modifying models
flutter pub run build_runner build --delete-conflicting-outputs

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

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
- UI strings are in German
- Keep language consistent across the app

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
