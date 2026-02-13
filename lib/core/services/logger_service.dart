import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
    };
  }

  @override
  String toString() {
    final timeStr = timestamp.toIso8601String().substring(11, 19);
    final levelStr = level.name.toUpperCase().padRight(8);
    return '[$timeStr] $levelStr $message';
  }
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final List<LogEntry> _logs = [];
  final StreamController<List<LogEntry>> _logController =
      StreamController<List<LogEntry>>.broadcast();

  Stream<List<LogEntry>> get logsStream => _logController.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  static const int _maxLogs = 1000;

  void debug(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.debug, message, context: context);
  }

  void info(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.info, message, context: context);
  }

  void warning(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.warning, message, context: context);
  }

  void error(String message,
      {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _log(LogLevel.error, message,
        error: error?.toString(), stackTrace: stackTrace, context: context);
  }

  void critical(String message,
      {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _log(LogLevel.critical, message,
        error: error, stackTrace: stackTrace, context: context);
  }

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace,
      context: context,
    );

    _logs.add(entry);

    // Keep only the last _maxLogs entries
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }

    // Send to stream
    _logController.add(List.from(_logs));

    // Also log to developer console in debug mode
    if (kDebugMode) {
      if (level == LogLevel.error || level == LogLevel.critical) {
        developer.log(
          message,
          name: 'SmartHome',
          error: error,
          stackTrace: stackTrace,
        );
      } else {
        print(entry.toString());
      }
    }
  }

  void logDatabaseOperation(String operation, {Map<String, dynamic>? details}) {
    info('Database Operation: $operation', context: {
      'operation': operation,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void logAuthenticationEvent(String event,
      {String? userId, Map<String, dynamic>? details}) {
    info('Auth Event: $event', context: {
      'event': event,
      'userId': userId,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void logNavigationEvent(String from, String to,
      {Map<String, dynamic>? details}) {
    debug('Navigation: $from -> $to', context: {
      'from': from,
      'to': to,
      'details': details,
    });
  }

  void logDeviceEvent(String deviceId, String event,
      {Map<String, dynamic>? details}) {
    info('Device Event: $deviceId - $event', context: {
      'deviceId': deviceId,
      'event': event,
      'details': details,
    });
  }

  void logSecurityEvent(String event, {Map<String, dynamic>? details}) {
    warning('Security Event: $event', context: {
      'event': event,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void logMQTTEvent(String topic, String event,
      {Map<String, dynamic>? details}) {
    debug('MQTT Event: $topic - $event', context: {
      'topic': topic,
      'event': event,
      'details': details,
    });
  }

  void clearLogs() {
    _logs.clear();
    _logController.add([]);
  }

  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  List<LogEntry> getLogsSince(DateTime since) {
    return _logs.where((log) => log.timestamp.isAfter(since)).toList();
  }

  void dispose() {
    _logController.close();
  }

  // Utility method to get recent errors
  List<LogEntry> getRecentErrors({int count = 10}) {
    return _logs
        .where((log) =>
            log.level == LogLevel.error || log.level == LogLevel.critical)
        .take(count)
        .toList();
  }

  // Utility method to export logs
  String exportLogs() {
    final logsJson = _logs.map((log) => log.toJson()).toList();
    return logsJson.map((log) => log.toString()).join('\n');
  }
}

// Global logger instance for easy access
final logger = LoggerService();
