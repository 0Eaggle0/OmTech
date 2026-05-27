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
    );
  }

  /// Локация: «8-204 · УЛК-8».
  String get location {
    if (auditorium.isEmpty && building.isEmpty) return '';
    if (building.isEmpty) return auditorium;
    if (auditorium.isEmpty) return building;
    return '$auditorium · $building';
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
