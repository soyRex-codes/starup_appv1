import 'dart:developer' as developer;

/// Centralized logging utility for the application
/// Provides consistent logging across all services and components
class Logger {
  static const String _appName = 'FounderVers';

  /// Log debug information
  static void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _appName,
      level: 500,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log general information
  static void info(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _appName,
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warnings
  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _appName,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log errors (equivalent to severe)
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _appName,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log severe errors (highest level)
  static void severe(String message, {dynamic error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _appName,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
