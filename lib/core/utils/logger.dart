enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  static LogLevel _logLevel = LogLevel.info;
  static const String _prefix = '[SmartHome]';

  static void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  static void verbose(String message, [Object? error, StackTrace? stackTrace]) {
    if (_logLevel.index <= LogLevel.verbose.index) {
      _log('VERBOSE', message, error, stackTrace);
    }
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_logLevel.index <= LogLevel.debug.index) {
      _log('DEBUG', message, error, stackTrace);
    }
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (_logLevel.index <= LogLevel.info.index) {
      _log('INFO', message, error, stackTrace);
    }
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (_logLevel.index <= LogLevel.warning.index) {
      _log('WARN', message, error, stackTrace);
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_logLevel.index <= LogLevel.error.index) {
      _log('ERROR', message, error, stackTrace);
    }
  }

  static void _log(
      String level, String message, Object? error, StackTrace? stackTrace) {
    final timestamp = DateTime.now().toIso8601String();
    final output = '$_prefix [$timestamp] [$level] $message';

    // ignore: avoid_print
    print(output);

    if (error != null) {
      // ignore: avoid_print
      print('$_prefix Error: $error');
    }

    if (stackTrace != null) {
      // ignore: avoid_print
      print('$_prefix Stack trace:\n$stackTrace');
    }
  }
}
