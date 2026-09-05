import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/prompts_screen.dart';
import 'utils/constants.dart';
import 'utils/app_theme.dart';
import 'generated/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'providers/history_provider.dart';
import 'providers/prompts_provider.dart';
import 'providers/split_transcription_provider.dart';
import 'services/settings_service.dart';
import 'services/history_service.dart';
import 'services/prompt_service.dart';
import 'services/recording_notification_service.dart';
import 'services/audio_splitter_service.dart';
import 'models/transcription_history.dart';
import 'models/transcription_result.dart';
import 'models/prompt_result.dart';
import 'models/audio_file.dart';
import 'models/prompt.dart';
import 'models/audio_split.dart';
import 'models/split_transcription_job.dart';
import 'models/speaker.dart';
import 'models/transcript_segment.dart';
import 'models/chat_message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable scheduler debug messages (suppresses "Queue jank" spam)
  debugPrintBeginFrameBanner = false;
  debugPrintEndFrameBanner = false;

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(SpeakerAdapter());
  Hive.registerAdapter(TranscriptSegmentAdapter());
  Hive.registerAdapter(TranscriptionResultAdapter());
  Hive.registerAdapter(PromptResultAdapter());
  Hive.registerAdapter(TranscriptionHistoryAdapter());
  Hive.registerAdapter(AudioFileAdapter());
  Hive.registerAdapter(PromptAdapter());
  Hive.registerAdapter(SplitStatusAdapter());
  Hive.registerAdapter(AudioSplitAdapter());
  Hive.registerAdapter(JobStatusAdapter());
  Hive.registerAdapter(SplitTranscriptionJobAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  // Initialize all providers before app starts to ensure state is loaded
  final settingsProvider = SettingsProvider(SettingsService());
  final historyProvider = HistoryProvider(HistoryService());
  final promptsProvider = PromptsProvider(PromptService());
  final splitTranscriptionProvider = SplitTranscriptionProvider();

  // Initialize notification service for recording indicator
  final notificationService = RecordingNotificationService();
  await notificationService.initialize();

  // Wait for all providers to initialize before rendering UI
  await Future.wait([
    settingsProvider.initialize(),
    historyProvider.initialize(),
    promptsProvider.initialize(),
  ]);

  // Cleanup orphaned split files from previous sessions
  AudioSplitterService().cleanupAllSplits();

  runApp(VIOSAApp(
    settingsProvider: settingsProvider,
    historyProvider: historyProvider,
    promptsProvider: promptsProvider,
    splitTranscriptionProvider: splitTranscriptionProvider,
  ));
}

class VIOSAApp extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final HistoryProvider historyProvider;
  final PromptsProvider promptsProvider;
  final SplitTranscriptionProvider splitTranscriptionProvider;

  const VIOSAApp({
    super.key,
    required this.settingsProvider,
    required this.historyProvider,
    required this.promptsProvider,
    required this.splitTranscriptionProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: promptsProvider),
        ChangeNotifierProvider.value(value: splitTranscriptionProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeScreen(),
            routes: {
              '/prompts': (context) => const PromptsScreen(),
            },
          );
        },
      ),
    );
  }
}
