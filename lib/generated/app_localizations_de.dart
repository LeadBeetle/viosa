// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settings => 'Einstellungen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get create => 'Erstellen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get start => 'Starten';

  @override
  String get choose => 'Wählen';

  @override
  String get example => 'Beispiel';

  @override
  String get noRecordings => 'Keine Aufnahmen';

  @override
  String get noRecordingsSubtitle =>
      'Starten Sie eine neue Aufnahme mit dem + Button';

  @override
  String get deleteRecording => 'Aufnahme löschen';

  @override
  String deleteConfirmation(String name) {
    return 'Möchten Sie \"$name\" wirklich löschen?';
  }

  @override
  String get recordingRenamed => 'Aufnahme umbenannt';

  @override
  String get recordingDeleted => 'Aufnahme gelöscht';

  @override
  String get managePrompts => 'Prompts verwalten';

  @override
  String get selectFile => 'Datei wählen';

  @override
  String get recording => 'Aufnahme';

  @override
  String get renameRecording => 'Umbenennen';

  @override
  String get name => 'Name';

  @override
  String get newName => 'Neuer Name';

  @override
  String get noAudioPath => 'Kein Audiopfad verfügbar';

  @override
  String get audioFileNotFound => 'Audiodatei nicht gefunden';

  @override
  String get apiConfiguration => 'API-Konfiguration';

  @override
  String get apiKeyLabel => 'OpenRouter API-Key';

  @override
  String get apiKeyHint => 'sk-or-v1-...';

  @override
  String get apiKeyHelp => 'Holen Sie sich Ihren API-Key von';

  @override
  String get showApiKey => 'API-Key anzeigen';

  @override
  String get hideApiKey => 'API-Key verbergen';

  @override
  String get pleaseEnterApiKey => 'Bitte geben Sie einen API-Key ein';

  @override
  String get configureApiKey => 'Bitte API-Key konfigurieren';

  @override
  String get modelsSectionTitle => 'Modelle';

  @override
  String get speechToTextModelLabel => 'Spracherkennung';

  @override
  String get languageModelLabel => 'Sprachmodell';

  @override
  String get aiModel => 'KI-Modell';

  @override
  String get audioTranscription => 'Audio & Transkription';

  @override
  String get storageLocation => 'Speicherort für Aufnahmen';

  @override
  String get defaultStorageLocation => 'Standard-Speicherort';

  @override
  String get transcriptionLanguage => 'Sprache';

  @override
  String get transcriptionLanguageDescription =>
      'Wählen Sie die Sprache für die Transkription';

  @override
  String get transcriptionLanguageAuto => 'Automatisch erkennen';

  @override
  String get transcriptionLanguageGerman => 'Deutsch';

  @override
  String get transcriptionLanguageEnglish => 'Englisch';

  @override
  String get speakerDiarization => 'Sprechererkennung';

  @override
  String get speakerDiarizationDescription =>
      'Identifiziert verschiedene Sprecher in der Aufnahme';

  @override
  String get uiLanguage => 'App-Sprache';

  @override
  String get uiLanguageDescription =>
      'Wählen Sie die Sprache der Benutzeroberfläche';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get appearance => 'Darstellung';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeDescription => 'Wählen Sie das Farbschema der App';

  @override
  String get promptsManage => 'Prompts verwalten';

  @override
  String get promptsDescription =>
      'Erstellen und bearbeiten Sie Ihre KI-Prompts';

  @override
  String get aboutViosa => 'Über VIOSA';

  @override
  String get aboutDescription =>
      'VIOSA (Voice Intelligent Output and Speech Analyzer) nutzt die OpenRouter API für Audio-Transkription mit modernsten KI-Modellen.';

  @override
  String get apiKeySecurityNote =>
      'Ihr API-Key wird sicher auf Ihrem Gerät gespeichert und niemals an Dritte weitergegeben.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get prompts => 'Prompts';

  @override
  String get customPrompts => 'Eigene';

  @override
  String customPromptsCount(int count) {
    return 'Eigene ($count)';
  }

  @override
  String standardPromptsCount(int count) {
    return 'Standard ($count)';
  }

  @override
  String get noCustomPrompts => 'Noch keine eigenen Prompts';

  @override
  String get noCustomPromptsSubtitle =>
      'Erstellen Sie eigene Prompts für Ihre Transkriptionen';

  @override
  String get createPrompt => 'Prompt erstellen';

  @override
  String get newPrompt => 'Neuer Prompt';

  @override
  String get deletePrompt => 'Prompt löschen';

  @override
  String get promptSaved => 'Prompt erfolgreich gespeichert';

  @override
  String get promptDeleted => 'Prompt gelöscht';

  @override
  String get noPredefinedPrompts => 'Keine vordefinierten Prompts verfügbar';

  @override
  String get editPrompt => 'Prompt bearbeiten';

  @override
  String get promptName => 'Prompt-Name';

  @override
  String get promptNameHint => 'z.B. Zusammenfassen';

  @override
  String get enterNameRequired => 'Bitte geben Sie einen Namen ein';

  @override
  String get advancedOptions => 'Erweiterte Optionen';

  @override
  String get manualTranscriptionPlacement =>
      'Manuelle Platzierung der Transkription';

  @override
  String get autoTranscriptionPlacement =>
      'Transkription wird automatisch am Ende eingefügt';

  @override
  String get insertTranscription => 'Transkription einfügen';

  @override
  String get promptTemplate => 'Prompt-Vorlage';

  @override
  String promptTemplateHintAdvanced(Object transcription) {
    return 'Verwenden Sie den Button oben, um \'\'$transcription\'\' einzufügen';
  }

  @override
  String get promptTemplateHintSimple =>
      'Beschreiben Sie, was mit der Transkription geschehen soll';

  @override
  String get enterTemplateRequired => 'Bitte geben Sie eine Vorlage ein';

  @override
  String transcriptionPlaceholderFound(Object transcription) {
    return '\'\'$transcription\'\' gefunden';
  }

  @override
  String transcriptionPlacementHintAdvanced(Object transcription) {
    return 'Verwenden Sie \'\'$transcription\'\', wo der Text eingefügt werden soll';
  }

  @override
  String get transcriptionPlacementHintSimple =>
      'Die Transkription wird automatisch an Ihren Prompt angehängt';

  @override
  String get sessionDiscardTitle => 'Aktuelle Session verwerfen?';

  @override
  String get sessionDiscardMessage =>
      'Sie haben bereits eine Audiodatei ausgewählt oder transkribiert. Möchten Sie diese Session verwerfen und eine neue starten?';

  @override
  String get startNewSession => 'Neue Session starten';

  @override
  String get longAudioDetected => 'Lange Audiodatei erkannt';

  @override
  String get startTranscription => 'Transkription starten';

  @override
  String get warningExistingData =>
      'Achtung: Bestehende Transkription und Prompt-Ergebnisse werden gelöscht.';

  @override
  String longAudioDescription(String duration, int splitCount) {
    return 'Diese Audiodatei ist $duration lang und wird in $splitCount Segmente aufgeteilt (je ~10 Minuten).\n\nDie Transkription läuft im Hintergrund und kann einige Minuten dauern.';
  }

  @override
  String shortAudioDescription(String duration) {
    return 'Diese Audiodatei ist $duration lang.';
  }

  @override
  String modelLabel(String modelName) {
    return 'Modell: $modelName';
  }

  @override
  String get newRecording => 'Neue Aufnahme';

  @override
  String get splittingAudio => 'Audio wird aufgeteilt...';

  @override
  String get preparingAudio => 'Audio wird vorbereitet...';

  @override
  String get transcriptionFailed => 'Transkription fehlgeschlagen';

  @override
  String get startChat => 'Chat starten';

  @override
  String get chat => 'Chat';

  @override
  String get clearChat => 'Chat löschen';

  @override
  String get clearChatConfirmTitle => 'Chat löschen?';

  @override
  String get clearChatConfirmMessage =>
      'Möchten Sie den gesamten Chat-Verlauf löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get startChatTitle => 'Starten Sie einen Chat';

  @override
  String get startChatDescription =>
      'Stellen Sie Fragen zum Transkript oder nutzen Sie @Transkript um darauf zu verweisen.';

  @override
  String get apiKeyNotConfigured => 'API-Schlüssel nicht konfiguriert';

  @override
  String get recordingNotFound => 'Aufnahme nicht gefunden';

  @override
  String errorPlaying(String error) {
    return 'Fehler beim Abspielen: $error';
  }

  @override
  String errorRenaming(String error) {
    return 'Fehler beim Umbenennen: $error';
  }

  @override
  String errorDeleting(String error) {
    return 'Fehler beim Löschen: $error';
  }

  @override
  String errorSavingLanguage(String error) {
    return 'Fehler beim Speichern der Sprache: $error';
  }

  @override
  String errorSavingTheme(String error) {
    return 'Fehler beim Speichern des Themes: $error';
  }

  @override
  String errorSavingPrompt(String error) {
    return 'Fehler beim Speichern des Prompts: $error';
  }

  @override
  String errorDeletingPrompt(String error) {
    return 'Fehler beim Löschen des Prompts: $error';
  }

  @override
  String errorSelectingFolder(String error) {
    return 'Fehler beim Auswählen des Ordners: $error';
  }

  @override
  String errorOpeningUrl(String url) {
    return 'URL konnte nicht geöffnet werden: $url';
  }

  @override
  String errorGeneric(String error) {
    return 'Fehler: $error';
  }

  @override
  String get storagePermissionRequired =>
      'Speicherberechtigung erforderlich. Bitte erlauben Sie den Zugriff in den App-Einstellungen.';

  @override
  String get storageSavedSuccess => 'Speicherort erfolgreich gespeichert';

  @override
  String examplePromptAdvanced(Object transcription) {
    return 'Fasse den folgenden Text zusammen:\n\n\'\'$transcription\'\'\n\nAchte dabei auf die Hauptpunkte.';
  }

  @override
  String get examplePromptSimple =>
      'Fasse den Text zusammen und liste die wichtigsten Punkte auf.';

  @override
  String get transcriptionSuccess => 'Erfolgreich!';

  @override
  String get transcribing => 'Wird transkribiert...';

  @override
  String get transcribe => 'Transkribieren';

  @override
  String get transcription => 'Transkription';

  @override
  String get retranscribe => 'Erneut transkribieren';

  @override
  String languageLabel(String language) {
    return 'Sprache: $language';
  }

  @override
  String wordCount(int count) {
    return '$count Wörter';
  }

  @override
  String characterCount(int count) {
    return '$count Zeichen';
  }

  @override
  String get speakers => 'Sprecher: ';

  @override
  String get processWithPrompt =>
      'Verarbeite die Transkription mit einem KI-Prompt';

  @override
  String get generating => 'Wird generiert...';

  @override
  String get applyAnotherPrompt => 'Weiteres Prompt anwenden';

  @override
  String get applyPrompt => 'Prompt anwenden';

  @override
  String messageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nachrichten',
      one: 'Nachricht',
    );
    return '$count $_temp0';
  }

  @override
  String get transcribed => 'Transkribiert';

  @override
  String get oldRecordingNoAudio => 'Alte Aufnahme ohne Audiodatei';

  @override
  String get oldRecordingAudioUnavailable =>
      'Alte Aufnahme: Audiodatei nicht mehr verfügbar';

  @override
  String timeAgoSeconds(int count) {
    return 'vor $count Sek.';
  }

  @override
  String timeAgoMinutes(int count) {
    return 'vor $count Min.';
  }

  @override
  String timeAgoHours(int count) {
    return 'vor $count Std.';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tagen',
      one: 'Tag',
    );
    return 'vor $count $_temp0';
  }

  @override
  String timeAgoYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jahren',
      one: 'Jahr',
    );
    return 'vor $count $_temp0';
  }

  @override
  String get menuRename => 'Umbenennen';

  @override
  String get menuExport => 'Exportieren';

  @override
  String promptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count Prompt$_temp0';
  }

  @override
  String get paused => 'Pausiert';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get pause => 'Pause';

  @override
  String get done => 'Fertig';

  @override
  String get no => 'Nein';

  @override
  String get storagePermissionRequiredTitle =>
      'Speicherberechtigung erforderlich';

  @override
  String get storagePermissionRequiredContent =>
      'Um Aufnahmen in Ihrem ausgewählten Ordner zu speichern, benötigt VIOSA Zugriff auf den Speicher.\n\nBitte erlauben Sie den Zugriff.';

  @override
  String get grantPermission => 'Berechtigung erteilen';

  @override
  String get permissionDeniedTitle => 'Berechtigung verweigert';

  @override
  String get permissionDeniedContent =>
      'Um in Ihrem gewählten Ordner zu speichern, muss die Speicherberechtigung aktiviert werden.\n\nMöchten Sie die Einstellungen öffnen?';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get recordingInProgress => 'Aufnahme läuft';

  @override
  String get readyToRecord => 'Bereit zur Aufnahme';

  @override
  String get savingRecording => 'Aufnahme wird gespeichert...';

  @override
  String get predefinedPromptQuestionsName => 'Fragen generieren';

  @override
  String get predefinedPromptQuestionsTemplate =>
      'Generiere 5-7 Verständnisfragen zum folgenden Text. Die Fragen sollen:\n- Verschiedene Schwierigkeitsgrade abdecken (einfach bis anspruchsvoll)\n- Sowohl Fakten als auch Zusammenhänge abfragen\n- Klar und präzise formuliert sein\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptActionItemsName => 'Action Items';

  @override
  String get predefinedPromptActionItemsTemplate =>
      'Extrahiere alle Aufgaben und To-Dos aus dem folgenden Text.\n\nFormatiere die Ausgabe als strukturierte Liste:\n- Gruppiere nach Thema oder Verantwortlichkeit (falls erkennbar)\n- Markiere Deadlines oder Fristen (falls erwähnt)\n- Priorisiere nach Dringlichkeit (falls ableitbar)\n\nFalls keine konkreten Aufgaben erkennbar sind, gib dies an.\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptSummaryName => 'Zusammenfassen';

  @override
  String get predefinedPromptSummaryTemplate =>
      'Erstelle eine ausführliche und detaillierte Zusammenfassung des folgenden Textes.\n\nDie Zusammenfassung soll:\n- Strukturiert in thematische Abschnitte gegliedert sein\n- Alle wesentlichen Inhalte, Argumente und Erkenntnisse erfassen\n- Den Kontext, Zweck und die Schlussfolgerungen des Gesprächs/Textes verdeutlichen\n- Wichtige Details und Nuancen beibehalten\n\nVerwende Überschriften und Absätze für bessere Lesbarkeit.\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptKeyPointsName => 'Wichtige Punkte';

  @override
  String get predefinedPromptKeyPointsTemplate =>
      'Liste die wichtigsten Punkte aus dem folgenden Text auf.\n\nFür jeden Punkt:\n- Formuliere eine klare Hauptaussage\n- Ergänze relevante Details, Begründungen oder Kontext\n- Erkläre die Bedeutung oder Implikation des Punktes\n\nAchte auf:\n- Maximal 5-10 Punkte\n- Priorisierung nach Relevanz\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptDecisionsName => 'Entscheidungen';

  @override
  String get predefinedPromptDecisionsTemplate =>
      'Extrahiere alle Entscheidungen aus dem folgenden Text.\n\nFür jede Entscheidung:\n- Was wurde entschieden?\n- Warum wurde so entschieden? (Begründung/Argumente)\n- Wer ist verantwortlich? (falls erkennbar)\n- Bis wann? (falls erwähnt)\n\nFalls keine klaren Entscheidungen getroffen wurden, liste die offenen Diskussionspunkte und ausstehenden Klärungen auf.\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptProContraName => 'Pro & Contra';

  @override
  String get predefinedPromptProContraTemplate =>
      'Analysiere den folgenden Text und erstelle eine Pro & Contra Analyse.\n\nStruktur:\n- Thema oder Fragestellung identifizieren\n- Pro-Argumente mit Begründungen auflisten\n- Contra-Argumente mit Begründungen auflisten\n- Fazit oder Tendenz zusammenfassen (falls aus dem Gespräch erkennbar)\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptReportName => 'Bericht erstellen';

  @override
  String get predefinedPromptReportTemplate =>
      'Erstelle einen formellen Bericht basierend auf dem folgenden Text.\n\nStruktur:\n- Titel und Datum/Anlass (falls erkennbar)\n- Einleitung: Kontext und Zweck\n- Hauptteil: Besprochene Themen mit Kernaussagen und Details\n- Ergebnisse: Getroffene Entscheidungen und Vereinbarungen\n- Ausblick: Nächste Schritte und offene Punkte\n\nVerwende einen sachlichen, professionellen Stil.\n\nText:\n[[transcription]]';

  @override
  String get predefinedPromptControversyName => 'Kontroversen vertiefen';

  @override
  String get predefinedPromptControversyTemplate =>
      'Identifiziere kontroverse oder strittige Punkte aus dem folgenden Text und analysiere diese tiefgehend.\n\nFür jeden kontroversen Punkt:\n- Beschreibe den Streitpunkt und die verschiedenen Standpunkte\n- Analysiere die vorgebrachten Argumente jeder Seite\n- Ergänze wichtige Aspekte, die in der Diskussion zu kurz kamen oder fehlten\n- Liefere zusätzliche Fakten, Perspektiven oder Gegenargumente zur Vertiefung\n- Gib eine ausgewogene Einschätzung\n\nZiel ist es, eine fundierte Grundlage für die weitere Meinungsbildung zu schaffen.\n\nText:\n[[transcription]]';

  @override
  String get selectPrompt => 'Prompt auswählen';

  @override
  String get apply => 'Anwenden';

  @override
  String get noPromptsAvailable =>
      'Keine Prompts verfügbar. Erstellen Sie einen im Prompts-Bereich.';

  @override
  String get selectPromptForTranscription =>
      'Wählen Sie einen Prompt für Ihre Transkription:';

  @override
  String errorLoadingPrompts(String error) {
    return 'Fehler beim Laden der Prompts: $error';
  }

  @override
  String get noPredefinedPromptsAvailable =>
      'Keine vordefinierten Prompts verfügbar.';

  @override
  String get noCustomPromptsAvailable =>
      'Keine eigenen Prompts vorhanden.\n\nErstellen Sie Ihre eigenen Prompts unter \"Prompts\" in der Navigation.';

  @override
  String get generatingResponse => 'Antwort wird generiert...';

  @override
  String get applying => 'Wende an...';

  @override
  String get cancelled => 'Abgebrochen';

  @override
  String promptResultsCount(int count) {
    return 'Prompt-Ergebnisse ($count)';
  }

  @override
  String get deletePromptResult => 'Prompt-Ergebnis löschen?';

  @override
  String deletePromptResultConfirmation(String name) {
    return 'Möchten Sie das Ergebnis \"$name\" wirklich löschen?';
  }

  @override
  String promptResultDeleted(String name) {
    return '$name gelöscht';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String promptLabel(String name) {
    return 'Prompt: $name';
  }

  @override
  String modelUsedLabel(String model) {
    return 'Modell: $model';
  }

  @override
  String wordsLabel(int count) {
    return '$count Wörter';
  }

  @override
  String charactersLabel(int count) {
    return '$count Zeichen';
  }

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get copy => 'Kopieren';

  @override
  String get collapse => 'Einklappen';

  @override
  String get audioFileNotFoundWarning =>
      'Die Audiodatei wurde nicht gefunden. Sie können die vorhandenen Ergebnisse ansehen, aber keine neue Transkription starten.';

  @override
  String get noResultsAvailable => 'Keine Ergebnisse verfügbar';

  @override
  String get chatContext => 'Chat-Kontext';

  @override
  String get chatContextDescription =>
      'Wählen Sie, welche Inhalte der KI zur Verfügung stehen sollen.';

  @override
  String chatContextEnabledCount(int count, int total) {
    return '$count von $total aktiv';
  }

  @override
  String get sort => 'Sortieren';

  @override
  String get sortDateNewest => 'Datum (neueste zuerst)';

  @override
  String get sortDateOldest => 'Datum (älteste zuerst)';

  @override
  String get sortNameAZ => 'Name (A-Z)';

  @override
  String get sortNameZA => 'Name (Z-A)';

  @override
  String get sortDurationLongest => 'Dauer (längste zuerst)';

  @override
  String get sortDurationShortest => 'Dauer (kürzeste zuerst)';
}
