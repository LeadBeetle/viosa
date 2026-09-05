// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get start => 'Start';

  @override
  String get choose => 'Choose';

  @override
  String get example => 'Example';

  @override
  String get noRecordings => 'No Recordings';

  @override
  String get noRecordingsSubtitle => 'Start a new recording with the + button';

  @override
  String get deleteRecording => 'Delete Recording';

  @override
  String deleteConfirmation(String name) {
    return 'Do you really want to delete \"$name\"?';
  }

  @override
  String get recordingRenamed => 'Recording renamed';

  @override
  String get recordingDeleted => 'Recording deleted';

  @override
  String get managePrompts => 'Manage Prompts';

  @override
  String get selectFile => 'Select File';

  @override
  String get recording => 'Recording';

  @override
  String get renameRecording => 'Rename';

  @override
  String get name => 'Name';

  @override
  String get newName => 'New name';

  @override
  String get noAudioPath => 'No audio path available';

  @override
  String get audioFileNotFound => 'Audio file not found';

  @override
  String get apiConfiguration => 'API Configuration';

  @override
  String get apiKeyLabel => 'OpenRouter API Key';

  @override
  String get apiKeyHint => 'sk-or-v1-...';

  @override
  String get apiKeyHelp => 'Get your API key from';

  @override
  String get showApiKey => 'Show API key';

  @override
  String get hideApiKey => 'Hide API key';

  @override
  String get pleaseEnterApiKey => 'Please enter an API key';

  @override
  String get configureApiKey => 'Please configure API key';

  @override
  String get modelsSectionTitle => 'Models';

  @override
  String get speechToTextModelLabel => 'Speech recognition';

  @override
  String get languageModelLabel => 'Language model';

  @override
  String get aiModel => 'AI Model';

  @override
  String get audioTranscription => 'Audio & Transcription';

  @override
  String get storageLocation => 'Storage Location for Recordings';

  @override
  String get defaultStorageLocation => 'Default storage location';

  @override
  String get transcriptionLanguage => 'Language';

  @override
  String get transcriptionLanguageDescription =>
      'Select the language for transcription';

  @override
  String get transcriptionLanguageAuto => 'Auto-Detect';

  @override
  String get transcriptionLanguageGerman => 'German';

  @override
  String get transcriptionLanguageEnglish => 'English';

  @override
  String get speakerDiarization => 'Speaker Recognition';

  @override
  String get speakerDiarizationDescription =>
      'The model labels different speakers directly in the transcript';

  @override
  String get uiLanguage => 'App Language';

  @override
  String get uiLanguageDescription => 'Select the user interface language';

  @override
  String get languageGerman => 'German';

  @override
  String get languageEnglish => 'English';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDescription => 'Select the app\'s color scheme';

  @override
  String get promptsManage => 'Manage Prompts';

  @override
  String get promptsDescription => 'Create and edit your AI prompts';

  @override
  String get aboutViosa => 'About VIOSA';

  @override
  String get aboutDescription =>
      'VIOSA (Voice Intelligent Output and Speech Analyzer) uses the OpenRouter API for audio transcription with cutting-edge AI models.';

  @override
  String get apiKeySecurityNote =>
      'Your API key is securely stored on your device and never shared with third parties.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get prompts => 'Prompts';

  @override
  String get customPrompts => 'Custom';

  @override
  String customPromptsCount(int count) {
    return 'Custom ($count)';
  }

  @override
  String standardPromptsCount(int count) {
    return 'Standard ($count)';
  }

  @override
  String get noCustomPrompts => 'No custom prompts yet';

  @override
  String get noCustomPromptsSubtitle =>
      'Create custom prompts for your transcriptions';

  @override
  String get createPrompt => 'Create Prompt';

  @override
  String get newPrompt => 'New Prompt';

  @override
  String get deletePrompt => 'Delete Prompt';

  @override
  String get promptSaved => 'Prompt saved successfully';

  @override
  String get promptDeleted => 'Prompt deleted';

  @override
  String get noPredefinedPrompts => 'No predefined prompts available';

  @override
  String get editPrompt => 'Edit Prompt';

  @override
  String get promptName => 'Prompt Name';

  @override
  String get promptNameHint => 'e.g. Summarize';

  @override
  String get enterNameRequired => 'Please enter a name';

  @override
  String get advancedOptions => 'Advanced Options';

  @override
  String get manualTranscriptionPlacement => 'Manual transcription placement';

  @override
  String get autoTranscriptionPlacement =>
      'Transcription is automatically appended at the end';

  @override
  String get insertTranscription => 'Insert Transcription';

  @override
  String get promptTemplate => 'Prompt Template';

  @override
  String promptTemplateHintAdvanced(Object transcription) {
    return 'Use the button above to insert \'\'$transcription\'\'';
  }

  @override
  String get promptTemplateHintSimple =>
      'Describe what should be done with the transcription';

  @override
  String get enterTemplateRequired => 'Please enter a template';

  @override
  String transcriptionPlaceholderFound(Object transcription) {
    return '\'\'$transcription\'\' found';
  }

  @override
  String transcriptionPlacementHintAdvanced(Object transcription) {
    return 'Use \'\'$transcription\'\' where the text should be inserted';
  }

  @override
  String get transcriptionPlacementHintSimple =>
      'The transcription will be automatically appended to your prompt';

  @override
  String get sessionDiscardTitle => 'Discard current session?';

  @override
  String get sessionDiscardMessage =>
      'You have already selected or transcribed an audio file. Do you want to discard this session and start a new one?';

  @override
  String get startNewSession => 'Start New Session';

  @override
  String get startTranscription => 'Start Transcription';

  @override
  String get warningExistingData =>
      'Warning: Existing transcription, prompt results and chat history will be deleted.';

  @override
  String audioDurationDescription(String duration) {
    return 'This audio file is $duration long.';
  }

  @override
  String modelLabel(String modelName) {
    return 'Model: $modelName';
  }

  @override
  String get newRecording => 'New Recording';

  @override
  String get transcriptionFailed => 'Transcription failed';

  @override
  String get startChat => 'Start Chat';

  @override
  String get chat => 'Chat';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get clearChatConfirmTitle => 'Clear chat?';

  @override
  String get clearChatConfirmMessage =>
      'Do you want to delete the entire chat history? This action cannot be undone.';

  @override
  String get startChatTitle => 'Start a Chat';

  @override
  String get startChatDescription =>
      'Ask questions about the transcript or use @Transcript to reference it.';

  @override
  String get apiKeyNotConfigured => 'API key not configured';

  @override
  String get recordingNotFound => 'Recording not found';

  @override
  String errorPlaying(String error) {
    return 'Error playing: $error';
  }

  @override
  String errorRenaming(String error) {
    return 'Error renaming: $error';
  }

  @override
  String errorDeleting(String error) {
    return 'Error deleting: $error';
  }

  @override
  String errorSavingLanguage(String error) {
    return 'Error saving language: $error';
  }

  @override
  String errorSavingTheme(String error) {
    return 'Error saving theme: $error';
  }

  @override
  String errorSavingPrompt(String error) {
    return 'Error saving prompt: $error';
  }

  @override
  String errorDeletingPrompt(String error) {
    return 'Error deleting prompt: $error';
  }

  @override
  String errorSelectingFolder(String error) {
    return 'Error selecting folder: $error';
  }

  @override
  String errorOpeningUrl(String url) {
    return 'Could not open URL: $url';
  }

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get storagePermissionRequired =>
      'Storage permission required. Please allow access in the app settings.';

  @override
  String get storageSavedSuccess => 'Storage location saved successfully';

  @override
  String examplePromptAdvanced(Object transcription) {
    return 'Summarize the following text:\n\n\'\'$transcription\'\'\n\nFocus on the main points.';
  }

  @override
  String get examplePromptSimple =>
      'Summarize the text and list the key points.';

  @override
  String get transcriptionSuccess => 'Success!';

  @override
  String get transcribing => 'Transcribing...';

  @override
  String get transcribe => 'Transcribe';

  @override
  String get transcription => 'Transcription';

  @override
  String get retranscribe => 'Retranscribe';

  @override
  String languageLabel(String language) {
    return 'Language: $language';
  }

  @override
  String wordCount(int count) {
    return '$count words';
  }

  @override
  String characterCount(int count) {
    return '$count characters';
  }

  @override
  String get speakers => 'Speakers: ';

  @override
  String get processWithPrompt => 'Process the transcription with an AI prompt';

  @override
  String get generating => 'Generating...';

  @override
  String get applyAnotherPrompt => 'Apply another prompt';

  @override
  String get applyPrompt => 'Apply prompt';

  @override
  String messageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'messages',
      one: 'message',
    );
    return '$count $_temp0';
  }

  @override
  String get transcribed => 'Transcribed';

  @override
  String get oldRecordingNoAudio => 'Old recording without audio file';

  @override
  String get oldRecordingAudioUnavailable =>
      'Old recording: Audio file no longer available';

  @override
  String timeAgoSeconds(int count) {
    return '$count sec ago';
  }

  @override
  String timeAgoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String timeAgoHours(int count) {
    return '$count hr ago';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$count $_temp0 ago';
  }

  @override
  String timeAgoYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$count $_temp0 ago';
  }

  @override
  String get menuRename => 'Rename';

  @override
  String get menuExport => 'Export';

  @override
  String promptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'prompts',
      one: 'prompt',
    );
    return '$count $_temp0';
  }

  @override
  String get paused => 'Paused';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get done => 'Done';

  @override
  String get no => 'No';

  @override
  String get storagePermissionRequiredTitle => 'Storage permission required';

  @override
  String get storagePermissionRequiredContent =>
      'To save recordings in your selected folder, VIOSA needs access to storage.\n\nPlease allow access.';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get permissionDeniedTitle => 'Permission denied';

  @override
  String get permissionDeniedContent =>
      'To save in your selected folder, storage permission must be enabled.\n\nWould you like to open settings?';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get recordingInProgress => 'Recording in progress';

  @override
  String get readyToRecord => 'Ready to record';

  @override
  String get savingRecording => 'Saving recording...';

  @override
  String get predefinedPromptQuestionsName => 'Generate Questions';

  @override
  String get predefinedPromptQuestionsTemplate =>
      'Generate 5-7 comprehension questions about the following text. The questions should:\n- Cover different difficulty levels (easy to challenging)\n- Ask about both facts and relationships\n- Be clearly and precisely formulated\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptActionItemsName => 'Action Items';

  @override
  String get predefinedPromptActionItemsTemplate =>
      'Extract all tasks and to-dos from the following text.\n\nFormat the output as a structured list:\n- Group by topic or responsibility (if recognizable)\n- Mark deadlines or due dates (if mentioned)\n- Prioritize by urgency (if derivable)\n\nIf no specific tasks are recognizable, indicate this.\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptSummaryName => 'Summarize';

  @override
  String get predefinedPromptSummaryTemplate =>
      'Create a comprehensive and detailed summary of the following text.\n\nThe summary should:\n- Be structured into thematic sections\n- Capture all essential content, arguments, and insights\n- Clarify the context, purpose, and conclusions of the conversation/text\n- Retain important details and nuances\n\nUse headings and paragraphs for better readability.\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptKeyPointsName => 'Key Points';

  @override
  String get predefinedPromptKeyPointsTemplate =>
      'List the most important points from the following text.\n\nFor each point:\n- Formulate a clear main statement\n- Add relevant details, reasoning, or context\n- Explain the significance or implication of the point\n\nNote:\n- Maximum 5-10 points\n- Prioritize by relevance\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptDecisionsName => 'Decisions';

  @override
  String get predefinedPromptDecisionsTemplate =>
      'Extract all decisions from the following text.\n\nFor each decision:\n- What was decided?\n- Why was it decided this way? (Reasoning/arguments)\n- Who is responsible? (if recognizable)\n- By when? (if mentioned)\n\nIf no clear decisions were made, list the open discussion points and pending clarifications.\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptProContraName => 'Pro & Contra';

  @override
  String get predefinedPromptProContraTemplate =>
      'Analyze the following text and create a Pro & Contra analysis.\n\nStructure:\n- Identify the topic or question\n- List pro arguments with reasoning\n- List contra arguments with reasoning\n- Summarize conclusion or tendency (if recognizable from the conversation)\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptReportName => 'Create Report';

  @override
  String get predefinedPromptReportTemplate =>
      'Create a formal report based on the following text.\n\nStructure:\n- Title and date/occasion (if recognizable)\n- Introduction: Context and purpose\n- Main part: Discussed topics with key statements and details\n- Results: Decisions made and agreements\n- Outlook: Next steps and open points\n\nUse an objective, professional style.\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptControversyName => 'Deepen Controversies';

  @override
  String get predefinedPromptControversyTemplate =>
      'Identify controversial or disputed points from the following text and analyze them in depth.\n\nFor each controversial point:\n- Describe the point of contention and the different viewpoints\n- Analyze the arguments presented by each side\n- Add important aspects that were missing or underrepresented in the discussion\n- Provide additional facts, perspectives, or counterarguments for deeper understanding\n- Give a balanced assessment\n\nThe goal is to create a well-founded basis for further opinion formation.\n\nText:\n[[transcription]]';

  @override
  String get selectPrompt => 'Select Prompt';

  @override
  String get apply => 'Apply';

  @override
  String get noPromptsAvailable =>
      'No prompts available. Create one in the Prompts section.';

  @override
  String get selectPromptForTranscription =>
      'Select a prompt for your transcription:';

  @override
  String errorLoadingPrompts(String error) {
    return 'Error loading prompts: $error';
  }

  @override
  String get noPredefinedPromptsAvailable => 'No predefined prompts available.';

  @override
  String get noCustomPromptsAvailable =>
      'No custom prompts yet.\n\nCreate your own prompts under \"Prompts\" in the navigation.';

  @override
  String get generatingResponse => 'Generating response...';

  @override
  String get applying => 'Applying...';

  @override
  String get cancelled => 'Cancelled';

  @override
  String promptResultsCount(int count) {
    return 'Prompt Results ($count)';
  }

  @override
  String get deletePromptResult => 'Delete prompt result?';

  @override
  String deletePromptResultConfirmation(String name) {
    return 'Do you really want to delete the result \"$name\"?';
  }

  @override
  String promptResultDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get undo => 'Undo';

  @override
  String promptLabel(String name) {
    return 'Prompt: $name';
  }

  @override
  String modelUsedLabel(String model) {
    return 'Model: $model';
  }

  @override
  String wordsLabel(int count) {
    return '$count words';
  }

  @override
  String charactersLabel(int count) {
    return '$count characters';
  }

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get copy => 'Copy';

  @override
  String get collapse => 'Collapse';

  @override
  String get audioFileNotFoundWarning =>
      'The audio file was not found. You can view existing results, but cannot start a new transcription.';

  @override
  String get noResultsAvailable => 'No results available';

  @override
  String get chatContext => 'Chat Context';

  @override
  String get chatContextDescription =>
      'Select which content should be available to the AI.';

  @override
  String chatContextEnabledCount(int count, int total) {
    return '$count of $total active';
  }

  @override
  String get sort => 'Sort';

  @override
  String get sortDateNewest => 'Date (newest first)';

  @override
  String get sortDateOldest => 'Date (oldest first)';

  @override
  String get sortNameAZ => 'Name (A-Z)';

  @override
  String get sortNameZA => 'Name (Z-A)';

  @override
  String get sortDurationLongest => 'Duration (longest first)';

  @override
  String get sortDurationShortest => 'Duration (shortest first)';

  @override
  String get cancelTranscription => 'Cancel transcription';

  @override
  String get transcriptionCancelled => 'Transcription cancelled';

  @override
  String get stay => 'Stay';

  @override
  String get discardRecordingTitle => 'Discard recording?';

  @override
  String discardRecordingContent(String duration) {
    return 'The recording ($duration) will be deleted and cannot be restored.';
  }

  @override
  String get discard => 'Discard';

  @override
  String get continueRecording => 'Keep recording';

  @override
  String get apiKeyMissingTitle => 'API key missing';

  @override
  String get apiKeyMissingDescription =>
      'Add an OpenRouter key to transcribe your recordings.';

  @override
  String get setUp => 'Set up';

  @override
  String errorStartingRecording(String error) {
    return 'Could not start recording: $error';
  }

  @override
  String errorStoppingRecording(String error) {
    return 'Could not stop recording: $error';
  }

  @override
  String get errorSavingRecording => 'Recording could not be saved';

  @override
  String errorPausingRecording(String error) {
    return 'Could not pause recording: $error';
  }

  @override
  String errorResumingRecording(String error) {
    return 'Could not resume recording: $error';
  }

  @override
  String errorCancellingRecording(String error) {
    return 'Could not discard recording: $error';
  }

  @override
  String get storagePermissionDeniedDefaultFolder =>
      'Storage permission denied. The recording is saved to the default folder.';

  @override
  String get micPermissionTitle => 'Microphone permission required';

  @override
  String get micPermissionDescription =>
      'VIOSA needs microphone access to record.';

  @override
  String get micPermissionRequired => 'Microphone permission required';

  @override
  String get checkAgain => 'Check again';

  @override
  String get enterMessage => 'Type a message ...';

  @override
  String get speakNow => 'Listening ...';

  @override
  String get stopGeneration => 'Stop generation';

  @override
  String get noAudioFilesFound => 'No audio files found';

  @override
  String get reload => 'Reload';

  @override
  String get noSearchResults => 'No results';

  @override
  String get noFilesMatchSearch => 'No files match your search.';

  @override
  String errorLoadingFiles(String error) {
    return 'Could not load files: $error';
  }

  @override
  String get processing => 'Processing';

  @override
  String get retry => 'Try again';

  @override
  String get showTranscription => 'Show transcription';

  @override
  String errorRetrying(String error) {
    return 'Retry failed: $error';
  }

  @override
  String get errorAuth => 'Invalid API key. Please check it in settings.';

  @override
  String get errorRateLimit =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String get errorNetwork =>
      'No connection. Please check your internet connection.';

  @override
  String get errorTimeout => 'The request timed out. Please try again.';

  @override
  String get errorServer =>
      'The service is unavailable right now. Please try again later.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorApiKeyMissing =>
      'No API key stored. Please add one in the settings.';

  @override
  String errorUnknownWithDetails(String details) {
    return 'Something went wrong: $details';
  }

  @override
  String errorServiceWithDetails(String details) {
    return 'Transcription failed: $details';
  }

  @override
  String get errorAudioFileMissing =>
      'The audio file is gone. Please link the file again.';

  @override
  String get speechUnavailable => 'Speech recognition unavailable';

  @override
  String get speechInitError => 'Speech recognition could not be started';

  @override
  String get speechRecognitionError => 'Speech recognition failed';

  @override
  String get tapToStop => 'Tap to stop';

  @override
  String get tapToSpeak => 'Tap to speak';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get selectAudioFileTitle => 'Select audio file';

  @override
  String get searchFilesHint => 'Search...';

  @override
  String get loadingAudioFiles => 'Loading audio files...';

  @override
  String get browseAllFiles => 'Open another file';

  @override
  String get browseAllFilesHint =>
      'Open a file from any folder or cloud storage';

  @override
  String get importingFile => 'Importing file...';

  @override
  String get unsupportedAudioFormat => 'This file format is not supported.';

  @override
  String get storageAccessOptionalHint =>
      'Without storage access only the app\'s own recordings are listed. Other files can still be opened via \"Open another file\".';

  @override
  String get scanResultsTruncated =>
      'Not all files are shown. Narrow the search or use \"Open another file\".';

  @override
  String get sortNewestShort => 'Newest';

  @override
  String get sortOldestShort => 'Oldest';

  @override
  String get sortNameAZShort => 'Name A-Z';

  @override
  String get sortNameZAShort => 'Name Z-A';

  @override
  String get sortSizeDescShort => 'Size ↓';

  @override
  String get sortSizeAscShort => 'Size ↑';

  @override
  String get fileTypeAll => 'All';

  @override
  String get fileTypeOther => 'Other';

  @override
  String get relinkAudioFile => 'Select file again';

  @override
  String get audioFileRelinked => 'Audio file relinked';

  @override
  String errorImportingFile(String error) {
    return 'Could not import file: $error';
  }

  @override
  String get transcriptionContinuesInBackground =>
      'Transcription keeps running in the background';

  @override
  String get transcriptionRunningBannerTitle => 'Transcription running';

  @override
  String get openRunningTranscription => 'Open';

  @override
  String get promptGenerationRunningTitle => 'Prompt still running';

  @override
  String get promptGenerationRunningContent =>
      'Leaving the session discards the result being generated.';

  @override
  String get promptCancelled => 'Generation stopped';

  @override
  String errorSavingHistory(String error) {
    return 'Could not save the result: $error';
  }

  @override
  String errorSharingResult(String error) {
    return 'Sharing failed: $error';
  }

  @override
  String get searchRecordings => 'Search recordings';

  @override
  String get searchRecordingsHint => 'Search name or transcript';

  @override
  String get noRecordingsMatchSearch => 'No recording matches the search';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeDescription =>
      'Font size of transcripts and prompt results';

  @override
  String get storedData => 'Stored data';

  @override
  String get clearAllHistory => 'Delete all recordings';

  @override
  String get clearAllHistoryConfirm =>
      'All recordings, transcripts and chats are deleted permanently.';

  @override
  String get allHistoryCleared => 'All recordings deleted';

  @override
  String get transcribeStyle => 'Transcription style';

  @override
  String get transcribeStyleClean => 'Clean';

  @override
  String get transcribeStyleVerbatim => 'Verbatim';

  @override
  String get transcribeStyleDescription =>
      'Clean removes fillers, verbatim keeps every spoken word';

  @override
  String get keywords => 'Domain terms';

  @override
  String get keywordsDescription =>
      'Names and technical terms the model should prefer';

  @override
  String get keywordsHint => 'Enter a term and confirm';

  @override
  String get keywordsEmpty => 'No terms added yet';

  @override
  String get autoTranscribe => 'Transcribe after recording';

  @override
  String get autoTranscribeDescription =>
      'Starts transcription right after a recording ends';

  @override
  String speakerLabel(int position) {
    return 'Speaker $position';
  }

  @override
  String get timestamps => 'Timestamps';

  @override
  String get jumpToPosition => 'Jump to this position';

  @override
  String get exportAsText => 'Share as text';

  @override
  String get exportAsSubtitles => 'Share as subtitles (SRT)';

  @override
  String detectedLanguageLabel(String language) {
    return 'Detected: $language';
  }

  @override
  String get autoPrompt => 'Prompt after transcription';

  @override
  String get autoPromptDescription =>
      'Runs the selected prompt as soon as a transcript is ready';

  @override
  String get autoPromptDisabled => 'Disabled';
}
