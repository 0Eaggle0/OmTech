import '../models/grade.dart';
import '../models/student_record.dart';

/// Средний балл по числовым оценкам («отлично» → 5 … «неуд.» → 2).
/// Зачёты («зачтено») не участвуют — у них нет численного эквивалента.
/// Возвращает `null`, если считать не из чего.
double? calcGpa(StudentRecord record) {
  final marks = record.allSections
      .expand((s) => s.grades)
      .map((g) => markValue(g.mark))
      .whereType<double>()
      .toList();
  if (marks.isEmpty) return null;
  return marks.reduce((a, b) => a + b) / marks.length;
}

double? markValue(String mark) {
  final m = mark.toLowerCase();
  if (m.contains('отл')) return 5;
  if (m.contains('хор')) return 4;
  if (m.contains('удовл')) return 3;
  if (m.contains('неуд')) return 2;
  return double.tryParse(mark.replaceAll(',', '.'));
}

/// Сводка по семестру для строки статистики на экране оценок.
class SemesterMarkCounts {
  final int excellent;
  final int good;
  final int credited;

  const SemesterMarkCounts({
    required this.excellent,
    required this.good,
    required this.credited,
  });
}

SemesterMarkCounts countMarks(Iterable<Grade> grades) {
  var excellent = 0, good = 0, credited = 0;
  for (final g in grades) {
    final m = g.mark.toLowerCase();
    if (m.contains('отл')) {
      excellent++;
    } else if (m.contains('хор')) {
      good++;
    } else if (m.contains('зачт')) {
      credited++;
    }
  }
  return SemesterMarkCounts(excellent: excellent, good: good, credited: credited);
}
