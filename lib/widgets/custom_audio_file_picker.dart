import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/l10n.dart';
import '../models/audio_file_info.dart';
import '../services/audio_file_scanner_service.dart';
import '../services/i_audio_file_scanner_service.dart';
import '../utils/audio_formats.dart';
import '../utils/constants.dart';
import 'audio_file_item.dart';

/// Sortierreihenfolge der Dateiliste.
enum SortOption {
  newestFirst,
  oldestFirst,
  nameAZ,
  nameZA,
  sizeDesc,
  sizeAsc,
}

/// Filter für gängige Audioformate.
enum AudioFileType {
  all,
  mp3,
  wav,
  m4a,
  other,
}

/// Dateiauswahl für Audiodateien.
///
/// Zeigt die Dateien aus den bekannten Verzeichnissen und erlaubt über die
/// Systemauswahl zusätzlich den Zugriff auf jeden anderen Ordner, damit
/// Dateien nicht außerhalb der App verschoben werden müssen.
class CustomAudioFilePicker extends StatefulWidget {
  final IAudioFileScannerService? scannerService;

  const CustomAudioFilePicker({super.key, this.scannerService});

  @override
  State<CustomAudioFilePicker> createState() => _CustomAudioFilePickerState();
}

class _CustomAudioFilePickerState extends State<CustomAudioFilePicker> {
  static const double _filterBarHeight = 50.0;
  static const double _headerHeight = 170.0;
  static const int _maxFilesPerDirectory = 200;

  late final IAudioFileScannerService _scannerService =
      widget.scannerService ?? AudioFileScannerService();

  final TextEditingController _searchController = TextEditingController();

