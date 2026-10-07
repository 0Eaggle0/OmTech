import 'dart:io';

import 'package:path/path.dart' as p;

/// Блокировка папки cookies ЛК на время входа.
///
/// UI-изолят и изолят фонового воркера пишут в одну папку cookies; два
/// одновременных входа затирают сессию друг друга. `RandomAccessFile.lock`
/// тут не годится: на Android это fcntl, а он не разделяет изоляты одного
/// процесса. Атомарное создание файла (`exclusive: true`) — разделяет.
///
/// Упавший с замком изолят не держит его вечно: файл старше [_stale]
/// считается брошенным.
class CookieStoreLock {
  static const _stale = Duration(seconds: 90);
  static const _poll = Duration(milliseconds: 250);

  final File _file;

  CookieStoreLock(String dir) : _file = File(p.join(dir, '.login.lock'));

  Future<T> run<T>(Future<T> Function() body) async {
    await _acquire();
    try {
      return await body();
    } finally {
      try {
        await _file.delete();
      } catch (_) {}
    }
  }

  Future<void> _acquire() async {
    final giveUpAt = DateTime.now().add(_stale);
    while (true) {
      try {
        await _file.create(exclusive: true);
        return;
      } on FileSystemException {
        if (await _isStale() || DateTime.now().isAfter(giveUpAt)) {
          try {
            await _file.delete();
          } catch (_) {}
        }
        await Future<void>.delayed(_poll);
      }
    }
  }

  Future<bool> _isStale() async {
    try {
      final age = DateTime.now().difference(await _file.lastModified());
      return age > _stale;
    } catch (_) {
      return false;
    }
  }
}
