/// Статус проверки отчётной работы.
enum ReportWorkStatus {
  /// Работа загружена, ещё не проверена преподавателем.
  pending,

  /// Работа принята.
  accepted,

  /// Работа отклонена.
  rejected;

  String toJson() => name;

  static ReportWorkStatus fromJson(Object? raw) {
    final s = raw?.toString() ?? '';
    return ReportWorkStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ReportWorkStatus.pending,
    );
  }
}

/// «Прочая» отчётная работа — лабораторная, домашняя, презентация и т. п.
class ReportWork {
  /// Идентификатор записи (первый аргумент `getotherpage('<fileId>','<fnpp>')`).
  final String fileId;

  /// «Номер портфеля» — второй аргумент `getotherpage`. На сайте это
  /// идентификатор студента, одинаковый для всех его работ. Нужен в POST'е
  /// `otherpage.php`, иначе сервер вернёт пустую форму создания.
  final String fnpp;

  /// Дата создания записи (когда загрузили работу), `null` если не распарсилось.
  final DateTime? date;

  /// Название предмета. Пример: «Программирование».
  final String discipline;

  /// Номер семестра, к которому отнесена работа.
  final int? semester;

  /// Номер работы в системе ОмГТУ (на сайте показан как «№ 2496706»).
  final String workNumber;

  /// Название работы. Пример: «Отчёт по лабораторной работе №1».
  final String title;

  /// Текущий статус проверки.
  final ReportWorkStatus status;

  /// ФИО преподавателя, либо пустая строка, если работа ещё не назначена/проверена.
  final String teacher;

  /// Комментарий преподавателя к работе. `null`, если комментария нет.
  final String? comment;

  const ReportWork({
    required this.fileId,
    required this.fnpp,
    required this.date,
    required this.discipline,
    required this.semester,
    required this.workNumber,
    required this.title,
    required this.status,
    required this.teacher,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
        'fileId': fileId,
        'fnpp': fnpp,
        'date': date?.toIso8601String(),
        'discipline': discipline,
        'semester': semester,
        'workNumber': workNumber,
        'title': title,
        'status': status.toJson(),
        'teacher': teacher,
        'comment': comment,
      };

  factory ReportWork.fromJson(Map<String, dynamic> json) => ReportWork(
        fileId: (json['fileId'] ?? '') as String,
        fnpp: (json['fnpp'] ?? '') as String,
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        discipline: (json['discipline'] ?? '') as String,
        semester: json['semester'] as int?,
        workNumber: (json['workNumber'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        status: ReportWorkStatus.fromJson(json['status']),
        teacher: (json['teacher'] ?? '') as String,
        comment: json['comment'] as String?,
      );
}

/// Курсовая работа студента за выбранный учебный год.
class ReportCourseWork {
  /// Внутренний идентификатор записи (`hexnrec` на сайте).
  final String hexnrec;

  /// Группа, к которой относится курсовая (например, «ИСТ-241»).
  final String groupName;

  /// ФИО студента.
  final String studentName;

  /// Тип работы. Пример: «Проектная деятельность».
  final String workType;

  /// Название курсовой.
  final String title;

  const ReportCourseWork({
    required this.hexnrec,
    required this.groupName,
    required this.studentName,
    required this.workType,
    required this.title,
  });

  Map<String, dynamic> toJson() => {
        'hexnrec': hexnrec,
        'groupName': groupName,
        'studentName': studentName,
        'workType': workType,
        'title': title,
      };

  factory ReportCourseWork.fromJson(Map<String, dynamic> json) =>
      ReportCourseWork(
        hexnrec: (json['hexnrec'] ?? '') as String,
        groupName: (json['groupName'] ?? '') as String,
        studentName: (json['studentName'] ?? '') as String,
        workType: (json['workType'] ?? '') as String,
        title: (json['title'] ?? '') as String,
      );
}

/// Полный «снимок» страницы /ecab/vkr2.php.
class ReportWorksResult {
  /// Курсовые работы за активный учебный год, который видит пользователь.
  final List<ReportCourseWork> courseWorks;

  /// «Прочие работы» за все годы (плоский список).
  final List<ReportWork> otherWorks;

  /// Активный учебный год, к которому относятся курсовые работы.
  /// Пример: 2025 для учебного года 2025/2026.
  final int? academicYear;

  const ReportWorksResult({
    required this.courseWorks,
    required this.otherWorks,
    required this.academicYear,
  });

  Map<String, dynamic> toJson() => {
        'courseWorks': courseWorks.map((c) => c.toJson()).toList(),
        'otherWorks': otherWorks.map((o) => o.toJson()).toList(),
        'academicYear': academicYear,
      };

  factory ReportWorksResult.fromJson(Map<String, dynamic> json) =>
      ReportWorksResult(
        courseWorks: ((json['courseWorks'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => ReportCourseWork.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        otherWorks: ((json['otherWorks'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => ReportWork.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        academicYear: json['academicYear'] as int?,
      );
}

/// Дисциплина, в которую можно загрузить «прочую» работу, — строка списка
/// в форме загрузки: `seldisc('<hexnrec>','<название>','<группа>','<семестр>')`.
class ReportUploadDiscipline {
  /// Внутренний id дисциплины (`dischexnrec`), уходит в POST загрузки.
  final String hexnrec;

  final String name;

  /// Группа, например «ИСТ-241».
  final String group;

  /// Семестр строкой — ровно так он уходит в поле `semester`.
  final String semester;

  const ReportUploadDiscipline({
    required this.hexnrec,
    required this.name,
    required this.group,
    required this.semester,
  });

  int get semesterNumber => int.tryParse(semester) ?? 0;
}