  List<AudioFileInfo> _audioFiles = [];
  List<AudioFileInfo> _filteredFiles = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _isTruncated = false;
  String? _errorMessage;
  SortOption _currentSort = SortOption.newestFirst;
  AudioFileType _selectedFileType = AudioFileType.all;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fragt die Berechtigung an und lädt danach die Dateien.
  ///
  /// Eine abgelehnte Berechtigung blockiert die Auswahl nicht: die
  /// App-eigenen Aufnahmen bleiben sichtbar und die Systemauswahl bleibt
  /// erreichbar.
  Future<void> _checkPermissionAndLoadFiles() async {
    final hasPermission = await _requestStoragePermission();
    if (!mounted) return;

    setState(() {
      _hasPermission = hasPermission;
    });

    await _loadAudioFiles();
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    if (await Permission.audio.isGranted ||
        await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    if (await Permission.audio.request().isGranted) {
      return true;
    }

    return await Permission.storage.request().isGranted;
  }

  Future<void> _loadAudioFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _scannerService.getAllAudioFiles(
        recursive: true,
        maxFilesPerDirectory: _maxFilesPerDirectory,
      );
      if (!mounted) return;

      setState(() {
        _audioFiles = result.files;
        _isTruncated = result.truncated;
        _isLoading = false;
        _errorMessage =
            result.files.isEmpty ? context.l10n.noAudioFilesFound : null;
      });
      _filterFiles(_searchController.text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.errorLoadingFiles(e.toString());
      });
    }
  }

  /// Öffnet die Systemauswahl, damit jede Datei unabhängig vom Ordner
  /// gewählt werden kann.
  Future<void> _browseWithSystemPicker() async {
    try {
      final result = await FilePicker.pickFile(type: FileType.audio);

      final path = result?.path;
      if (path == null || !mounted) return;

      if (!AudioFormats.isSupportedPath(path)) {
        _showMessage(context.l10n.unsupportedAudioFormat);
        return;
      }

      final fileInfo = await AudioFileInfo.fromFile(File(path));
      if (!mounted) return;

      Navigator.of(context).pop(fileInfo);
    } catch (e) {
      if (!mounted) return;
      _showMessage(context.l10n.errorLoadingFiles(e.toString()));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  void _sortFiles(SortOption option) {
    setState(() {
      _currentSort = option;
      _applySort();
    });
  }

  void _applySort() {
    switch (_currentSort) {
      case SortOption.newestFirst:
        _filteredFiles.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
        break;
      case SortOption.oldestFirst:
        _filteredFiles.sort((a, b) => a.modifiedDate.compareTo(b.modifiedDate));
        break;
      case SortOption.nameAZ:
        _filteredFiles
            .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameZA:
        _filteredFiles
            .sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.sizeDesc:
        _filteredFiles.sort((a, b) => b.size.compareTo(a.size));
        break;
      case SortOption.sizeAsc:
        _filteredFiles.sort((a, b) => a.size.compareTo(b.size));
        break;
    }
  }

  void _filterFiles(String query) {
    setState(() {
      final typeFiltered = _filterByFileType(_audioFiles, _selectedFileType);
      final normalizedQuery = query.trim().toLowerCase();

      _filteredFiles = normalizedQuery.isEmpty
          ? typeFiltered
          : typeFiltered
              .where((file) => file.name.toLowerCase().contains(normalizedQuery))
              .toList();

      _applySort();
    });
  }

  List<AudioFileInfo> _filterByFileType(
    List<AudioFileInfo> files,
    AudioFileType type,
  ) {
    if (type == AudioFileType.all) {
      return List<AudioFileInfo>.from(files);
    }

    return files.where((file) {
      final extension = file.extension.toLowerCase();
      switch (type) {
        case AudioFileType.all:
          return true;
        case AudioFileType.mp3:
          return extension == 'mp3';
        case AudioFileType.wav:
          return extension == 'wav';
        case AudioFileType.m4a:
          return extension == 'm4a' || extension == 'mp4';
        case AudioFileType.other:
          return !['mp3', 'wav', 'm4a', 'mp4'].contains(extension);
      }
    }).toList();
  }

  void _changeFileTypeFilter(AudioFileType type) {
    setState(() {
      _selectedFileType = type;
    });
    _filterFiles(_searchController.text);
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.newestFirst:
        return context.l10n.sortNewestShort;
      case SortOption.oldestFirst:
        return context.l10n.sortOldestShort;
      case SortOption.nameAZ:
        return context.l10n.sortNameAZShort;
      case SortOption.nameZA:
        return context.l10n.sortNameZAShort;
      case SortOption.sizeDesc:
        return context.l10n.sortSizeDescShort;
      case SortOption.sizeAsc:
        return context.l10n.sortSizeAscShort;
    }
  }

  String _getFileTypeLabel(AudioFileType type) {
    switch (type) {
      case AudioFileType.all:
        return context.l10n.fileTypeAll;
      case AudioFileType.mp3:
        return 'MP3';
      case AudioFileType.wav:
        return 'WAV';
      case AudioFileType.m4a:
        return 'M4A/MP4';
      case AudioFileType.other:
        return context.l10n.fileTypeOther;
    }
  }

  IconData _getFileTypeIcon(AudioFileType type) {
    switch (type) {
      case AudioFileType.all:
        return Icons.audio_file;
      case AudioFileType.mp3:
      case AudioFileType.m4a:
        return Icons.music_note;
      case AudioFileType.wav:
        return Icons.graphic_eq;
      case AudioFileType.other:
        return Icons.audio_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.selectAudioFileTitle),
        actions: [
          IconButton(
            onPressed: _browseWithSystemPicker,
            icon: const Icon(Icons.folder_open),
            tooltip: context.l10n.browseAllFilesHint,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(_headerHeight),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.l10n.searchFilesHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterFiles('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    filled: true,
                  ),
                  onChanged: _filterFiles,
                ),
              ),
              _buildChipBar(
                AudioFileType.values.map((type) {
                  return FilterChip(
                    avatar: Icon(
                      _getFileTypeIcon(type),
                      size: AppIconSize.medium,
                    ),
                    label: Text(_getFileTypeLabel(type)),
                    selected: _selectedFileType == type,
                    onSelected: (selected) {
                      if (selected) {
                        _changeFileTypeFilter(type);
                      }
                    },
                  );
                }),
              ),
              _buildChipBar(
                SortOption.values.map((option) {
                  return FilterChip(
                    label: Text(_getSortLabel(option)),
                    selected: _currentSort == option,
                    onSelected: (selected) {
                      if (selected) {
                        _sortFiles(option);
                      }
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (!_hasPermission) _buildPermissionBanner(),
          if (_isTruncated) _buildTruncationBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _browseWithSystemPicker,
        icon: const Icon(Icons.folder_open),
        label: Text(context.l10n.browseAllFiles),
      ),
    );
  }

  Widget _buildChipBar(Iterable<Widget> chips) {
    return SizedBox(
      height: _filterBarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        children: chips
            .map((chip) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s),
                  child: chip,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPermissionBanner() {
    return MaterialBanner(
      content: Text(context.l10n.storageAccessOptionalHint),
      leading: const Icon(Icons.folder_off),
      actions: [
        TextButton(
          onPressed: _checkPermissionAndLoadFiles,
          child: Text(context.l10n.grantPermission),
        ),
        TextButton(
          onPressed: _openAppSettings,
          child: Text(context.l10n.openSettings),
        ),
      ],
    );
  }

  Widget _buildTruncationBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: AppIconSize.small,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: AppOpacity.secondary),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              context.l10n.scanResultsTruncated,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.m),
            Text(context.l10n.loadingAudioFiles),
          ],
        ),
      );
    }

    if (_filteredFiles.isEmpty) {
      final isSearching = _searchController.text.trim().isNotEmpty ||
          _selectedFileType != AudioFileType.all;

      return _buildEmptyState(
        icon: isSearching ? Icons.search_off : Icons.music_note,
        title: isSearching
            ? context.l10n.noSearchResults
            : context.l10n.noAudioFilesFound,
        message: isSearching
            ? context.l10n.noFilesMatchSearch
            : (_errorMessage ?? context.l10n.browseAllFilesHint),
        action: isSearching
            ? null
            : FilledButton.icon(
                onPressed: _loadAudioFiles,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.reload),
              ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.s),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final fileInfo = _filteredFiles[index];
        return AudioFileItem(
          fileInfo: fileInfo,
          onTap: () => Navigator.of(context).pop(fileInfo),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppIconSize.emptyState,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: AppOpacity.tertiary),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.l),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
