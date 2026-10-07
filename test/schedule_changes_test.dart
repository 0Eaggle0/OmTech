import 'package:campus2_0/models/schedule_event.dart';
import 'package:campus2_0/services/schedule_changes.dart';
import 'package:flutter_test/flutter_test.dart';

ScheduleEvent _lesson(
  int day,
  String begin,
  String discipline, {
  String auditorium = '8-418',
  String subGroup = '',
  List<String> groups = const ['АТП-251'],
}) =>
    ScheduleEvent(
      date: DateTime(2026, 10, day),
      beginLesson: begin,
      endLesson: '',
      discipline: discipline,
      lecturer: 'Иванов И.И.',
      auditorium: auditorium,
      building: 'УЛК-8',
      kindOfWork: 'Лекция',
      stream: '',
      rawSubgroup: subGroup,
      groups: groups,
    );

void main() {
  final today = DateTime(2026, 10, 13, 9, 30);

  test('одинаковое расписание — изменений нет', () {
    final week = [_lesson(13, '09:40', 'Физика'), _lesson(14, '11:35', 'Математика')];
    expect(diffSchedule(week, [...week], from: today), isEmpty);
  });

  test('отмена, перенос и новая пара — по дням', () {
    final before = [
      _lesson(13, '09:40', 'Физика'),
      _lesson(14, '11:35', 'Математика'),
    ];
    final after = [
      _lesson(13, '13:15', 'Физика'), // перенесли
      _lesson(15, '08:00', 'История'), // добавили, Математику отменили
    ];

    final changes = diffSchedule(before, after, from: today);

    expect(changes.map((c) => c.day.day), [13, 14, 15]);
    expect(changes[0].removed.single.beginLesson, '09:40');
    expect(changes[0].added.single.beginLesson, '13:15');
    expect(changes[1].removed.single.discipline, 'Математика');
    expect(changes[1].added, isEmpty);
    expect(changes[2].added.single.discipline, 'История');
  });

  test('смена аудитории — тоже изменение', () {
    final changes = diffSchedule(
      [_lesson(13, '09:40', 'Физика')],
      [_lesson(13, '09:40', 'Физика', auditorium: '6-301')],
      from: today,
    );
    expect(changes, hasLength(1));
  });

  test('прошедшие дни и чужая подгруппа не считаются', () {
    final changes = diffSchedule(
      [_lesson(12, '09:40', 'Физика'), _lesson(14, '09:40', 'Химия', subGroup: 'АТП-251/2')],
      [],
      from: today,
      subgroup: 1,
    );
    expect(changes, isEmpty);
  });

  test('добавленная к потоку группа — не изменение пары', () {
    final changes = diffSchedule(
      [_lesson(13, '09:40', 'Физика')],
      [_lesson(13, '09:40', 'Физика', groups: ['АТП-251', 'АТП-252'])],
      from: today,
    );
    expect(changes, isEmpty);
  });

  test('текст уведомления', () {
    final changes = diffSchedule(
      [_lesson(14, '11:35', 'Математика')],
      [_lesson(14, '13:15', 'Математика')],
      from: today,
    );
    expect(
      describeScheduleChanges(changes),
      'ср 14.10 — отменено: Математика 11:35; добавлено: Математика 13:15',
    );
  });

  test('больше трёх дней — хвост одной строкой', () {
    final before = [for (var d = 13; d <= 17; d++) _lesson(d, '09:40', 'Физика')];
    final text = describeScheduleChanges(diffSchedule(before, [], from: today));
    expect(text.split('\n'), hasLength(4));
    expect(text, endsWith('и ещё дней: 2'));
  });
}
