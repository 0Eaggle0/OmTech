import 'package:campus2_0/models/schedule_event.dart';
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
}
