import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'providers/settings_provider.dart';
import 'providers/history_provider.dart';
import 'providers/prompts_provider.dart';
import 'providers/session_state_provider.dart';
import 'providers/split_transcription_provider.dart';
import 'services/settings_service.dart';
import 'services/history_service.dart';
import 'services/prompt_service.dart';
import 'services/recording_notification_service.dart';
import 'models/transcription_history.dart';
import 'models/transcription_result.dart';
import 'models/prompt_result.dart';
import 'models/audio_file.dart';
import 'models/prompt.dart';
import 'models/audio_split.dart';
import 'models/split_transcription_job.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable scheduler debug messages (suppresses "Queue jank" spam)
  debugPrintBeginFrameBanner = false;
  debugPrintEndFrameBanner = false;

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TranscriptionResultAdapter());
  Hive.registerAdapter(PromptResultAdapter());
  Hive.registerAdapter(TranscriptionHistoryAdapter());
  Hive.registerAdapter(AudioFileAdapter());
  Hive.registerAdapter(PromptAdapter());
  Hive.registerAdapter(SplitStatusAdapter());
  Hive.registerAdapter(AudioSplitAdapter());
  Hive.registerAdapter(JobStatusAdapter());
  Hive.registerAdapter(SplitTranscriptionJobAdapter());

  // Initialize all providers before app starts to ensure state is loaded
  final settingsProvider = SettingsProvider(SettingsService());
  final historyProvider = HistoryProvider(HistoryService());
  final promptsProvider = PromptsProvider(PromptService());
  final sessionStateProvider = SessionStateProvider();
  final splitTranscriptionProvider = SplitTranscriptionProvider();

  // Initialize notification service for recording indicator
  final notificationService = RecordingNotificationService();
  await notificationService.initialize();

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
    splitTranscriptionProvider: splitTranscriptionProvider,
  ));
}

class VIOSAApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final HistoryProvider historyProvider;
  final PromptsProvider promptsProvider;
  final SessionStateProvider sessionStateProvider;
  final SplitTranscriptionProvider splitTranscriptionProvider;

  const VIOSAApp({
    super.key,
    required this.settingsProvider,
    required this.historyProvider,
    required this.promptsProvider,
    required this.sessionStateProvider,
    required this.splitTranscriptionProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: promptsProvider),
        ChangeNotifierProvider.value(value: sessionStateProvider),
        ChangeNotifierProvider.value(value: splitTranscriptionProvider),
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
