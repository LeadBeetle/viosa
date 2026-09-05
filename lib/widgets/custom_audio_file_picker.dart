import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/audio_file_info.dart';
import '../services/audio_file_scanner_service.dart';
import '../l10n/l10n.dart';
import 'audio_file_item.dart';

/// Enum for sort options
enum SortOption {
  newestFirst,
  oldestFirst,
  nameAZ,
  nameZA,
  sizeDesc,
  sizeAsc,
}

/// Common audio file type categories for filtering
enum AudioFileType {
  all,
  mp3,
  wav,
  m4a,
  other,
}

/// Custom audio file picker with date-based sorting
/// Provides full control over file selection UX
class CustomAudioFilePicker extends StatefulWidget {
  const CustomAudioFilePicker({super.key});

  @override
  State<CustomAudioFilePicker> createState() => _CustomAudioFilePickerState();
}

class _CustomAudioFilePickerState extends State<CustomAudioFilePicker> {
  final AudioFileScannerService _scannerService = AudioFileScannerService();

  List<AudioFileInfo> _audioFiles = [];
  List<AudioFileInfo> _filteredFiles = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;
  SortOption _currentSort = SortOption.newestFirst;
  AudioFileType _selectedFileType = AudioFileType.all;
  final TextEditingController _searchController = TextEditingController();

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

  /// Check permissions and load audio files
  Future<void> _checkPermissionAndLoadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check and request permissions
    final hasPermission = await _requestStoragePermission();
    if (!mounted) return;

    if (!hasPermission) {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
        _errorMessage = context.l10n.storagePermissionRequired;
      });
      return;
    }

    setState(() {
      _hasPermission = true;
    });

    // Load audio files
    await _loadAudioFiles();
  }

  /// Request storage permission based on platform and Android version
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) {
      // iOS doesn't need explicit storage permissions
      return true;
    }

    // Check if already granted
    if (await Permission.audio.isGranted ||
        await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Request appropriate permission
    PermissionStatus status = await Permission.audio.request();
    if (status.isGranted) {
      return true;
    }

    // Fallback to storage permission for older devices
    status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    }

    // If permanently denied, open settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  /// Load audio files from common directories
  Future<void> _loadAudioFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await _scannerService.getAllAudioFiles(
        recursive: true,
        maxFilesPerDirectory: 200,
      );
      if (!mounted) return;

      setState(() {
        _audioFiles = files;
        _filteredFiles = files;
        _isLoading = false;
      });

      if (files.isEmpty) {
        setState(() {
          _errorMessage = context.l10n.noAudioFilesFound;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.errorLoadingFiles(e.toString());
      });
    }
  }

  /// Sort files based on selected option
  void _sortFiles(SortOption option) {
    setState(() {
      _currentSort = option;

      switch (option) {
        case SortOption.newestFirst:
          _filteredFiles.sort((a, b) => b.createdDate.compareTo(a.createdDate));
          break;
        case SortOption.oldestFirst:
          _filteredFiles.sort((a, b) => a.createdDate.compareTo(b.createdDate));
          break;
        case SortOption.nameAZ:
          _filteredFiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case SortOption.nameZA:
          _filteredFiles.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case SortOption.sizeDesc:
          _filteredFiles.sort((a, b) => b.size.compareTo(a.size));
          break;
        case SortOption.sizeAsc:
          _filteredFiles.sort((a, b) => a.size.compareTo(b.size));
          break;
      }
    });
  }

  /// Filter files based on search query and file type
  void _filterFiles(String query) {
    setState(() {
      // First filter by file type
      List<AudioFileInfo> typeFiltered = _filterByFileType(_audioFiles, _selectedFileType);

      // Then filter by search query
      if (query.isEmpty) {
        _filteredFiles = typeFiltered;
      } else {
        _filteredFiles = typeFiltered.where((file) {
          return file.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
      // Re-apply current sort
      _sortFiles(_currentSort);
    });
  }

  /// Filter files by file type
  List<AudioFileInfo> _filterByFileType(List<AudioFileInfo> files, AudioFileType type) {
    if (type == AudioFileType.all) {
      return files;
    }

    return files.where((file) {
      final ext = file.extension.toLowerCase();
      switch (type) {
        case AudioFileType.all:
          return true;
        case AudioFileType.mp3:
          return ext == 'mp3';
        case AudioFileType.wav:
          return ext == 'wav';
        case AudioFileType.m4a:
          return ext == 'm4a' || ext == 'mp4';
        case AudioFileType.other:
          return !['mp3', 'wav', 'm4a', 'mp4'].contains(ext);
      }
    }).toList();
  }

  /// Change file type filter
  void _changeFileTypeFilter(AudioFileType type) {
    setState(() {
      _selectedFileType = type;
    });
    _filterFiles(_searchController.text);
  }

  /// Get label for sort option
  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.newestFirst:
        return 'Neueste';
      case SortOption.oldestFirst:
        return 'Älteste';
      case SortOption.nameAZ:
        return 'Name A-Z';
      case SortOption.nameZA:
        return 'Name Z-A';
      case SortOption.sizeDesc:
        return 'Größe ↓';
      case SortOption.sizeAsc:
        return 'Größe ↑';
    }
  }

  /// Get label for file type
  String _getFileTypeLabel(AudioFileType type) {
    switch (type) {
      case AudioFileType.all:
        return 'Alle';
      case AudioFileType.mp3:
        return 'MP3';
      case AudioFileType.wav:
        return 'WAV';
      case AudioFileType.m4a:
        return 'M4A/MP4';
      case AudioFileType.other:
        return 'Andere';
    }
  }

  /// Get icon for file type
  IconData _getFileTypeIcon(AudioFileType type) {
    switch (type) {
      case AudioFileType.all:
        return Icons.audio_file;
      case AudioFileType.mp3:
        return Icons.music_note;
      case AudioFileType.wav:
        return Icons.graphic_eq;
      case AudioFileType.m4a:
        return Icons.music_note;
      case AudioFileType.other:
        return Icons.audio_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio-Datei auswählen'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(170),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Suchen...',
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: _filterFiles,
                ),
              ),
              // File type filter chips
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: AudioFileType.values.map((type) {
                    final isSelected = _selectedFileType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          _getFileTypeIcon(type),
                          size: 18,
                        ),
                        label: Text(_getFileTypeLabel(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _changeFileTypeFilter(type);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Sort chips
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: SortOption.values.map((option) {
                    final isSelected = _currentSort == option;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getSortLabel(option)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _sortFiles(option);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Lade Audio-Dateien...'),
          ],
        ),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Zugriff benötigt',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'VIOSA benötigt Zugriff auf Ihre Dateien, um Audio-Dateien anzuzeigen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _checkPermissionAndLoadFiles,
                icon: const Icon(Icons.refresh),
                label: const Text('Berechtigung erteilen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _filteredFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                context.l10n.noAudioFilesFound,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadAudioFiles,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.reload),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                context.l10n.noSearchResults,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.noFilesMatchSearch,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final fileInfo = _filteredFiles[index];
        return AudioFileItem(
          fileInfo: fileInfo,
          onTap: () {
            Navigator.of(context).pop(fileInfo);
          },
        );
      },
    );
  }
}
