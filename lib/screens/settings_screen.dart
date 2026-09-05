import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../models/model_config.dart';
import '../repositories/model_repository.dart';
import '../services/snackbar_service.dart';
import '../widgets/info_chip.dart';
import '../widgets/settings/setting_header.dart';
import '../widgets/settings/transcription_options_section.dart';
import '../l10n/l10n.dart';
import 'prompts_screen.dart';

/// Settings screen for configuring API key and language
/// Follows Single Responsibility Principle: Manages settings UI
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  String _selectedLanguage = 'auto';
  String? _audioSavePath;
  String _selectedThemeMode = 'system';
  bool _isApiKeyVisible = false;
  bool _isAboutSectionExpanded = false;
  bool _isApiKeyValid = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final settingsProvider = context.read<SettingsProvider>();

    if (settingsProvider.apiKey != null) {
      _apiKeyController.text = settingsProvider.apiKey!;
      _validateApiKey(settingsProvider.apiKey!);
    }
    _selectedLanguage = settingsProvider.language;
    _audioSavePath = settingsProvider.audioSavePath;
    _selectedThemeMode = settingsProvider.themeModeString;
  }

  void _validateApiKey(String key) {
    setState(() {
      _isApiKeyValid = key.trim().startsWith('sk-or-v1-') && key.trim().length > 20;
    });
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) return;

    try {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.saveApiKey(apiKey);
    } catch (e) {
      debugPrint('Error saving API key: $e');
    }
  }

  Future<void> _saveLanguage(String language) async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.saveLanguage(language);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.errorSavingLanguage(e.toString()));
      }
    }
  }

  Future<void> _saveThemeMode(String themeMode) async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.saveThemeMode(themeMode);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.errorSavingTheme(e.toString()));
      }
    }
  }

  Future<bool> _validateBeforeExit() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isNotEmpty) {
      await _saveApiKey();
    }
    return true;
  }

  Future<void> _selectAudioSavePath() async {
    try {
      final settingsProvider = context.read<SettingsProvider>();

      if (Platform.isAndroid) {
        final permissionGranted = await _requestStoragePermission();
        if (!permissionGranted) {
          if (mounted) {
            _showErrorSnackBar(context.l10n.storagePermissionRequired);
          }
          return;
        }
      }

      final String? selectedDirectory = await FilePicker.getDirectoryPath();

      if (selectedDirectory != null) {
        if (mounted) {
          setState(() {
            _audioSavePath = selectedDirectory;
          });

          await settingsProvider.saveAudioSavePath(selectedDirectory);

          if (mounted) {
            _showSuccessSnackBar(context.l10n.storageSavedSuccess);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.errorSelectingFolder(e.toString()));
      }
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    final legacyStatus = await Permission.storage.request();
    if (legacyStatus.isGranted) {
      return true;
    }

    return false;
  }

  void _showErrorSnackBar(String message) {
    SnackBarService().showError(context, message);
  }

  void _showSuccessSnackBar(String message) {
    SnackBarService().showSuccess(context, message);
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showErrorSnackBar(context.l10n.errorOpeningUrl(url));
      }
    }
  }

  String _getLanguageName(BuildContext context, String code) {
    switch (code) {
      case 'auto':
        return context.l10n.transcriptionLanguageAuto;
      case 'de':
        return context.l10n.transcriptionLanguageGerman;
      case 'en':
        return context.l10n.transcriptionLanguageEnglish;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final canExit = await _validateBeforeExit();
        if (canExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.settings),
            ),
            body: settingsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildApiConfigCard(context),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildModelSelectionCard(context),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildAudioTranscriptionCard(context),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildLanguageCard(context),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildAppearanceCard(context),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildTextSizeCard(context),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildDataCard(context),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildPromptsCard(context),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildAboutCard(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApiConfigCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.key,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.apiConfiguration,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: context.l10n.apiKeyLabel,
                hintText: context.l10n.apiKeyHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isApiKeyValid)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    IconButton(
                      icon: Icon(
                        _isApiKeyVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isApiKeyVisible = !_isApiKeyVisible;
                        });
                      },
                      tooltip: _isApiKeyVisible
                          ? context.l10n.hideApiKey
                          : context.l10n.showApiKey,
                    ),
                  ],
                ),
              ),
              obscureText: !_isApiKeyVisible,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (value) {
                _validateApiKey(value);
                if (value.trim().isNotEmpty) {
                  _saveApiKey();
                }
              },
            ),
            const SizedBox(height: AppSpacing.s),
            InkWell(
              onTap: () => _launchURL('https://openrouter.ai/keys'),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${context.l10n.apiKeyHelp} ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      TextSpan(
                        text: 'openrouter.ai',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelectionCard(BuildContext context) {
    const transcriptionModel = ModelRepository.transcriptionModel;
    final llmModel = ModelRepository.defaultModel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.memory,
                  size: AppIconSize.medium,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  context.l10n.modelsSectionTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            _buildModelRow(
              context,
              icon: Icons.record_voice_over,
              label: context.l10n.speechToTextModelLabel,
              model: transcriptionModel,
            ),
            const SizedBox(height: AppSpacing.s),
            _buildModelRow(
              context,
              icon: Icons.auto_awesome,
              label: context.l10n.languageModelLabel,
              model: llmModel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ModelConfig model,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: AppOpacity.secondary),
                ),
          ),
        ),
        InfoChip(
          label: model.name,
          icon: icon,
        ),
      ],
    );
  }

  Widget _buildAudioTranscriptionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_voice,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.audioTranscription,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.folder,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.storageLocation,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _audioSavePath ?? context.l10n.defaultStorageLocation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _selectAudioSavePath,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text(context.l10n.choose),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            const Divider(),
            const SizedBox(height: AppSpacing.m),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.transcriptionLanguage,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InfoChip(
                      label: _getLanguageName(context, _selectedLanguage),
                      icon: Icons.translate,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.indent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        initialValue: _selectedLanguage,
                        items: AppConstants.supportedLanguages
                            .map(
                              (lang) => DropdownMenuItem(
                                value: lang.code,
                                child: Text(_getLanguageName(context, lang.code)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                            _saveLanguage(value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.transcriptionLanguageDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const TranscriptionOptionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeCard(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_size,
                  size: AppIconSize.medium,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  context.l10n.textSize,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settingsProvider.textSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    label: settingsProvider.textSize.round().toString(),
                    onChanged: (value) => settingsProvider.saveTextSize(value),
                  ),
                ),
                Text(
                  settingsProvider.textSize.round().toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            SettingDescription(context.l10n.textSizeDescription),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  size: AppIconSize.medium,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  context.l10n.storedData,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _confirmClearHistory,
                icon: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  context.l10n.clearAllHistory,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.clearAllHistory),
        content: Text(ctx.l10n.clearAllHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(ctx.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context.read<HistoryProvider>().clearAllHistory();
    if (!mounted) return;
    SnackBarService().showSuccess(context, context.l10n.allHistoryCleared);
  }

  Widget _buildLanguageCard(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final selectedUiLanguage = settingsProvider.uiLanguage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.translate,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.uiLanguage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageButton(
                    context: context,
                    label: context.l10n.languageGerman,
                    value: 'de',
                    isSelected: selectedUiLanguage == 'de',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLanguageButton(
                    context: context,
                    label: context.l10n.languageEnglish,
                    value: 'en',
                    isSelected: selectedUiLanguage == 'en',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              context.l10n.uiLanguageDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton({
    required BuildContext context,
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        context.read<SettingsProvider>().saveUiLanguage(value);
      },
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.appearance,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.brightness_6,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.theme,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildThemeModeButton(
                              context: context,
                              icon: Icons.brightness_auto,
                              label: context.l10n.themeSystem,
                              value: 'system',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildThemeModeButton(
                              context: context,
                              icon: Icons.light_mode,
                              label: context.l10n.themeLight,
                              value: 'light',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildThemeModeButton(
                              context: context,
                              icon: Icons.dark_mode,
                              label: context.l10n.themeDark,
                              value: 'dark',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        context.l10n.themeDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSelected = _selectedThemeMode == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedThemeMode = value;
        });
        _saveThemeMode(value);
      },
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptsCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromptsScreen()),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.promptsManage,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.promptsDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () {
          setState(() {
            _isAboutSectionExpanded = !_isAboutSectionExpanded;
          });
        },
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.aboutViosa,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isAboutSectionExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              if (_isAboutSectionExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.aboutDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  context.l10n.apiKeySecurityNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  context.l10n.version('1.0.0'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
