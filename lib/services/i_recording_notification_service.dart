/// Interface for managing recording foreground service notification
/// Follows Interface Segregation Principle and Dependency Inversion Principle
abstract class IRecordingNotificationService {
  /// Initialize the foreground task service
  Future<void> initialize();

  /// Start foreground service with recording notification
  Future<void> showRecordingNotification();

  /// Update notification to show paused state
  Future<void> showPausedNotification();

  /// Update notification back to recording state
  Future<void> showResumedNotification();

  /// Stop the foreground service
  Future<void> cancelRecordingNotification();
}
