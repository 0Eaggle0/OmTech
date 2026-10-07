import 'dart:io';

import 'package:campus2_0/services/lk/cookie_store_lock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('cookie_lock'));
  tearDown(() async => dir.delete(recursive: true));

  test('два входа не пересекаются и идут по очереди', () async {
    // Отдельные экземпляры — как у двух изолятов с одной папкой cookies.
    final a = CookieStoreLock(dir.path);
    final b = CookieStoreLock(dir.path);
    final events = <String>[];

    Future<void> login(CookieStoreLock lock, String who) => lock.run(() async {
          events.add('$who start');
          await Future<void>.delayed(const Duration(milliseconds: 300));
          events.add('$who end');
        });

    await Future.wait([login(a, 'a'), login(b, 'b')]);

    expect(events, hasLength(4));
    expect(events[0].split(' ').first, events[1].split(' ').first);
    expect(events[1], endsWith('end'));
  });

  test('замок отпускается и после ошибки внутри', () async {
    final lock = CookieStoreLock(dir.path);
    await expectLater(
      lock.run<void>(() async => throw StateError('boom')),
      throwsStateError,
    );
    expect(await lock.run(() async => 42), 42);
  });

  test('брошенный замок (старше 90 с) не блокирует вход', () async {
    File('${dir.path}/.login.lock')
      ..writeAsStringSync('')
      ..setLastModifiedSync(DateTime.now().subtract(const Duration(minutes: 5)));
    final result = await CookieStoreLock(dir.path)
        .run(() async => 'ok')
        .timeout(const Duration(seconds: 5));
    expect(result, 'ok');
  });
}
