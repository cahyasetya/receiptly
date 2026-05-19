import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class Logger {
  final String tag;

  const Logger(this.tag);

  void debug(String message) => _log(LogLevel.debug, message);
  void info(String message) => _log(LogLevel.info, message);
  void warn(String message) => _log(LogLevel.warn, message);
  void error(String message) => _log(LogLevel.error, message);

  void _log(LogLevel level, String message) {
    // Print to terminal (stdout) so it's visible during `flutter run`
    final prefix = switch (level) {
      LogLevel.debug => '🐛',
      LogLevel.info  => 'ℹ️',
      LogLevel.warn  => '⚠️',
      LogLevel.error => '',
    };
    debugPrint('[$tag] $prefix $message');

    // Also send to DevTools
    dev.log(
      message,
      name: tag,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info  => 800,
        LogLevel.warn  => 900,
        LogLevel.error => 1000,
      },
    );
}
}
