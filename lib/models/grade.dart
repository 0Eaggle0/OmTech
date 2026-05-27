/// Оценка по дисциплине (заглушка — данные требуют авторизации в ЛК).
class Grade {
  final String discipline;
  final String controlType; // экзамен / зачёт / курсовая
  final String mark; // «отлично», «зачтено», «4», ...
  final int? score; // балл по 100-балльной шкале, если есть

  const Grade({
    required this.discipline,
    required this.controlType,
    required this.mark,
    this.score,
  });
}

/// Семестр с набором оценок.
class Semester {
  final String title;
  final List<Grade> grades;

  const Semester({required this.title, required this.grades});
}
