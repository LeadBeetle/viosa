import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @create.
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get rename;

  /// No description provided for @start.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get start;

  /// No description provided for @choose.
  ///
  /// In de, this message translates to:
  /// **'Wählen'**
  String get choose;

  /// No description provided for @example.
  ///
  /// In de, this message translates to:
  /// **'Beispiel'**
  String get example;

  /// No description provided for @noRecordings.
  ///
  /// In de, this message translates to:
  /// **'Keine Aufnahmen'**
  String get noRecordings;

  /// No description provided for @noRecordingsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Starten Sie eine neue Aufnahme mit dem + Button'**
  String get noRecordingsSubtitle;

  /// No description provided for @deleteRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme löschen'**
  String get deleteRecording;

  /// No description provided for @deleteConfirmation.
  ///
  /// In de, this message translates to:
  /// **'Möchten Sie \"{name}\" wirklich löschen?'**
  String deleteConfirmation(String name);

  /// No description provided for @recordingRenamed.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme umbenannt'**
  String get recordingRenamed;

  /// No description provided for @recordingDeleted.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme gelöscht'**
  String get recordingDeleted;

  /// No description provided for @managePrompts.
  ///
  /// In de, this message translates to:
  /// **'Prompts verwalten'**
  String get managePrompts;

  /// No description provided for @selectFile.
  ///
  /// In de, this message translates to:
  /// **'Datei wählen'**
  String get selectFile;

  /// No description provided for @recording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme'**
  String get recording;

  /// No description provided for @renameRecording.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get renameRecording;

  /// No description provided for @name.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @newName.
  ///
  /// In de, this message translates to:
  /// **'Neuer Name'**
  String get newName;

  /// No description provided for @noAudioPath.
  ///
  /// In de, this message translates to:
  /// **'Kein Audiopfad verfügbar'**
  String get noAudioPath;

  /// No description provided for @audioFileNotFound.
  ///
  /// In de, this message translates to:
  /// **'Audiodatei nicht gefunden'**
  String get audioFileNotFound;

  /// No description provided for @apiConfiguration.
  ///
  /// In de, this message translates to:
  /// **'API-Konfiguration'**
  String get apiConfiguration;

  /// No description provided for @apiKeyLabel.
  ///
  /// In de, this message translates to:
  /// **'OpenRouter API-Key'**
  String get apiKeyLabel;

  /// No description provided for @apiKeyHint.
  ///
  /// In de, this message translates to:
  /// **'sk-or-v1-...'**
  String get apiKeyHint;

  /// No description provided for @apiKeyHelp.
  ///
  /// In de, this message translates to:
  /// **'Holen Sie sich Ihren API-Key von'**
  String get apiKeyHelp;

  /// No description provided for @showApiKey.
  ///
  /// In de, this message translates to:
  /// **'API-Key anzeigen'**
  String get showApiKey;

  /// No description provided for @hideApiKey.
  ///
  /// In de, this message translates to:
  /// **'API-Key verbergen'**
  String get hideApiKey;

  /// No description provided for @pleaseEnterApiKey.
  ///
  /// In de, this message translates to:
  /// **'Bitte geben Sie einen API-Key ein'**
  String get pleaseEnterApiKey;

  /// No description provided for @configureApiKey.
  ///
  /// In de, this message translates to:
  /// **'Bitte API-Key konfigurieren'**
  String get configureApiKey;

  /// No description provided for @modelsSectionTitle.
  ///
  /// In de, this message translates to:
  /// **'Modelle'**
  String get modelsSectionTitle;

  /// No description provided for @speechToTextModelLabel.
  ///
  /// In de, this message translates to:
  /// **'Spracherkennung'**
  String get speechToTextModelLabel;

  /// No description provided for @languageModelLabel.
  ///
  /// In de, this message translates to:
  /// **'Sprachmodell'**
  String get languageModelLabel;

  /// No description provided for @aiModel.
  ///
  /// In de, this message translates to:
  /// **'KI-Modell'**
  String get aiModel;

  /// No description provided for @audioTranscription.
  ///
  /// In de, this message translates to:
  /// **'Audio & Transkription'**
  String get audioTranscription;

  /// No description provided for @storageLocation.
  ///
  /// In de, this message translates to:
  /// **'Speicherort für Aufnahmen'**
  String get storageLocation;

  /// No description provided for @defaultStorageLocation.
  ///
  /// In de, this message translates to:
  /// **'Standard-Speicherort'**
  String get defaultStorageLocation;

  /// No description provided for @transcriptionLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get transcriptionLanguage;

  /// No description provided for @transcriptionLanguageDescription.
  ///
  /// In de, this message translates to:
  /// **'Wählen Sie die Sprache für die Transkription'**
  String get transcriptionLanguageDescription;

  /// No description provided for @transcriptionLanguageAuto.
  ///
  /// In de, this message translates to:
  /// **'Automatisch erkennen'**
  String get transcriptionLanguageAuto;

  /// No description provided for @transcriptionLanguageGerman.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get transcriptionLanguageGerman;

  /// No description provided for @transcriptionLanguageEnglish.
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get transcriptionLanguageEnglish;

  /// No description provided for @speakerDiarization.
  ///
  /// In de, this message translates to:
  /// **'Sprechererkennung'**
  String get speakerDiarization;

  /// No description provided for @speakerDiarizationDescription.
  ///
  /// In de, this message translates to:
  /// **'Das Modell kennzeichnet verschiedene Sprecher direkt im Transkript'**
  String get speakerDiarizationDescription;

  /// No description provided for @uiLanguage.
  ///
  /// In de, this message translates to:
  /// **'App-Sprache'**
  String get uiLanguage;

  /// No description provided for @uiLanguageDescription.
  ///
  /// In de, this message translates to:
  /// **'Wählen Sie die Sprache der Benutzeroberfläche'**
  String get uiLanguageDescription;

  /// No description provided for @languageGerman.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get languageEnglish;

  /// No description provided for @appearance.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In de, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// No description provided for @themeDescription.
  ///
  /// In de, this message translates to:
  /// **'Wählen Sie das Farbschema der App'**
  String get themeDescription;

  /// No description provided for @promptsManage.
  ///
  /// In de, this message translates to:
  /// **'Prompts verwalten'**
  String get promptsManage;

  /// No description provided for @promptsDescription.
  ///
  /// In de, this message translates to:
  /// **'Erstellen und bearbeiten Sie Ihre KI-Prompts'**
  String get promptsDescription;

  /// No description provided for @aboutViosa.
  ///
  /// In de, this message translates to:
  /// **'Über VIOSA'**
  String get aboutViosa;

  /// No description provided for @aboutDescription.
  ///
  /// In de, this message translates to:
  /// **'VIOSA (Voice Intelligent Output and Speech Analyzer) nutzt die OpenRouter API für Audio-Transkription mit modernsten KI-Modellen.'**
  String get aboutDescription;

  /// No description provided for @apiKeySecurityNote.
  ///
  /// In de, this message translates to:
  /// **'Ihr API-Key wird sicher auf Ihrem Gerät gespeichert und niemals an Dritte weitergegeben.'**
  String get apiKeySecurityNote;

  /// No description provided for @version.
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @prompts.
  ///
  /// In de, this message translates to:
  /// **'Prompts'**
  String get prompts;

  /// No description provided for @customPrompts.
  ///
  /// In de, this message translates to:
  /// **'Eigene'**
  String get customPrompts;

  /// No description provided for @customPromptsCount.
  ///
  /// In de, this message translates to:
  /// **'Eigene ({count})'**
  String customPromptsCount(int count);

  /// No description provided for @standardPromptsCount.
  ///
  /// In de, this message translates to:
  /// **'Standard ({count})'**
  String standardPromptsCount(int count);

  /// No description provided for @noCustomPrompts.
  ///
  /// In de, this message translates to:
  /// **'Noch keine eigenen Prompts'**
  String get noCustomPrompts;

  /// No description provided for @noCustomPromptsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Erstellen Sie eigene Prompts für Ihre Transkriptionen'**
  String get noCustomPromptsSubtitle;

  /// No description provided for @createPrompt.
  ///
  /// In de, this message translates to:
  /// **'Prompt erstellen'**
  String get createPrompt;

  /// No description provided for @newPrompt.
  ///
  /// In de, this message translates to:
  /// **'Neuer Prompt'**
  String get newPrompt;

  /// No description provided for @deletePrompt.
  ///
  /// In de, this message translates to:
  /// **'Prompt löschen'**
  String get deletePrompt;

  /// No description provided for @promptSaved.
  ///
  /// In de, this message translates to:
  /// **'Prompt erfolgreich gespeichert'**
  String get promptSaved;

  /// No description provided for @promptDeleted.
  ///
  /// In de, this message translates to:
  /// **'Prompt gelöscht'**
  String get promptDeleted;

  /// No description provided for @noPredefinedPrompts.
  ///
  /// In de, this message translates to:
  /// **'Keine vordefinierten Prompts verfügbar'**
  String get noPredefinedPrompts;

  /// No description provided for @editPrompt.
  ///
  /// In de, this message translates to:
  /// **'Prompt bearbeiten'**
  String get editPrompt;

  /// No description provided for @promptName.
  ///
  /// In de, this message translates to:
  /// **'Prompt-Name'**
  String get promptName;

  /// No description provided for @promptNameHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Zusammenfassen'**
  String get promptNameHint;

  /// No description provided for @enterNameRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte geben Sie einen Namen ein'**
  String get enterNameRequired;

  /// No description provided for @advancedOptions.
  ///
  /// In de, this message translates to:
  /// **'Erweiterte Optionen'**
  String get advancedOptions;

  /// No description provided for @manualTranscriptionPlacement.
  ///
  /// In de, this message translates to:
  /// **'Manuelle Platzierung der Transkription'**
  String get manualTranscriptionPlacement;

  /// No description provided for @autoTranscriptionPlacement.
  ///
  /// In de, this message translates to:
  /// **'Transkription wird automatisch am Ende eingefügt'**
  String get autoTranscriptionPlacement;

  /// No description provided for @insertTranscription.
  ///
  /// In de, this message translates to:
  /// **'Transkription einfügen'**
  String get insertTranscription;

  /// No description provided for @promptTemplate.
  ///
  /// In de, this message translates to:
  /// **'Prompt-Vorlage'**
  String get promptTemplate;

  /// No description provided for @promptTemplateHintAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Verwenden Sie den Button oben, um \'\'{transcription}\'\' einzufügen'**
  String promptTemplateHintAdvanced(Object transcription);

  /// No description provided for @promptTemplateHintSimple.
  ///
  /// In de, this message translates to:
  /// **'Beschreiben Sie, was mit der Transkription geschehen soll'**
  String get promptTemplateHintSimple;

  /// No description provided for @enterTemplateRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte geben Sie eine Vorlage ein'**
  String get enterTemplateRequired;

  /// No description provided for @transcriptionPlaceholderFound.
  ///
  /// In de, this message translates to:
  /// **'\'\'{transcription}\'\' gefunden'**
  String transcriptionPlaceholderFound(Object transcription);

  /// No description provided for @transcriptionPlacementHintAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Verwenden Sie \'\'{transcription}\'\', wo der Text eingefügt werden soll'**
  String transcriptionPlacementHintAdvanced(Object transcription);

  /// No description provided for @transcriptionPlacementHintSimple.
  ///
  /// In de, this message translates to:
  /// **'Die Transkription wird automatisch an Ihren Prompt angehängt'**
  String get transcriptionPlacementHintSimple;

  /// No description provided for @sessionDiscardTitle.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Session verwerfen?'**
  String get sessionDiscardTitle;

  /// No description provided for @sessionDiscardMessage.
  ///
  /// In de, this message translates to:
  /// **'Sie haben bereits eine Audiodatei ausgewählt oder transkribiert. Möchten Sie diese Session verwerfen und eine neue starten?'**
  String get sessionDiscardMessage;

  /// No description provided for @startNewSession.
  ///
  /// In de, this message translates to:
  /// **'Neue Session starten'**
  String get startNewSession;

  /// No description provided for @startTranscription.
  ///
  /// In de, this message translates to:
  /// **'Transkription starten'**
  String get startTranscription;

  /// No description provided for @warningExistingData.
  ///
  /// In de, this message translates to:
  /// **'Achtung: Bestehende Transkription, Prompt-Ergebnisse und der Chat-Verlauf werden gelöscht.'**
  String get warningExistingData;

  /// No description provided for @audioDurationDescription.
  ///
  /// In de, this message translates to:
  /// **'Diese Audiodatei ist {duration} lang.'**
  String audioDurationDescription(String duration);

  /// No description provided for @modelLabel.
  ///
  /// In de, this message translates to:
  /// **'Modell: {modelName}'**
  String modelLabel(String modelName);

  /// No description provided for @newRecording.
  ///
  /// In de, this message translates to:
  /// **'Neue Aufnahme'**
  String get newRecording;

  /// No description provided for @transcriptionFailed.
  ///
  /// In de, this message translates to:
  /// **'Transkription fehlgeschlagen'**
  String get transcriptionFailed;

  /// No description provided for @startChat.
  ///
  /// In de, this message translates to:
  /// **'Chat starten'**
  String get startChat;

  /// No description provided for @chat.
  ///
  /// In de, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @clearChat.
  ///
  /// In de, this message translates to:
  /// **'Chat löschen'**
  String get clearChat;

  /// No description provided for @clearChatConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Chat löschen?'**
  String get clearChatConfirmTitle;

  /// No description provided for @clearChatConfirmMessage.
  ///
  /// In de, this message translates to:
  /// **'Möchten Sie den gesamten Chat-Verlauf löschen? Diese Aktion kann nicht rückgängig gemacht werden.'**
  String get clearChatConfirmMessage;

  /// No description provided for @startChatTitle.
  ///
  /// In de, this message translates to:
  /// **'Starten Sie einen Chat'**
  String get startChatTitle;

  /// No description provided for @startChatDescription.
  ///
  /// In de, this message translates to:
  /// **'Stellen Sie Fragen zum Transkript oder nutzen Sie @Transkript um darauf zu verweisen.'**
  String get startChatDescription;

  /// No description provided for @apiKeyNotConfigured.
  ///
  /// In de, this message translates to:
  /// **'API-Schlüssel nicht konfiguriert'**
  String get apiKeyNotConfigured;

  /// No description provided for @recordingNotFound.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme nicht gefunden'**
  String get recordingNotFound;

  /// No description provided for @errorPlaying.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Abspielen: {error}'**
  String errorPlaying(String error);

  /// No description provided for @errorRenaming.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Umbenennen: {error}'**
  String errorRenaming(String error);

  /// No description provided for @errorDeleting.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen: {error}'**
  String errorDeleting(String error);

  /// No description provided for @errorSavingLanguage.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern der Sprache: {error}'**
  String errorSavingLanguage(String error);

  /// No description provided for @errorSavingTheme.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern des Themes: {error}'**
  String errorSavingTheme(String error);

  /// No description provided for @errorSavingPrompt.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern des Prompts: {error}'**
  String errorSavingPrompt(String error);

  /// No description provided for @errorDeletingPrompt.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen des Prompts: {error}'**
  String errorDeletingPrompt(String error);

  /// No description provided for @errorSelectingFolder.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Auswählen des Ordners: {error}'**
  String errorSelectingFolder(String error);

  /// No description provided for @errorOpeningUrl.
  ///
  /// In de, this message translates to:
  /// **'URL konnte nicht geöffnet werden: {url}'**
  String errorOpeningUrl(String url);

  /// No description provided for @errorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {error}'**
  String errorGeneric(String error);

  /// No description provided for @storagePermissionRequired.
  ///
  /// In de, this message translates to:
  /// **'Speicherberechtigung erforderlich. Bitte erlauben Sie den Zugriff in den App-Einstellungen.'**
  String get storagePermissionRequired;

  /// No description provided for @storageSavedSuccess.
  ///
  /// In de, this message translates to:
  /// **'Speicherort erfolgreich gespeichert'**
  String get storageSavedSuccess;

  /// No description provided for @examplePromptAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Fasse den folgenden Text zusammen:\n\n\'\'{transcription}\'\'\n\nAchte dabei auf die Hauptpunkte.'**
  String examplePromptAdvanced(Object transcription);

  /// No description provided for @examplePromptSimple.
  ///
  /// In de, this message translates to:
  /// **'Fasse den Text zusammen und liste die wichtigsten Punkte auf.'**
  String get examplePromptSimple;

  /// No description provided for @transcriptionSuccess.
  ///
  /// In de, this message translates to:
  /// **'Erfolgreich!'**
  String get transcriptionSuccess;

  /// No description provided for @transcribing.
  ///
  /// In de, this message translates to:
  /// **'Wird transkribiert...'**
  String get transcribing;

  /// No description provided for @transcribe.
  ///
  /// In de, this message translates to:
  /// **'Transkribieren'**
  String get transcribe;

  /// No description provided for @transcription.
  ///
  /// In de, this message translates to:
  /// **'Transkription'**
  String get transcription;

  /// No description provided for @retranscribe.
  ///
  /// In de, this message translates to:
  /// **'Erneut transkribieren'**
  String get retranscribe;

  /// No description provided for @languageLabel.
  ///
  /// In de, this message translates to:
  /// **'Sprache: {language}'**
  String languageLabel(String language);

  /// No description provided for @wordCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Wörter'**
  String wordCount(int count);

  /// No description provided for @characterCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Zeichen'**
  String characterCount(int count);

  /// No description provided for @speakers.
  ///
  /// In de, this message translates to:
  /// **'Sprecher: '**
  String get speakers;

  /// No description provided for @processWithPrompt.
  ///
  /// In de, this message translates to:
  /// **'Verarbeite die Transkription mit einem KI-Prompt'**
  String get processWithPrompt;

  /// No description provided for @generating.
  ///
  /// In de, this message translates to:
  /// **'Wird generiert...'**
  String get generating;

  /// No description provided for @applyAnotherPrompt.
  ///
  /// In de, this message translates to:
  /// **'Weiteres Prompt anwenden'**
  String get applyAnotherPrompt;

  /// No description provided for @applyPrompt.
  ///
  /// In de, this message translates to:
  /// **'Prompt anwenden'**
  String get applyPrompt;

  /// No description provided for @messageCount.
  ///
  /// In de, this message translates to:
  /// **'{count} {count, plural, =1{Nachricht} other{Nachrichten}}'**
  String messageCount(int count);

  /// No description provided for @transcribed.
  ///
  /// In de, this message translates to:
  /// **'Transkribiert'**
  String get transcribed;

  /// No description provided for @oldRecordingNoAudio.
  ///
  /// In de, this message translates to:
  /// **'Alte Aufnahme ohne Audiodatei'**
  String get oldRecordingNoAudio;

  /// No description provided for @oldRecordingAudioUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Alte Aufnahme: Audiodatei nicht mehr verfügbar'**
  String get oldRecordingAudioUnavailable;

  /// No description provided for @timeAgoSeconds.
  ///
  /// In de, this message translates to:
  /// **'vor {count} Sek.'**
  String timeAgoSeconds(int count);

  /// No description provided for @timeAgoMinutes.
  ///
  /// In de, this message translates to:
  /// **'vor {count} Min.'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In de, this message translates to:
  /// **'vor {count} Std.'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In de, this message translates to:
  /// **'vor {count} {count, plural, =1{Tag} other{Tagen}}'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoYears.
  ///
  /// In de, this message translates to:
  /// **'vor {count} {count, plural, =1{Jahr} other{Jahren}}'**
  String timeAgoYears(int count);

  /// No description provided for @menuRename.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get menuRename;

  /// No description provided for @menuExport.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get menuExport;

  /// No description provided for @promptCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Prompt{count, plural, =1{} other{s}}'**
  String promptCount(int count);

  /// No description provided for @paused.
  ///
  /// In de, this message translates to:
  /// **'Pausiert'**
  String get paused;

  /// No description provided for @resume.
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @no.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get no;

  /// No description provided for @storagePermissionRequiredTitle.
  ///
  /// In de, this message translates to:
  /// **'Speicherberechtigung erforderlich'**
  String get storagePermissionRequiredTitle;

  /// No description provided for @storagePermissionRequiredContent.
  ///
  /// In de, this message translates to:
  /// **'Um Aufnahmen in Ihrem ausgewählten Ordner zu speichern, benötigt VIOSA Zugriff auf den Speicher.\n\nBitte erlauben Sie den Zugriff.'**
  String get storagePermissionRequiredContent;

  /// No description provided for @grantPermission.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung erteilen'**
  String get grantPermission;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung verweigert'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedContent.
  ///
  /// In de, this message translates to:
  /// **'Um in Ihrem gewählten Ordner zu speichern, muss die Speicherberechtigung aktiviert werden.\n\nMöchten Sie die Einstellungen öffnen?'**
  String get permissionDeniedContent;

  /// No description provided for @openSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get openSettings;

  /// No description provided for @recordingInProgress.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme läuft'**
  String get recordingInProgress;

  /// No description provided for @readyToRecord.
  ///
  /// In de, this message translates to:
  /// **'Bereit zur Aufnahme'**
  String get readyToRecord;

  /// No description provided for @savingRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme wird gespeichert...'**
  String get savingRecording;

  /// No description provided for @predefinedPromptQuestionsName.
  ///
  /// In de, this message translates to:
  /// **'Fragen generieren'**
  String get predefinedPromptQuestionsName;

  /// No description provided for @predefinedPromptQuestionsTemplate.
  ///
  /// In de, this message translates to:
  /// **'Generiere 5-7 Verständnisfragen zum folgenden Text. Die Fragen sollen:\n- Verschiedene Schwierigkeitsgrade abdecken (einfach bis anspruchsvoll)\n- Sowohl Fakten als auch Zusammenhänge abfragen\n- Klar und präzise formuliert sein\n\nText:\n[[transcription]]'**
  String get predefinedPromptQuestionsTemplate;

  /// No description provided for @predefinedPromptActionItemsName.
  ///
  /// In de, this message translates to:
  /// **'Action Items'**
  String get predefinedPromptActionItemsName;

  /// No description provided for @predefinedPromptActionItemsTemplate.
  ///
  /// In de, this message translates to:
  /// **'Extrahiere alle Aufgaben und To-Dos aus dem folgenden Text.\n\nFormatiere die Ausgabe als strukturierte Liste:\n- Gruppiere nach Thema oder Verantwortlichkeit (falls erkennbar)\n- Markiere Deadlines oder Fristen (falls erwähnt)\n- Priorisiere nach Dringlichkeit (falls ableitbar)\n\nFalls keine konkreten Aufgaben erkennbar sind, gib dies an.\n\nText:\n[[transcription]]'**
  String get predefinedPromptActionItemsTemplate;

  /// No description provided for @predefinedPromptSummaryName.
  ///
  /// In de, this message translates to:
  /// **'Zusammenfassen'**
  String get predefinedPromptSummaryName;

  /// No description provided for @predefinedPromptSummaryTemplate.
  ///
  /// In de, this message translates to:
  /// **'Erstelle eine ausführliche und detaillierte Zusammenfassung des folgenden Textes.\n\nDie Zusammenfassung soll:\n- Strukturiert in thematische Abschnitte gegliedert sein\n- Alle wesentlichen Inhalte, Argumente und Erkenntnisse erfassen\n- Den Kontext, Zweck und die Schlussfolgerungen des Gesprächs/Textes verdeutlichen\n- Wichtige Details und Nuancen beibehalten\n\nVerwende Überschriften und Absätze für bessere Lesbarkeit.\n\nText:\n[[transcription]]'**
  String get predefinedPromptSummaryTemplate;

  /// No description provided for @predefinedPromptKeyPointsName.
  ///
  /// In de, this message translates to:
  /// **'Wichtige Punkte'**
  String get predefinedPromptKeyPointsName;

  /// No description provided for @predefinedPromptKeyPointsTemplate.
  ///
  /// In de, this message translates to:
  /// **'Liste die wichtigsten Punkte aus dem folgenden Text auf.\n\nFür jeden Punkt:\n- Formuliere eine klare Hauptaussage\n- Ergänze relevante Details, Begründungen oder Kontext\n- Erkläre die Bedeutung oder Implikation des Punktes\n\nAchte auf:\n- Maximal 5-10 Punkte\n- Priorisierung nach Relevanz\n\nText:\n[[transcription]]'**
  String get predefinedPromptKeyPointsTemplate;

  /// No description provided for @predefinedPromptDecisionsName.
  ///
  /// In de, this message translates to:
  /// **'Entscheidungen'**
  String get predefinedPromptDecisionsName;

  /// No description provided for @predefinedPromptDecisionsTemplate.
  ///
  /// In de, this message translates to:
  /// **'Extrahiere alle Entscheidungen aus dem folgenden Text.\n\nFür jede Entscheidung:\n- Was wurde entschieden?\n- Warum wurde so entschieden? (Begründung/Argumente)\n- Wer ist verantwortlich? (falls erkennbar)\n- Bis wann? (falls erwähnt)\n\nFalls keine klaren Entscheidungen getroffen wurden, liste die offenen Diskussionspunkte und ausstehenden Klärungen auf.\n\nText:\n[[transcription]]'**
  String get predefinedPromptDecisionsTemplate;

  /// No description provided for @predefinedPromptProContraName.
  ///
  /// In de, this message translates to:
  /// **'Pro & Contra'**
  String get predefinedPromptProContraName;

  /// No description provided for @predefinedPromptProContraTemplate.
  ///
  /// In de, this message translates to:
  /// **'Analysiere den folgenden Text und erstelle eine Pro & Contra Analyse.\n\nStruktur:\n- Thema oder Fragestellung identifizieren\n- Pro-Argumente mit Begründungen auflisten\n- Contra-Argumente mit Begründungen auflisten\n- Fazit oder Tendenz zusammenfassen (falls aus dem Gespräch erkennbar)\n\nText:\n[[transcription]]'**
  String get predefinedPromptProContraTemplate;

  /// No description provided for @predefinedPromptReportName.
  ///
  /// In de, this message translates to:
  /// **'Bericht erstellen'**
  String get predefinedPromptReportName;

  /// No description provided for @predefinedPromptReportTemplate.
  ///
  /// In de, this message translates to:
  /// **'Erstelle einen formellen Bericht basierend auf dem folgenden Text.\n\nStruktur:\n- Titel und Datum/Anlass (falls erkennbar)\n- Einleitung: Kontext und Zweck\n- Hauptteil: Besprochene Themen mit Kernaussagen und Details\n- Ergebnisse: Getroffene Entscheidungen und Vereinbarungen\n- Ausblick: Nächste Schritte und offene Punkte\n\nVerwende einen sachlichen, professionellen Stil.\n\nText:\n[[transcription]]'**
  String get predefinedPromptReportTemplate;

  /// No description provided for @predefinedPromptControversyName.
  ///
  /// In de, this message translates to:
  /// **'Kontroversen vertiefen'**
  String get predefinedPromptControversyName;

  /// No description provided for @predefinedPromptControversyTemplate.
  ///
  /// In de, this message translates to:
  /// **'Identifiziere kontroverse oder strittige Punkte aus dem folgenden Text und analysiere diese tiefgehend.\n\nFür jeden kontroversen Punkt:\n- Beschreibe den Streitpunkt und die verschiedenen Standpunkte\n- Analysiere die vorgebrachten Argumente jeder Seite\n- Ergänze wichtige Aspekte, die in der Diskussion zu kurz kamen oder fehlten\n- Liefere zusätzliche Fakten, Perspektiven oder Gegenargumente zur Vertiefung\n- Gib eine ausgewogene Einschätzung\n\nZiel ist es, eine fundierte Grundlage für die weitere Meinungsbildung zu schaffen.\n\nText:\n[[transcription]]'**
  String get predefinedPromptControversyTemplate;

  /// No description provided for @selectPrompt.
  ///
  /// In de, this message translates to:
  /// **'Prompt auswählen'**
  String get selectPrompt;

  /// No description provided for @apply.
  ///
  /// In de, this message translates to:
  /// **'Anwenden'**
  String get apply;

  /// No description provided for @noPromptsAvailable.
  ///
  /// In de, this message translates to:
  /// **'Keine Prompts verfügbar. Erstellen Sie einen im Prompts-Bereich.'**
  String get noPromptsAvailable;

  /// No description provided for @selectPromptForTranscription.
  ///
  /// In de, this message translates to:
  /// **'Wählen Sie einen Prompt für Ihre Transkription:'**
  String get selectPromptForTranscription;

  /// No description provided for @errorLoadingPrompts.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden der Prompts: {error}'**
  String errorLoadingPrompts(String error);

  /// No description provided for @noPredefinedPromptsAvailable.
  ///
  /// In de, this message translates to:
  /// **'Keine vordefinierten Prompts verfügbar.'**
  String get noPredefinedPromptsAvailable;

  /// No description provided for @noCustomPromptsAvailable.
  ///
  /// In de, this message translates to:
  /// **'Keine eigenen Prompts vorhanden.\n\nErstellen Sie Ihre eigenen Prompts unter \"Prompts\" in der Navigation.'**
  String get noCustomPromptsAvailable;

  /// No description provided for @generatingResponse.
  ///
  /// In de, this message translates to:
  /// **'Antwort wird generiert...'**
  String get generatingResponse;

  /// No description provided for @applying.
  ///
  /// In de, this message translates to:
  /// **'Wende an...'**
  String get applying;

  /// No description provided for @cancelled.
  ///
  /// In de, this message translates to:
  /// **'Abgebrochen'**
  String get cancelled;

  /// No description provided for @promptResultsCount.
  ///
  /// In de, this message translates to:
  /// **'Prompt-Ergebnisse ({count})'**
  String promptResultsCount(int count);

  /// No description provided for @deletePromptResult.
  ///
  /// In de, this message translates to:
  /// **'Prompt-Ergebnis löschen?'**
  String get deletePromptResult;

  /// No description provided for @deletePromptResultConfirmation.
  ///
  /// In de, this message translates to:
  /// **'Möchten Sie das Ergebnis \"{name}\" wirklich löschen?'**
  String deletePromptResultConfirmation(String name);

  /// No description provided for @promptResultDeleted.
  ///
  /// In de, this message translates to:
  /// **'{name} gelöscht'**
  String promptResultDeleted(String name);

  /// No description provided for @undo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get undo;

  /// No description provided for @promptLabel.
  ///
  /// In de, this message translates to:
  /// **'Prompt: {name}'**
  String promptLabel(String name);

  /// No description provided for @modelUsedLabel.
  ///
  /// In de, this message translates to:
  /// **'Modell: {model}'**
  String modelUsedLabel(String model);

  /// No description provided for @wordsLabel.
  ///
  /// In de, this message translates to:
  /// **'{count} Wörter'**
  String wordsLabel(int count);

  /// No description provided for @charactersLabel.
  ///
  /// In de, this message translates to:
  /// **'{count} Zeichen'**
  String charactersLabel(int count);

  /// No description provided for @showMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr anzeigen'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In de, this message translates to:
  /// **'Weniger anzeigen'**
  String get showLess;

  /// No description provided for @copy.
  ///
  /// In de, this message translates to:
  /// **'Kopieren'**
  String get copy;

  /// No description provided for @collapse.
  ///
  /// In de, this message translates to:
  /// **'Einklappen'**
  String get collapse;

  /// No description provided for @audioFileNotFoundWarning.
  ///
  /// In de, this message translates to:
  /// **'Die Audiodatei wurde nicht gefunden. Sie können die vorhandenen Ergebnisse ansehen, aber keine neue Transkription starten.'**
  String get audioFileNotFoundWarning;

  /// No description provided for @noResultsAvailable.
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse verfügbar'**
  String get noResultsAvailable;

  /// No description provided for @chatContext.
  ///
  /// In de, this message translates to:
  /// **'Chat-Kontext'**
  String get chatContext;

  /// No description provided for @chatContextDescription.
  ///
  /// In de, this message translates to:
  /// **'Wählen Sie, welche Inhalte der KI zur Verfügung stehen sollen.'**
  String get chatContextDescription;

  /// No description provided for @chatContextEnabledCount.
  ///
  /// In de, this message translates to:
  /// **'{count} von {total} aktiv'**
  String chatContextEnabledCount(int count, int total);

  /// No description provided for @sort.
  ///
  /// In de, this message translates to:
  /// **'Sortieren'**
  String get sort;

  /// No description provided for @sortDateNewest.
  ///
  /// In de, this message translates to:
  /// **'Datum (neueste zuerst)'**
  String get sortDateNewest;

  /// No description provided for @sortDateOldest.
  ///
  /// In de, this message translates to:
  /// **'Datum (älteste zuerst)'**
  String get sortDateOldest;

  /// No description provided for @sortNameAZ.
  ///
  /// In de, this message translates to:
  /// **'Name (A-Z)'**
  String get sortNameAZ;

  /// No description provided for @sortNameZA.
  ///
  /// In de, this message translates to:
  /// **'Name (Z-A)'**
  String get sortNameZA;

  /// No description provided for @sortDurationLongest.
  ///
  /// In de, this message translates to:
  /// **'Dauer (längste zuerst)'**
  String get sortDurationLongest;

  /// No description provided for @sortDurationShortest.
  ///
  /// In de, this message translates to:
  /// **'Dauer (kürzeste zuerst)'**
  String get sortDurationShortest;

  /// No description provided for @cancelTranscription.
  ///
  /// In de, this message translates to:
  /// **'Transkription abbrechen'**
  String get cancelTranscription;

  /// No description provided for @transcriptionCancelled.
  ///
  /// In de, this message translates to:
  /// **'Transkription abgebrochen'**
  String get transcriptionCancelled;

  /// No description provided for @stay.
  ///
  /// In de, this message translates to:
  /// **'Bleiben'**
  String get stay;

  /// No description provided for @discardRecordingTitle.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme verwerfen?'**
  String get discardRecordingTitle;

  /// No description provided for @discardRecordingContent.
  ///
  /// In de, this message translates to:
  /// **'Die Aufnahme ({duration}) wird gelöscht und kann nicht wiederhergestellt werden.'**
  String discardRecordingContent(String duration);

  /// No description provided for @discard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get discard;

  /// No description provided for @continueRecording.
  ///
  /// In de, this message translates to:
  /// **'Weiter aufnehmen'**
  String get continueRecording;

  /// No description provided for @apiKeyMissingTitle.
  ///
  /// In de, this message translates to:
  /// **'API-Schlüssel fehlt'**
  String get apiKeyMissingTitle;

  /// No description provided for @apiKeyMissingDescription.
  ///
  /// In de, this message translates to:
  /// **'Hinterlegen Sie einen OpenRouter-Schlüssel, um Aufnahmen zu transkribieren.'**
  String get apiKeyMissingDescription;

  /// No description provided for @setUp.
  ///
  /// In de, this message translates to:
  /// **'Einrichten'**
  String get setUp;

  /// No description provided for @errorStartingRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme konnte nicht gestartet werden: {error}'**
  String errorStartingRecording(String error);

  /// No description provided for @errorStoppingRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme konnte nicht beendet werden: {error}'**
  String errorStoppingRecording(String error);

  /// No description provided for @errorSavingRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme konnte nicht gespeichert werden'**
  String get errorSavingRecording;

  /// No description provided for @errorPausingRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme konnte nicht pausiert werden: {error}'**
  String errorPausingRecording(String error);

  /// No description provided for @errorResumingRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme konnte nicht fortgesetzt werden: {error}'**
  String errorResumingRecording(String error);

  /// No description provided for @errorCancellingRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme konnte nicht verworfen werden: {error}'**
  String errorCancellingRecording(String error);

  /// No description provided for @storagePermissionDeniedDefaultFolder.
  ///
  /// In de, this message translates to:
  /// **'Speicherberechtigung verweigert. Die Aufnahme wird im Standard-Ordner gespeichert.'**
  String get storagePermissionDeniedDefaultFolder;

  /// No description provided for @micPermissionTitle.
  ///
  /// In de, this message translates to:
  /// **'Mikrofon-Berechtigung erforderlich'**
  String get micPermissionTitle;

  /// No description provided for @micPermissionDescription.
  ///
  /// In de, this message translates to:
  /// **'VIOSA braucht Zugriff auf das Mikrofon, um aufnehmen zu können.'**
  String get micPermissionDescription;

  /// No description provided for @micPermissionRequired.
  ///
  /// In de, this message translates to:
  /// **'Mikrofonberechtigung erforderlich'**
  String get micPermissionRequired;

  /// No description provided for @checkAgain.
  ///
  /// In de, this message translates to:
  /// **'Erneut prüfen'**
  String get checkAgain;

  /// No description provided for @enterMessage.
  ///
  /// In de, this message translates to:
  /// **'Nachricht eingeben ...'**
  String get enterMessage;

  /// No description provided for @speakNow.
  ///
  /// In de, this message translates to:
  /// **'Sprechen ...'**
  String get speakNow;

  /// No description provided for @stopGeneration.
  ///
  /// In de, this message translates to:
  /// **'Generierung stoppen'**
  String get stopGeneration;

  /// No description provided for @noAudioFilesFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Audio-Dateien gefunden'**
  String get noAudioFilesFound;

  /// No description provided for @reload.
  ///
  /// In de, this message translates to:
  /// **'Erneut laden'**
  String get reload;

  /// No description provided for @noSearchResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Ergebnisse'**
  String get noSearchResults;

  /// No description provided for @noFilesMatchSearch.
  ///
  /// In de, this message translates to:
  /// **'Keine Dateien entsprechen Ihrer Suche.'**
  String get noFilesMatchSearch;

  /// No description provided for @errorLoadingFiles.
  ///
  /// In de, this message translates to:
  /// **'Dateien konnten nicht geladen werden: {error}'**
  String errorLoadingFiles(String error);

  /// No description provided for @processing.
  ///
  /// In de, this message translates to:
  /// **'Wird verarbeitet'**
  String get processing;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @showTranscription.
  ///
  /// In de, this message translates to:
  /// **'Transkription anzeigen'**
  String get showTranscription;

  /// No description provided for @errorRetrying.
  ///
  /// In de, this message translates to:
  /// **'Erneuter Versuch fehlgeschlagen: {error}'**
  String errorRetrying(String error);

  /// No description provided for @errorAuth.
  ///
  /// In de, this message translates to:
  /// **'API-Schlüssel ungültig. Bitte in den Einstellungen prüfen.'**
  String get errorAuth;

  /// No description provided for @errorRateLimit.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Anfragen. Bitte kurz warten und erneut versuchen.'**
  String get errorRateLimit;

  /// No description provided for @errorNetwork.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Bitte Internetverbindung prüfen.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In de, this message translates to:
  /// **'Zeitüberschreitung. Bitte erneut versuchen.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In de, this message translates to:
  /// **'Der Dienst ist gerade nicht erreichbar. Bitte später erneut versuchen.'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen. Bitte erneut versuchen.'**
  String get errorUnknown;

  /// No description provided for @errorApiKeyMissing.
  ///
  /// In de, this message translates to:
  /// **'Kein API-Schlüssel hinterlegt. Bitte in den Einstellungen eintragen.'**
  String get errorApiKeyMissing;

  /// No description provided for @errorUnknownWithDetails.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen: {details}'**
  String errorUnknownWithDetails(String details);

  /// No description provided for @errorServiceWithDetails.
  ///
  /// In de, this message translates to:
  /// **'Transkription fehlgeschlagen: {details}'**
  String errorServiceWithDetails(String details);

  /// No description provided for @errorAudioFileMissing.
  ///
  /// In de, this message translates to:
  /// **'Die Audiodatei ist nicht mehr vorhanden. Bitte die Datei erneut verknüpfen.'**
  String get errorAudioFileMissing;

  /// No description provided for @speechUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Spracherkennung nicht verfügbar'**
  String get speechUnavailable;

  /// No description provided for @speechInitError.
  ///
  /// In de, this message translates to:
  /// **'Spracherkennung konnte nicht gestartet werden'**
  String get speechInitError;

  /// No description provided for @speechRecognitionError.
  ///
  /// In de, this message translates to:
  /// **'Spracherkennung fehlgeschlagen'**
  String get speechRecognitionError;

  /// No description provided for @tapToStop.
  ///
  /// In de, this message translates to:
  /// **'Tippen zum Stoppen'**
  String get tapToStop;

  /// No description provided for @tapToSpeak.
  ///
  /// In de, this message translates to:
  /// **'Tippen zum Sprechen'**
  String get tapToSpeak;

  /// No description provided for @copiedToClipboard.
  ///
  /// In de, this message translates to:
  /// **'In Zwischenablage kopiert'**
  String get copiedToClipboard;

  /// No description provided for @regenerate.
  ///
  /// In de, this message translates to:
  /// **'Neu generieren'**
  String get regenerate;

  /// No description provided for @selectAudioFileTitle.
  ///
  /// In de, this message translates to:
  /// **'Audio-Datei auswählen'**
  String get selectAudioFileTitle;

  /// No description provided for @searchFilesHint.
  ///
  /// In de, this message translates to:
  /// **'Suchen...'**
  String get searchFilesHint;

  /// No description provided for @loadingAudioFiles.
  ///
  /// In de, this message translates to:
  /// **'Lade Audio-Dateien...'**
  String get loadingAudioFiles;

  /// No description provided for @browseAllFiles.
  ///
  /// In de, this message translates to:
  /// **'Andere Datei öffnen'**
  String get browseAllFiles;

  /// No description provided for @browseAllFilesHint.
  ///
  /// In de, this message translates to:
  /// **'Datei aus einem beliebigen Ordner oder Cloud-Speicher öffnen'**
  String get browseAllFilesHint;

  /// No description provided for @importingFile.
  ///
  /// In de, this message translates to:
  /// **'Datei wird übernommen...'**
  String get importingFile;

  /// No description provided for @unsupportedAudioFormat.
  ///
  /// In de, this message translates to:
  /// **'Dieses Dateiformat wird nicht unterstützt.'**
  String get unsupportedAudioFormat;

  /// No description provided for @storageAccessOptionalHint.
  ///
  /// In de, this message translates to:
  /// **'Ohne Speicherzugriff werden nur Aufnahmen der App angezeigt. Andere Dateien lassen sich weiterhin über \"Andere Datei öffnen\" laden.'**
  String get storageAccessOptionalHint;

  /// No description provided for @scanResultsTruncated.
  ///
  /// In de, this message translates to:
  /// **'Es werden nicht alle Dateien angezeigt. Suche eingrenzen oder \"Andere Datei öffnen\" nutzen.'**
  String get scanResultsTruncated;

  /// No description provided for @sortNewestShort.
  ///
  /// In de, this message translates to:
  /// **'Neueste'**
  String get sortNewestShort;

  /// No description provided for @sortOldestShort.
  ///
  /// In de, this message translates to:
  /// **'Älteste'**
  String get sortOldestShort;

  /// No description provided for @sortNameAZShort.
  ///
  /// In de, this message translates to:
  /// **'Name A-Z'**
  String get sortNameAZShort;

  /// No description provided for @sortNameZAShort.
  ///
  /// In de, this message translates to:
  /// **'Name Z-A'**
  String get sortNameZAShort;

  /// No description provided for @sortSizeDescShort.
  ///
  /// In de, this message translates to:
  /// **'Größe ↓'**
  String get sortSizeDescShort;

  /// No description provided for @sortSizeAscShort.
  ///
  /// In de, this message translates to:
  /// **'Größe ↑'**
  String get sortSizeAscShort;

  /// No description provided for @fileTypeAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get fileTypeAll;

  /// No description provided for @fileTypeOther.
  ///
  /// In de, this message translates to:
  /// **'Andere'**
  String get fileTypeOther;

  /// No description provided for @relinkAudioFile.
  ///
  /// In de, this message translates to:
  /// **'Datei erneut auswählen'**
  String get relinkAudioFile;

  /// No description provided for @audioFileRelinked.
  ///
  /// In de, this message translates to:
  /// **'Audiodatei neu verknüpft'**
  String get audioFileRelinked;

  /// No description provided for @errorImportingFile.
  ///
  /// In de, this message translates to:
  /// **'Datei konnte nicht übernommen werden: {error}'**
  String errorImportingFile(String error);

  /// No description provided for @transcriptionContinuesInBackground.
  ///
  /// In de, this message translates to:
  /// **'Transkription läuft im Hintergrund weiter'**
  String get transcriptionContinuesInBackground;

  /// No description provided for @transcriptionRunningBannerTitle.
  ///
  /// In de, this message translates to:
  /// **'Transkription läuft'**
  String get transcriptionRunningBannerTitle;

  /// No description provided for @openRunningTranscription.
  ///
  /// In de, this message translates to:
  /// **'Öffnen'**
  String get openRunningTranscription;

  /// No description provided for @promptGenerationRunningTitle.
  ///
  /// In de, this message translates to:
  /// **'Prompt läuft noch'**
  String get promptGenerationRunningTitle;

  /// No description provided for @promptGenerationRunningContent.
  ///
  /// In de, this message translates to:
  /// **'Wenn du die Sitzung verlässt, geht das laufende Ergebnis verloren.'**
  String get promptGenerationRunningContent;

  /// No description provided for @promptCancelled.
  ///
  /// In de, this message translates to:
  /// **'Generierung abgebrochen'**
  String get promptCancelled;

  /// No description provided for @errorSavingHistory.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis konnte nicht gespeichert werden: {error}'**
  String errorSavingHistory(String error);

  /// No description provided for @errorSharingResult.
  ///
  /// In de, this message translates to:
  /// **'Teilen fehlgeschlagen: {error}'**
  String errorSharingResult(String error);

  /// No description provided for @searchRecordings.
  ///
  /// In de, this message translates to:
  /// **'Aufnahmen durchsuchen'**
  String get searchRecordings;

  /// No description provided for @searchRecordingsHint.
  ///
  /// In de, this message translates to:
  /// **'Name oder Transkript durchsuchen'**
  String get searchRecordingsHint;

  /// No description provided for @noRecordingsMatchSearch.
  ///
  /// In de, this message translates to:
  /// **'Keine Aufnahme passt zur Suche'**
  String get noRecordingsMatchSearch;

  /// No description provided for @textSize.
  ///
  /// In de, this message translates to:
  /// **'Textgröße'**
  String get textSize;

  /// No description provided for @textSizeDescription.
  ///
  /// In de, this message translates to:
  /// **'Schriftgröße von Transkripten und Prompt-Ergebnissen'**
  String get textSizeDescription;

  /// No description provided for @storedData.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Daten'**
  String get storedData;

  /// No description provided for @clearAllHistory.
  ///
  /// In de, this message translates to:
  /// **'Alle Aufnahmen löschen'**
  String get clearAllHistory;

  /// No description provided for @clearAllHistoryConfirm.
  ///
  /// In de, this message translates to:
  /// **'Alle Aufnahmen, Transkripte und Chats werden dauerhaft gelöscht.'**
  String get clearAllHistoryConfirm;

  /// No description provided for @allHistoryCleared.
  ///
  /// In de, this message translates to:
  /// **'Alle Aufnahmen gelöscht'**
  String get allHistoryCleared;

  /// No description provided for @transcribeStyle.
  ///
  /// In de, this message translates to:
  /// **'Transkriptionsstil'**
  String get transcribeStyle;

  /// No description provided for @transcribeStyleClean.
  ///
  /// In de, this message translates to:
  /// **'Bereinigt'**
  String get transcribeStyleClean;

  /// No description provided for @transcribeStyleVerbatim.
  ///
  /// In de, this message translates to:
  /// **'Wortgetreu'**
  String get transcribeStyleVerbatim;

  /// No description provided for @transcribeStyleDescription.
  ///
  /// In de, this message translates to:
  /// **'Bereinigt entfernt Füllwörter, wortgetreu behält jedes gesprochene Wort'**
  String get transcribeStyleDescription;

  /// No description provided for @keywords.
  ///
  /// In de, this message translates to:
  /// **'Fachbegriffe'**
  String get keywords;

  /// No description provided for @keywordsDescription.
  ///
  /// In de, this message translates to:
  /// **'Namen und Fachbegriffe, die das Modell bevorzugt erkennen soll'**
  String get keywordsDescription;

  /// No description provided for @keywordsHint.
  ///
  /// In de, this message translates to:
  /// **'Begriff eingeben und bestätigen'**
  String get keywordsHint;

  /// No description provided for @keywordsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Begriffe hinterlegt'**
  String get keywordsEmpty;

  /// No description provided for @autoTranscribe.
  ///
  /// In de, this message translates to:
  /// **'Nach Aufnahme transkribieren'**
  String get autoTranscribe;

  /// No description provided for @autoTranscribeDescription.
  ///
  /// In de, this message translates to:
  /// **'Startet die Transkription direkt nach dem Ende einer Aufnahme'**
  String get autoTranscribeDescription;

  /// No description provided for @speakerLabel.
  ///
  /// In de, this message translates to:
  /// **'Sprecher {position}'**
  String speakerLabel(int position);

  /// No description provided for @timestamps.
  ///
  /// In de, this message translates to:
  /// **'Zeitmarken'**
  String get timestamps;

  /// No description provided for @jumpToPosition.
  ///
  /// In de, this message translates to:
  /// **'Zu dieser Stelle springen'**
  String get jumpToPosition;

  /// No description provided for @exportAsText.
  ///
  /// In de, this message translates to:
  /// **'Als Text teilen'**
  String get exportAsText;

  /// No description provided for @exportAsSubtitles.
  ///
  /// In de, this message translates to:
  /// **'Als Untertitel (SRT) teilen'**
  String get exportAsSubtitles;

  /// No description provided for @detectedLanguageLabel.
  ///
  /// In de, this message translates to:
  /// **'Erkannt: {language}'**
  String detectedLanguageLabel(String language);

  /// No description provided for @autoPrompt.
  ///
  /// In de, this message translates to:
  /// **'Prompt nach Transkription'**
  String get autoPrompt;

  /// No description provided for @autoPromptDescription.
  ///
  /// In de, this message translates to:
  /// **'Führt den gewählten Prompt automatisch aus, sobald ein Transkript fertig ist'**
  String get autoPromptDescription;

  /// No description provided for @autoPromptDisabled.
  ///
  /// In de, this message translates to:
  /// **'Deaktiviert'**
  String get autoPromptDisabled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
