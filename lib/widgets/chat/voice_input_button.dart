import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/i_speech_recognition_service.dart';
import '../../services/speech_recognition_service.dart';
import '../../services/snackbar_service.dart';
import '../../utils/constants.dart';

/// Voice input button with tap-to-toggle and push-to-talk support
class VoiceInputButton extends StatefulWidget {
  final void Function(String text) onResult;
  final void Function(String text) onPartialResult;
  final void Function(bool isListening) onListeningChanged;
  final bool enabled;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    required this.onPartialResult,
    required this.onListeningChanged,
    this.enabled = true,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final ISpeechRecognitionService _speechService = SpeechRecognitionService();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initError;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;
    if (_isInitializing) return false;

    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() {
          _initError = 'Mikrofonberechtigung erforderlich';
          _isInitializing = false;
        });
        return false;
      }

      _isInitialized = await _speechService.initialize();

      if (!_isInitialized) {
        setState(() {
          _initError = 'Spracherkennung nicht verfügbar';
          _isInitializing = false;
        });
        return false;
      }

      setState(() {
        _isInitializing = false;
      });
      return true;
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      setState(() {
        _initError = 'Initialisierungsfehler: $e';
        _isInitializing = false;
      });
      return false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!widget.enabled) return;

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!widget.enabled || _isListening) return;

    // Initialize on first use
    final initialized = await _ensureInitialized();
    if (!initialized) {
      if (mounted && _initError != null) {
        SnackBarService().showError(context, _initError!);
      }
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isListening = true;
    });
    widget.onListeningChanged(true);
    _pulseController.repeat(reverse: true);

    try {
      await _speechService.startListening(
        onResult: (text) {
          widget.onResult(text);
          _stopListening();
        },
        onPartialResult: widget.onPartialResult,
        locale: 'de-DE',
      );
    } catch (e) {
      debugPrint('Speech recognition error: $e');
      if (mounted) {
        SnackBarService().showError(context, 'Spracherkennungsfehler: $e');
      }
      _stopListening();
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;

    await _speechService.stopListening();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isListening = false;
    });
    widget.onListeningChanged(false);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = widget.enabled && !_isInitializing;

    return Tooltip(
      message: _isListening
          ? 'Tippen zum Stoppen'
          : 'Tippen zum Sprechen',
      child: GestureDetector(
        // Tap to toggle listening
        onTap: isAvailable ? _toggleListening : null,
        // Long press for push-to-talk (alternative)
        onLongPressStart: isAvailable && !_isListening ? (_) => _startListening() : null,
        onLongPressEnd: isAvailable && _isListening ? (_) => _stopListening() : null,
        onLongPressCancel: isAvailable && _isListening ? () => _stopListening() : null,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? theme.colorScheme.error
                    : (_isInitializing
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primaryContainer),
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.error.withValues(alpha: 0.4),
                          blurRadius: 8 * _pulseAnimation.value,
                          spreadRadius: 2 * _pulseAnimation.value,
                        ),
                      ]
                    : null,
              ),
              child: _isInitializing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening
                          ? theme.colorScheme.onError
                          : theme.colorScheme.onPrimaryContainer,
                      size: AppIconSize.large,
                    ),
            );
          },
        ),
      ),
    );
  }
}
