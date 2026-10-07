import 'dart:io';

import 'package:campus2_0/services/schedule_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late ScheduleCache cache;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('schedule_cache_test');
    cache = ScheduleCache(dir: () async => Directory('${root.path}/schedule'));
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('читает то, что записал, вместе со временем сохранения', () async {
    final before = DateTime.now().subtract(const Duration(seconds: 2));
    await cache.write('group_6_2026-10-05_2026-10-11', '[{"a":1}]');

    final read = await cache.read('group_6_2026-10-05_2026-10-11');
    expect(read?.rawJson, '[{"a":1}]');
    expect(read!.savedAt.isAfter(before), isTrue);
    expect(await cache.read('missing'), isNull);
  });

  test('перезапись заменяет содержимое и не оставляет временных файлов',
      () async {
    await cache.write('k', 'old');
    await cache.write('k', 'new');
    expect((await cache.read('k'))?.rawJson, 'new');
    final names = Directory('${root.path}/schedule')
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .toList();
    expect(names, ['k.json']);
  });

  test('держит не больше 40 записей, выкидывает самые старые', () async {
    final dir = Directory('${root.path}/schedule')..createSync(recursive: true);
    final base = DateTime(2026, 1, 1);
    for (var i = 0; i < 40; i++) {
      File('${dir.path}/old$i.json')
        ..writeAsStringSync('x')
        ..setLastModifiedSync(base.add(Duration(minutes: i)));
    }
    await cache.write('fresh', 'y');

    expect(await cache.read('old0'), isNull);
    expect(await cache.read('old1'), isNotNull);
    expect(await cache.read('fresh'), isNotNull);
    expect(dir.listSync(), hasLength(40));
  });

  test('clear удаляет всё, размер считается по файлам', () async {
    await cache.write('a', '12345');
    expect(await cache.sizeBytes(), 5);
    await cache.clear();
    expect(await cache.read('a'), isNull);
    expect(await cache.sizeBytes(), 0);
  });
}
