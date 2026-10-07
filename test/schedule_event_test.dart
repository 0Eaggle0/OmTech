import 'dart:convert';

import 'package:campus2_0/models/schedule_event.dart';
import 'package:campus2_0/services/schedule_api.dart';
import 'package:flutter_test/flutter_test.dart';

ScheduleEvent _event({String subGroup = '', String stream = ''}) =>
    ScheduleEvent.fromJson({
      'date': '2026.09.21',
      'beginLesson': '08:30',
      'endLesson': '10:05',
      'discipline': 'Физика',
      'subGroup': subGroup,
      'stream': stream,
    });

void main() {
  test('subgroupNumber берёт цифру после слэша, а не из номера группы', () {
    expect(_event(subGroup: 'ИВТ-241/2').subgroupNumber, '2');
    expect(_event(stream: 'ИСТ-241/1-я подгруппа').subgroupNumber, '1');
    expect(_event(stream: 'ИСТ-241').subgroupNumber, '');
  });

  test('visibleTo: без выбранной подгруппы видно всё', () {
    final first = _event(subGroup: 'ИВТ-241/1');
    final common = _event(stream: 'ИВТ-241');
    expect(first.visibleTo(null), isTrue);
    expect(common.visibleTo(null), isTrue);
  });

  test('visibleTo: своя подгруппа плюс общие пары', () {
    final first = _event(subGroup: 'ИВТ-241/1');
    final second = _event(subGroup: 'ИВТ-241/2');
    final common = _event(stream: 'ИВТ-241');

    expect(first.visibleTo(1), isTrue);
    expect(second.visibleTo(1), isFalse);
    expect(common.visibleTo(1), isTrue);

    expect(first.visibleTo(2), isFalse);
    expect(second.visibleTo(2), isTrue);
    expect(common.visibleTo(2), isTrue);
  });

  group('groups', () {
    test('поток в скобках, со звёздочкой', () {
      expect(_event(stream: 'Поток(АТП-251, АТП-252)').groups,
          ['АТП-251', 'АТП-252']);
      expect(_event(stream: 'Поток(ПИ-251, ПИ-252, ПИ-251)*').groups,
          ['ПИ-251', 'ПИ-252']);
    });

    test('поток через точку с запятой и с дисциплиной после #', () {
      expect(
        _event(stream: 'АТП-251;АТП-252#Метрология, стандартизация').groups,
        ['АТП-251', 'АТП-252'],
      );
    });

    test('старый формат потока с подгруппой', () {
      expect(_event(stream: 'ИСТ-241/1-я подгруппа').groups, ['ИСТ-241']);
    });

    test('без потока — поле group, затем subGroup', () {
      final byGroup = ScheduleEvent.fromJson({
        'date': '2026.10.05',
        'stream': null,
        'group': 'АТП-251',
        'subGroup': null,
      });
      expect(byGroup.groups, ['АТП-251']);
      expect(_event(subGroup: 'ЗАТП-252/1').groups, ['ЗАТП-252']);
    });

    test('groupsLabel прячет только свою группу', () {
      final own = _event(subGroup: 'АТП-251/1');
      final stream = _event(stream: 'Поток(АТП-251, АТП-252)');
      expect(own.groupsLabel(ownGroup: 'АТП-251'), '');
      expect(own.groupsLabel(), 'АТП-251');
      expect(stream.groupsLabel(ownGroup: 'АТП-251'), 'АТП-251, АТП-252');
    });
  });

  test('parseRaw склеивает одну пару разных групп в одну карточку', () {
    Map<String, dynamic> row(String group) => {
          'date': '2026.10.05',
          'beginLesson': '13:15',
          'endLesson': '14:45',
          'discipline': 'Физика',
          'lecturer': 'Иванов И.И.',
          'auditorium': '8-418',
          'group': group,
        };
    final events = ScheduleApi.parseRaw(
        jsonEncode([row('ИВТ-251'), row('ИВТ-252'), row('ИВТ-251')]));
    expect(events, hasLength(1));
    expect(events.single.groups, ['ИВТ-251', 'ИВТ-252']);
  });
}
