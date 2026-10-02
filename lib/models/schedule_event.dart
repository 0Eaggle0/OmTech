/// Одно занятие (пара) из API расписания ОМГТУ.
class ScheduleEvent {
  final DateTime date;
  final String beginLesson;
  final String endLesson;
  final String discipline;
  final String lecturer;
  final String auditorium;
  final String building;
  final String kindOfWork;
  final String stream;
  final String rawSubgroup;

  const ScheduleEvent({
    required this.date,
    required this.beginLesson,
    required this.endLesson,
    required this.discipline,
    required this.lecturer,
    required this.auditorium,
    required this.building,
    required this.kindOfWork,
    required this.stream,
    this.rawSubgroup = '',
  });

  /// API отдаёт дату в формате `YYYY.MM.DD`.
  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
      date: _parseDate(json['date']?.toString()),
      beginLesson: (json['beginLesson'] ?? '').toString(),
      endLesson: (json['endLesson'] ?? '').toString(),
      discipline: (json['discipline'] ?? '').toString(),
      lecturer: (json['lecturer'] ?? '').toString(),
      auditorium: (json['auditorium'] ?? '').toString(),
      building: (json['building'] ?? '').toString(),
      kindOfWork: (json['kindOfWork'] ?? '').toString(),
      stream: (json['stream'] ?? '').toString(),
      rawSubgroup: (json['subGroup'] ?? json['subgroupNumber'] ?? '').toString(),
    );
  }

  /// Локация: «8-204 · УЛК-8».
  String get location {
    if (auditorium.isEmpty && building.isEmpty) return '';
    if (building.isEmpty) return auditorium;
    if (auditorium.isEmpty) return building;
    return '$auditorium · $building';
  }

  /// Номер подгруппы (1 или 2). Пустая строка = пара для всех подгрупп.
  /// API возвращает subGroup как "ИВТ-241/2" — нужна цифра ПОСЛЕ слэша,
  /// иначе первая цифра в строке попадёт из номера группы (241 → 2).
  String get subgroupNumber {
    if (rawSubgroup.isNotEmpty) {
      final m = RegExp(r'/(\d)').firstMatch(rawSubgroup);
      if (m != null) return m.group(1)!;
    }
    final m = RegExp(r'/(\d)').firstMatch(stream);
    return m?.group(1) ?? '';
  }

  /// Пара видна выбранной подгруппе: [subgroup] `null` — видно всё,
  /// иначе общие пары плюс пары этой подгруппы.
  bool visibleTo(int? subgroup) {
    if (subgroup == null) return true;
    final n = subgroupNumber;
    return n.isEmpty || n == subgroup.toString();
  }

  /// Stream без суффикса подгруппы для отображения («ИСТ-241/1-я подгруппа» → «ИСТ-241»).
  String get streamDisplay {
    return stream.replaceAll(RegExp(r'/\d.*$'), '').trim();
  }

  static DateTime _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    final parts = raw.split(RegExp(r'[.\-/]'));
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]) ?? DateTime.now().year;
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      return DateTime(y, m, d);
    }
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
}
