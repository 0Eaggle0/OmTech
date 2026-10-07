import '../models/schedule_event.dart';

/// Изменения расписания за один день: что пропало и что появилось.
/// Перенос пары на другое время — это «пропала» + «появилась».
class ScheduleDayChange {
  final DateTime day;
  final List<ScheduleEvent> removed;
  final List<ScheduleEvent> added;

  const ScheduleDayChange(this.day, {this.removed = const [], this.added = const []});
}

/// Сравнивает два снимка расписания с [from] (включительно) — прошедшие
/// дни не интересны. [subgroup] — как в `ScheduleEvent.visibleTo`: пары
/// чужой подгруппы пользователя не касаются.
List<ScheduleDayChange> diffSchedule(
  List<ScheduleEvent> before,
  List<ScheduleEvent> after, {
  required DateTime from,
  int? subgroup,
}) {
  final start = DateTime(from.year, from.month, from.day);
  Map<DateTime, Map<String, ScheduleEvent>> byDay(List<ScheduleEvent> events) {
    final result = <DateTime, Map<String, ScheduleEvent>>{};
    for (final e in events) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      if (day.isBefore(start) || !e.visibleTo(subgroup)) continue;
      (result[day] ??= {})[_identity(e)] = e;
    }
    return result;
  }

  final old = byDay(before);
  final fresh = byDay(after);
  final days = {...old.keys, ...fresh.keys}.toList()..sort();
  final changes = <ScheduleDayChange>[];
  for (final day in days) {
    final o = old[day] ?? const {};
    final n = fresh[day] ?? const {};
    final removed = [for (final k in o.keys) if (!n.containsKey(k)) o[k]!];
    final added = [for (final k in n.keys) if (!o.containsKey(k)) n[k]!];
    if (removed.isEmpty && added.isEmpty) continue;
    changes.add(ScheduleDayChange(day, removed: removed, added: added));
  }
  return changes;
}

/// Всё, что студенту важно в паре. Группы не входят: их список меняется,
/// когда к потоку добавляют группу, а для самой пары это ничего не значит.
String _identity(ScheduleEvent e) => [
      e.beginLesson,
      e.endLesson,
      e.discipline,
      e.kindOfWork,
      e.auditorium,
      e.lecturer,
      e.rawSubgroup,
    ].join('|');

/// Текст уведомления: по строке на день, не больше [maxDays] дней.
String describeScheduleChanges(List<ScheduleDayChange> changes, {int maxDays = 3}) {
  const weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
  String two(int n) => n.toString().padLeft(2, '0');
  String lesson(ScheduleEvent e) => '${e.discipline} ${e.beginLesson}';

  final lines = <String>[];
  for (final c in changes.take(maxDays)) {
    final parts = [
      if (c.removed.isNotEmpty) 'отменено: ${c.removed.map(lesson).join(', ')}',
      if (c.added.isNotEmpty) 'добавлено: ${c.added.map(lesson).join(', ')}',
    ];
    lines.add('${weekdays[c.day.weekday - 1]} ${two(c.day.day)}.${two(c.day.month)} — '
        '${parts.join('; ')}');
  }
  if (changes.length > maxDays) lines.add('и ещё дней: ${changes.length - maxDays}');
  return lines.join('\n');
}
