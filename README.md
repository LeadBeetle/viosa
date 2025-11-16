# VIOSA - Audio Transcription App

VIOSA is a Flutter-based Android application for audio transcription using the OpenRouter API with Gemini Flash 2.5.

## Features

- Audio file selection (MP3, WAV, MP4, M4A)
- Audio playback
- Audio transcription via OpenRouter API
- Secure API key storage
- Language selection (German, English, Auto-detect)

## Prerequisites

- Flutter SDK (3.10.0 or higher)
- Android Studio with Android SDK
- Android emulator or physical Android device

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

## Project Structure

```
viosa/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── models/                        # Data models
│   ├── services/                      # Business logic
│   ├── screens/                       # UI screens
│   ├── widgets/                       # Reusable UI components
│   └── utils/                         # Helper functions
├── android/                           # Android-specific configuration
├── thoughts/                          # Documentation
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

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [OpenRouter API Documentation](https://openrouter.ai/docs)
