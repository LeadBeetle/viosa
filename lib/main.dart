import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'providers/settings_provider.dart';
import 'providers/history_provider.dart';
import 'providers/prompts_provider.dart';
import 'providers/session_state_provider.dart';
import 'services/settings_service.dart';
import 'services/history_service.dart';
import 'services/prompt_service.dart';
import 'models/transcription_history.dart';
import 'models/transcription_result.dart';
import 'models/prompt_result.dart';
import 'models/audio_file.dart';
import 'models/prompt.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TranscriptionResultAdapter());
  Hive.registerAdapter(PromptResultAdapter());
  Hive.registerAdapter(TranscriptionHistoryAdapter());
  Hive.registerAdapter(AudioFileAdapter());
  Hive.registerAdapter(PromptAdapter());

  // Initialize all providers before app starts to ensure state is loaded
  final settingsProvider = SettingsProvider(SettingsService());
  final historyProvider = HistoryProvider(HistoryService());
  final promptsProvider = PromptsProvider(PromptService());
  final sessionStateProvider = SessionStateProvider();

  // Wait for all providers to initialize before rendering UI
  await Future.wait([
    settingsProvider.initialize(),
    historyProvider.initialize(),
    promptsProvider.initialize(),
    sessionStateProvider.initialize(),
  ]);

  runApp(VIOSAApp(
    settingsProvider: settingsProvider,
    historyProvider: historyProvider,
    promptsProvider: promptsProvider,
    sessionStateProvider: sessionStateProvider,
  ));
}

class VIOSAApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final HistoryProvider historyProvider;
  final PromptsProvider promptsProvider;
  final SessionStateProvider sessionStateProvider;

  const VIOSAApp({
    super.key,
    required this.settingsProvider,
    required this.historyProvider,
    required this.promptsProvider,
    required this.sessionStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: promptsProvider),
        ChangeNotifierProvider.value(value: sessionStateProvider),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primaryColor),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
