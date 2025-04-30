import 'dart:developer' as developer;

/// A logger utility class that helps with debugging and error tracking
class AppLogger {
  /// Tag for categorizing logs
  final String tag;

  /// Whether to print timestamps with log messages
  final bool printTimestamps;

  /// Log level to control what gets printed
  final LogLevel logLevel;

  /// Creates a new logger instance
  ///
  /// [tag] - Category tag for this logger instance
  /// [printTimestamps] - Whether to include timestamps (defaults to true)
  /// [logLevel] - Minimum log level to print (defaults to LogLevel.debug)
  AppLogger({
    required this.tag,
    this.printTimestamps = true,
    this.logLevel = LogLevel.debug,
  });

  /// Log a debug message
  void d(String message) {
    if (logLevel.index <= LogLevel.debug.index) {
      _log('DEBUG', message);
    }
  }

  /// Log an info message
  void i(String message) {
    if (logLevel.index <= LogLevel.info.index) {
      _log('INFO', message);
    }
  }

  /// Log a warning message
  void w(String message) {
    if (logLevel.index <= LogLevel.warning.index) {
      _log('WARNING', message);
    }
  }

  /// Log an error message
  void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (logLevel.index <= LogLevel.error.index) {
      _log('ERROR', message);
      if (error != null) {
        _log('ERROR', 'Error details: $error');
      }
      if (stackTrace != null) {
        _log('ERROR', 'Stack trace: $stackTrace');
      }
    }
  }

  /// Log a message with specific level
  void log(LogLevel level, String message) {
    if (logLevel.index <= level.index) {
      _log(level.name.toUpperCase(), message);
    }
  }

  /// Internal logging method
  void _log(String level, String message) {
    final timestamp = printTimestamps ? '[${DateTime.now()}]' : '';
    developer.log('$timestamp [$tag] [$level] $message');
  }

  /// Create a child logger with the same settings but a different tag
  AppLogger child(String childTag) {
    return AppLogger(
      tag: '$tag:$childTag',
      printTimestamps: printTimestamps,
      logLevel: logLevel,
    );
  }
}

/// Log levels for controlling verbosity
enum LogLevel {
  debug,
  info,
  warning,
  error,
  none,
}

/// Global logger instance for quick access
final appLogger = AppLogger(tag: 'App');

/// Shorthand for global logger methods
void logDebug(String message) => appLogger.d(message);
void logInfo(String message) => appLogger.i(message);
void logWarning(String message) => appLogger.w(message);
void logError(String message, [Object? error, StackTrace? stackTrace]) =>
    appLogger.e(message, error, stackTrace);
