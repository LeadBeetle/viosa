import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'i_recording_notification_service.dart';

/// Service to manage recording foreground service notification
class RecordingNotificationService implements IRecordingNotificationService {
  static final RecordingNotificationService _instance = RecordingNotificationService._internal();
  factory RecordingNotificationService() => _instance;
  RecordingNotificationService._internal();

  bool _isInitialized = false;

  /// Initialize the foreground task service
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Only initialize on Android - iOS uses system recording indicator
    if (!Platform.isAndroid) {
      _isInitialized = true;
      return;
    }

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'viosa_recording',
        channelName: 'Aufnahme',
        channelDescription: 'Zeigt an, wenn eine Audioaufnahme läuft',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
  }

  /// Start foreground service with recording notification
  @override
  Future<void> showRecordingNotification() async {
    // Only show on Android - iOS uses system recording indicator
    if (!Platform.isAndroid) return;

    if (!_isInitialized) {
      await initialize();
    }

    // Request necessary permissions
    final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // Start foreground service
    await FlutterForegroundTask.startService(
      notificationTitle: 'VIOSA',
      notificationText: 'Aufnahme läuft...',
      notificationIcon: null,
      callback: _startCallback,
    );
  }

  /// Update notification to show paused state
  @override
  Future<void> showPausedNotification() async {
    if (!Platform.isAndroid) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: 'VIOSA',
      notificationText: 'Aufnahme pausiert',
    );
  }

  /// Update notification back to recording state
  @override
  Future<void> showResumedNotification() async {
    if (!Platform.isAndroid) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: 'VIOSA',
      notificationText: 'Aufnahme läuft...',
    );
  }

  /// Stop the foreground service
  @override
  Future<void> cancelRecordingNotification() async {
    if (!Platform.isAndroid) return;

    await FlutterForegroundTask.stopService();
  }
}

// This callback is required but we don't need to do anything in it
// since we just want the notification, not background processing
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_RecordingTaskHandler());
}

class _RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Nothing to do - we just need the foreground service notification
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Not using repeat events
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isAppTerminated) async {
    // Cleanup if needed
  }

  @override
  void onReceiveData(Object data) {
    // Not receiving data
  }

  @override
  void onNotificationButtonPressed(String id) {
    // Not using notification buttons
  }

  @override
  void onNotificationPressed() {
    // User tapped notification - could open app
  }

  @override
  void onNotificationDismissed() {
    // Notification was dismissed
  }
}
