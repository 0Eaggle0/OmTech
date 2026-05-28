import 'student_record.dart';

/// Оценка по дисциплине. Источник: либо ЛК up.omgtu.ru, либо демо-данные.
class Grade {
  final String discipline;
  final String controlType; // экзамен / зачёт / курсовая
  final String mark; // «отлично», «зачтено», «4», ...
  final int? score; // балл (рейтинг), если есть
  final int? hours; // кол. часов
  final int? rankByCK; // рейтинг по контрольным неделям
  final DateTime? date;
  final String? teacher;
  final bool inDiploma;
  final GradeStatus status;

  const Grade({
    required this.discipline,
    required this.controlType,
    required this.mark,
    this.score,
    this.hours,
    this.rankByCK,
    this.date,
    this.teacher,
    this.inDiploma = false,
    this.status = GradeStatus.none,
  });

  Map<String, dynamic> toJson() => {
        'discipline': discipline,
        'controlType': controlType,
        'mark': mark,
        if (score != null) 'score': score,
        if (hours != null) 'hours': hours,
        if (rankByCK != null) 'rankByCK': rankByCK,
        if (date != null) 'date': date!.toIso8601String(),
        if (teacher != null) 'teacher': teacher,
        'inDiploma': inDiploma,
        'status': status.name,
      };

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        discipline: json['discipline'] as String? ?? '',
        controlType: json['controlType'] as String? ?? '',
        mark: json['mark'] as String? ?? '',
        score: (json['score'] as num?)?.toInt(),
        hours: (json['hours'] as num?)?.toInt(),
        rankByCK: (json['rankByCK'] as num?)?.toInt(),
        date: json['date'] is String ? DateTime.tryParse(json['date'] as String) : null,
        teacher: json['teacher'] as String?,
        inDiploma: json['inDiploma'] as bool? ?? false,
        status: GradeStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => GradeStatus.none,
        ),
      );
}

/// Семестр (или секция: Экзамены / Зачёты / Курсовые) с набором оценок.
class Semester {
  final String title;
  final List<Grade> grades;

  const Semester({required this.title, required this.grades});

  Map<String, dynamic> toJson() => {
        'title': title,
        'grades': grades.map((g) => g.toJson()).toList(),
      };

  factory Semester.fromJson(Map<String, dynamic> json) => Semester(
        title: json['title'] as String? ?? '',
        grades: (json['grades'] as List?)
                ?.whereType<Map>()
                .map((j) => Grade.fromJson(j.cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}
