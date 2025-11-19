import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../repositories/model_repository.dart';
import '../services/snackbar_service.dart';

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
  bool _isSaving = false;
  bool _isApiKeyVisible = false;

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
    }
    _selectedLanguage = settingsProvider.language;
    _audioSavePath = settingsProvider.audioSavePath;
    _selectedModel = settingsProvider.selectedModel;
  }

  Future<void> _saveSettings() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      _showErrorSnackBar('Bitte geben Sie einen API-Key ein');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final settingsProvider = context.read<SettingsProvider>();

      await settingsProvider.saveApiKey(apiKey);
      await settingsProvider.saveLanguage(_selectedLanguage);
      await settingsProvider.saveModel(_selectedModel);

      if (_audioSavePath != null && _audioSavePath!.isNotEmpty) {
        await settingsProvider.saveAudioSavePath(_audioSavePath!);
      }

      if (mounted) {
        _showSuccessSnackBar('Einstellungen erfolgreich gespeichert');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Speichern der Einstellungen: $e');
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _selectAudioSavePath() async {
    try {
      final settingsProvider = context.read<SettingsProvider>();

      // Request storage permissions before allowing folder selection
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

          // Immediately save the selected path
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

  /// Request storage permission for Android devices
  Future<bool> _requestStoragePermission() async {
    // Check if already granted
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
    final status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      return true;
    }

    // If permanently denied, open app settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    // Try legacy storage permission for older Android versions
    final legacyStatus = await Permission.storage.request();
    if (legacyStatus.isGranted) {
      return true;
    }

    return false;
  }

  void _showErrorSnackBar(String message) {
    SnackBarService.showError(context, message);
  }

  void _showSuccessSnackBar(String message) {
    SnackBarService.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API-Konfiguration',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _apiKeyController,
                            decoration: InputDecoration(
                              labelText: 'OpenRouter API-Key',
                              hintText: 'sk-or-v1-...',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.key),
                              suffixIcon: IconButton(
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
                            ),
                            obscureText: !_isApiKeyVisible,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Holen Sie sich Ihren API-Key von openrouter.ai',
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
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KI-Modell',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
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
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
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
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      model.name,
                                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                          ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: model.provider == 'Google'
                                                          ? Colors.blue.withOpacity(0.1)
                                                          : Colors.orange.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      model.provider,
                                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                            color: model.provider == 'Google'
                                                                ? Colors.blue.shade700
                                                                : Colors.orange.shade700,
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
                                                    color: model.tier == 'Schnell & günstig'
                                                        ? Colors.green
                                                        : model.tier == 'Ausgewogen'
                                                            ? Colors.blue
                                                            : Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    model.tier,
                                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                          color: model.tier == 'Schnell & günstig'
                                                              ? Colors.green
                                                              : model.tier == 'Ausgewogen'
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
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio-Einstellungen',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Speicherort für Aufnahmen',
                                      style: Theme.of(context).textTheme.bodyLarge,
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
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Wählen'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transkriptions-Einstellungen',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Sprache',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.language),
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
                              }
                            },
                          ),
                          const SizedBox(height: 8),
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
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Speichere...' : 'Einstellungen speichern'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                              Text(
                                'Über VIOSA',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'VIOSA nutzt die OpenRouter API für Audio-Transkription. '
                            'Ihr API-Key wird sicher auf Ihrem Gerät gespeichert.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        );
      },
    );
  }
}
