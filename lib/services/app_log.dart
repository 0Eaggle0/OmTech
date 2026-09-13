import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Журнал последних событий приложения для отчёта об ошибке.
///
/// Перехватывает `debugPrint` и необработанные исключения. Хранит только
/// хвост (последние [_capacity] строк) в памяти — на диск ничего не пишет,
/// а пароли, cookies и sessid вырезаются ещё при записи.
class AppLog {
  AppLog._();

  static const _capacity = 500;
  static final _lines = ListQueue<String>();

  static final _secretPatterns = [
    RegExp(r'((?:USER_PASSWORD|USER_LOGIN|password|sessid)\s*[=:]\s*)[^&\s;,]+',
        caseSensitive: false),
    RegExp(r'((?:PHPSESSID|BITRIX_SM_\w+)\s*=\s*)[^;\s]+', caseSensitive: false),
    RegExp(r'((?:Set-Cookie|Cookie)\s*:\s*)[^\n]+', caseSensitive: false),
  ];

  static List<String> get lines => List.unmodifiable(_lines);

  /// Вызывается первым делом в `main()`: всё, что сломается дальше, должно
  /// попасть в журнал.
  static void install() {
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) add(message);
      // В release консоль никто не читает — журнала достаточно.
      if (kDebugMode) original(message, wrapWidth: wrapWidth);
    };

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      add('[FlutterError] ${details.exceptionAsString()}\n${_head(details.stack)}');
      previousOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      add('[Uncaught] $error\n${_head(stack)}');
      return false;
    };
  }

  static void add(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 23);
    for (final line in sanitize(message).split('\n')) {
      if (line.trim().isEmpty) continue;
      if (_lines.length >= _capacity) _lines.removeFirst();
      _lines.add('$time $line');
    }
  }

  static String sanitize(String text) {
    var out = text;
    for (final re in _secretPatterns) {
      out = out.replaceAllMapped(re, (m) => '${m[1]}***');
    }
    return out;
  }

  static String _head(StackTrace? stack) =>
      (stack?.toString() ?? '').split('\n').take(12).join('\n');
}
