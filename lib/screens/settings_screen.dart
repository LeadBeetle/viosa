import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../repositories/model_repository.dart';
import '../services/snackbar_service.dart';
import '../widgets/info_chip.dart';

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
  String _selectedModel = ModelRepository.defaultModelId;
  bool _isApiKeyVisible = false;
  bool _isModelSectionExpanded = false;
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
    _selectedModel = settingsProvider.selectedModel;
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
        _showErrorSnackBar('Fehler beim Speichern der Sprache: $e');
      }
    }
  }

  Future<void> _saveModel(String model) async {
    try {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.saveModel(model);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Speichern des Modells: $e');
      }
    }
  }

  Future<bool> _validateBeforeExit() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      _showErrorSnackBar('Bitte geben Sie einen API-Key ein');
      return false;
    }

    await _saveApiKey();
    return true;
  }

  Future<void> _selectAudioSavePath() async {
    try {
      final settingsProvider = context.read<SettingsProvider>();

      if (Platform.isAndroid) {
        final permissionGranted = await _requestStoragePermission();
        if (!permissionGranted) {
          if (mounted) {
            _showErrorSnackBar('Speicherberechtigung erforderlich. Bitte erlauben Sie den Zugriff in den App-Einstellungen.');
          }
          return;
        }
      }

      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        if (mounted) {
          setState(() {
            _audioSavePath = selectedDirectory;
          });

          await settingsProvider.saveAudioSavePath(selectedDirectory);

          _showSuccessSnackBar('Speicherort erfolgreich gespeichert');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Auswählen des Ordners: $e');
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
        _showErrorSnackBar('URL konnte nicht geöffnet werden: $url');
      }
    }
  }

  String _getLanguageName(String code) {
    final language = AppConstants.supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppConstants.supportedLanguages.first,
    );
    return language.name;
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
              title: const Text('Einstellungen'),
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
                  'API-Konfiguration',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'OpenRouter API-Key',
                hintText: 'sk-or-v1-...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isApiKeyValid)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.tertiary,
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
                          ? 'API-Key verbergen'
                          : 'API-Key anzeigen',
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
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchURL('https://openrouter.ai/keys'),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Holen Sie sich Ihren API-Key von ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'openrouter.ai',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelectionCard(BuildContext context) {
    final selectedModel = AppConstants.supportedModels.firstWhere(
      (m) => m.id == _selectedModel,
      orElse: () => AppConstants.supportedModels.first,
    );

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isModelSectionExpanded = !_isModelSectionExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.memory,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KI-Modell',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Aktuell: ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            InfoChip(
                              label: selectedModel.name,
                              icon: Icons.auto_awesome,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isModelSectionExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_isModelSectionExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wählen Sie das Modell für Transkription und Prompts',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...AppConstants.supportedModels.map((model) {
                    final isSelected = _selectedModel == model.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedModel = model.id;
                          });
                          _saveModel(model.id);
                        },
                        borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.5),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(
                                AppConstants.defaultBorderRadius),
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.3)
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: model.id,
                                  groupValue: _selectedModel,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedModel = value;
                                      });
                                      _saveModel(value);
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              model.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: model.provider == 'Google'
                                                  ? Colors.blue.withOpacity(0.1)
                                                  : Colors.orange
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              model.provider,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: model.provider ==
                                                            'Google'
                                                        ? Colors.blue.shade700
                                                        : Colors
                                                            .orange.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            model.tier == 'Schnell & günstig'
                                                ? Icons.flash_on
                                                : model.tier == 'Ausgewogen'
                                                    ? Icons.balance
                                                    : Icons.star,
                                            size: 14,
                                            color: model.tier ==
                                                    'Schnell & günstig'
                                                ? Colors.green
                                                : model.tier == 'Ausgewogen'
                                                    ? Colors.blue
                                                    : Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            model.tier,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: model.tier ==
                                                          'Schnell & günstig'
                                                      ? Colors.green
                                                      : model.tier ==
                                                              'Ausgewogen'
                                                          ? Colors.blue
                                                          : Colors.amber,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        model.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
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
                  'Audio & Transkription',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.folder,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Speicherort für Aufnahmen',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _audioSavePath ?? 'Standard-Speicherort',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
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
                  label: const Text('Wählen'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.language,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sprache',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InfoChip(
                            label: _getLanguageName(_selectedLanguage),
                            icon: Icons.translate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: _selectedLanguage,
                        items: AppConstants.supportedLanguages
                            .map(
                              (lang) => DropdownMenuItem(
                                value: lang.code,
                                child: Text(lang.name),
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
                      const SizedBox(height: 4),
                      Text(
                        'Wählen Sie die Sprache für die Transkription',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
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
                      'Über VIOSA',
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
                  'VIOSA (Voice Intelligent Output and Speech Analyzer) nutzt die OpenRouter API für Audio-Transkription mit modernsten KI-Modellen.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ihr API-Key wird sicher auf Ihrem Gerät gespeichert und niemals an Dritte weitergegeben.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
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
