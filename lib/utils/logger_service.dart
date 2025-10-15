import 'package:flutter/foundation.dart';

/// A simple logging service to replace print statements
/// Provides different log levels and better production logging control
class LoggerService {
  static const bool _enableLogsInProduction = false;

  /// Log general information
  static void info(String message, [String? tag]) {
    _log('INFO', message, tag);
  }

  /// Log debug information (only in debug mode)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      _log('DEBUG', message, tag);
    }
  }

  /// Log warnings
  static void warning(String message, [String? tag]) {
    _log('WARNING', message, tag);
  }

  /// Log errors
  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    _log('ERROR', message, tag);
    if (error != null) {
      _log('ERROR', 'Error details: $error', tag);
    }
    if (stackTrace != null && kDebugMode) {
      _log('ERROR', 'Stack trace:\n$stackTrace', tag);
    }
  }

  /// Log success messages
  static void success(String message, [String? tag]) {
    _log('SUCCESS', message, tag);
  }

  /// Internal logging method
  static void _log(String level, String message, [String? tag]) {
    // Only log in debug mode, or if explicitly enabled for production
    if (kDebugMode || _enableLogsInProduction) {
      final timestamp = DateTime.now().toIso8601String();
      final tagString = tag != null ? '[$tag]' : '';
      final logMessage = '[$timestamp] [$level] $tagString $message';

      // In production, you might want to send logs to a service like Firebase Crashlytics
      // For now, we just print them
      debugPrint(logMessage);
    }
  }

  /// Log authentication events
  static void auth(String message, [String? userId]) {
    final tag = userId != null ? 'AUTH:$userId' : 'AUTH';
    info(message, tag);
  }

  /// Log database operations
  static void database(String message, [String? collection]) {
    final tag = collection != null ? 'DB:$collection' : 'DB';
    debug(message, tag);
  }

  /// Log matching service operations
  static void matching(String message) {
    debug(message, 'MATCHING');
  }

  /// Log navigation events
  static void navigation(String message) {
    debug(message, 'NAV');
  }

  /// Log network requests (if needed)
  static void network(String message, [String? endpoint]) {
    final tag = endpoint != null ? 'NET:$endpoint' : 'NET';
    debug(message, tag);
  }
}
