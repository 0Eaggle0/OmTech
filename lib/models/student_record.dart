import 'grade.dart';

/// Статус строки в таблице зачётки. На сайте ОмГТУ кодируется CSS-классом
/// `success` / `warning` / `danger` на `<td>`.
enum GradeStatus { success, warning, danger, none }

GradeStatus gradeStatusFromCss(Iterable<String> classes) {
  for (final c in classes) {
    switch (c) {
      case 'success':
        return GradeStatus.success;
      case 'warning':
        return GradeStatus.warning;
      case 'danger':
        return GradeStatus.danger;
    }
  }
  return GradeStatus.none;
}

/// Краткая шапка студента из ЛК.
class StudentProfile {
  final String fullName;
  final String bookNumber;
  final String specialty;
  final String groupLabel;
  final String studyForm;
  final String libraryCardNumber;

  const StudentProfile({
    required this.fullName,
    required this.bookNumber,
    required this.specialty,
    required this.groupLabel,
    required this.studyForm,
    required this.libraryCardNumber,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'bookNumber': bookNumber,
        'specialty': specialty,
        'groupLabel': groupLabel,
        'studyForm': studyForm,
        'libraryCardNumber': libraryCardNumber,
      };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        fullName: json['fullName'] as String? ?? '',
        bookNumber: json['bookNumber'] as String? ?? '',
        specialty: json['specialty'] as String? ?? '',
        groupLabel: json['groupLabel'] as String? ?? '',
        studyForm: json['studyForm'] as String? ?? '',
        libraryCardNumber: json['libraryCardNumber'] as String? ?? '',
      );
}

/// Статус допуска по семестру (правая колонка на student/index).
class SemesterAccess {
  final int number;
  final bool hasAccess;

  const SemesterAccess({required this.number, required this.hasAccess});

  Map<String, dynamic> toJson() => {
        'number': number,
        'hasAccess': hasAccess,
      };

  factory SemesterAccess.fromJson(Map<String, dynamic> json) => SemesterAccess(
        number: (json['number'] as num?)?.toInt() ?? 0,
        hasAccess: json['hasAccess'] as bool? ?? false,
      );
}

/// Полная выписка из ЛК: профиль + допуски + сгруппированные оценки.
class StudentRecord {
  final StudentProfile profile;
  final List<SemesterAccess> semesters;
  final List<Semester> sections;

  const StudentRecord({
    required this.profile,
    required this.semesters,
    required this.sections,
  });

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'semesters': semesters.map((s) => s.toJson()).toList(),
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  factory StudentRecord.fromJson(Map<String, dynamic> json) => StudentRecord(
        profile: StudentProfile.fromJson(
            (json['profile'] as Map?)?.cast<String, dynamic>() ?? const {}),
        semesters: (json['semesters'] as List?)
                ?.whereType<Map>()
                .map((j) => SemesterAccess.fromJson(j.cast<String, dynamic>()))
                .toList() ??
            const [],
        sections: (json['sections'] as List?)
                ?.whereType<Map>()
                .map((j) => Semester.fromJson(j.cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}
