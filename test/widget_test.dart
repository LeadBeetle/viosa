import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:viosa/providers/settings_provider.dart';
import 'package:viosa/providers/history_provider.dart';
import 'package:viosa/providers/prompts_provider.dart';
import 'package:viosa/providers/session_state_provider.dart';
import 'package:viosa/providers/split_transcription_provider.dart';
import 'package:viosa/services/settings_service.dart';
import 'package:viosa/services/history_service.dart';
import 'package:viosa/services/prompt_service.dart';
import 'package:viosa/screens/home_screen.dart';
import 'package:viosa/utils/constants.dart';
import 'package:viosa/models/transcription_history.dart';
import 'package:viosa/models/transcription_result.dart';
import 'package:viosa/models/prompt_result.dart';
import 'package:viosa/models/audio_file.dart';
import 'package:viosa/models/prompt.dart';
import 'package:viosa/models/audio_split.dart';
import 'package:viosa/models/split_transcription_job.dart';
import 'package:viosa/models/speaker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Hive.init('./test/hive_test');
    Hive.registerAdapter(SpeakerAdapter());
    Hive.registerAdapter(TranscriptionResultAdapter());
    Hive.registerAdapter(PromptResultAdapter());
    Hive.registerAdapter(TranscriptionHistoryAdapter());
    Hive.registerAdapter(AudioFileAdapter());
    Hive.registerAdapter(PromptAdapter());
    Hive.registerAdapter(SplitStatusAdapter());
    Hive.registerAdapter(AudioSplitAdapter());
    Hive.registerAdapter(JobStatusAdapter());
    Hive.registerAdapter(SplitTranscriptionJobAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('Home screen renders with providers', (WidgetTester tester) async {
    final settingsProvider = SettingsProvider(SettingsService());
    final historyProvider = HistoryProvider(HistoryService());
    final promptsProvider = PromptsProvider(PromptService());
    final sessionStateProvider = SessionStateProvider();
    final splitTranscriptionProvider = SplitTranscriptionProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: historyProvider),
          ChangeNotifierProvider.value(value: promptsProvider),
          ChangeNotifierProvider.value(value: sessionStateProvider),
          ChangeNotifierProvider.value(value: splitTranscriptionProvider),
        ],
        child: const MaterialApp(
          title: AppConstants.appName,
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
