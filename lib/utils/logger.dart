import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void d(String message) {
    if (!kReleaseMode) {
      // debugPrint já evita travar o console com mensagens longas
      debugPrint(message);
    }
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }
}


