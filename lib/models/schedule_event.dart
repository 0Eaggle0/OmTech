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

  /// Группы на паре: «АТП-251», «АТП-252»… Для расписания препода или
  /// аудитории это единственный способ понять, кто сидит на занятии.
  final List<String> groups;

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
    this.groups = const [],
  });

  /// API отдаёт дату в формате `YYYY.MM.DD`.
  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    final stream = (json['stream'] ?? '').toString();
    final group = (json['group'] ?? '').toString();
    final rawSubgroup =
        (json['subGroup'] ?? json['subgroupNumber'] ?? '').toString();
    return ScheduleEvent(
      date: _parseDate(json['date']?.toString()),
      beginLesson: (json['beginLesson'] ?? '').toString(),
      endLesson: (json['endLesson'] ?? '').toString(),
      discipline: (json['discipline'] ?? '').toString(),
      lecturer: (json['lecturer'] ?? '').toString(),
      auditorium: (json['auditorium'] ?? '').toString(),
      building: (json['building'] ?? '').toString(),
      kindOfWork: (json['kindOfWork'] ?? '').toString(),
      stream: stream,
      rawSubgroup: rawSubgroup,
      groups: parseGroups(stream: stream, group: group, subGroup: rawSubgroup),
    );
  }

  /// Та же пара, но с добавленными группами — API повторяет пару отдельной
  /// строкой на каждую группу, и при склейке дублей группы надо сохранить.
  ScheduleEvent withGroups(Iterable<String> more) {
    final merged = [...groups];
    for (final g in more) {
      if (!merged.contains(g)) merged.add(g);
    }
    return ScheduleEvent(
      date: date,
      beginLesson: beginLesson,
      endLesson: endLesson,
      discipline: discipline,
      lecturer: lecturer,
      auditorium: auditorium,
      building: building,
      kindOfWork: kindOfWork,
      stream: stream,
      rawSubgroup: rawSubgroup,
      groups: merged,
    );
  }

  /// Группы из полей API. Поток приходит в разных видах:
  /// `Поток(АТП-251, АТП-252)*`, `АТП-251;АТП-252#Метрология…`,
  /// `ИСТ-241/1-я подгруппа`. Без потока — поле `group`, а у пары подгруппы
  /// только `subGroup` вида `АТП-251/1`.
  static List<String> parseGroups({
    String stream = '',
    String group = '',
    String subGroup = '',
  }) {
    var raw = stream.trim();
    if (raw.isEmpty) raw = group.trim();
    if (raw.isEmpty) raw = subGroup.trim();
    if (raw.isEmpty) return const [];

    raw = raw.replaceAll(RegExp(r'\*+$'), '').trim();
    final hash = raw.indexOf('#');
    if (hash >= 0) raw = raw.substring(0, hash);
    final wrapped = RegExp(r'^[^()]*\((.*)\)$').firstMatch(raw);
    if (wrapped != null) raw = wrapped.group(1)!;

    final result = <String>[];
    for (final part in raw.split(RegExp(r'[,;]'))) {
      final name = part.replaceAll(RegExp(r'/\d.*$'), '').trim();
      if (name.isNotEmpty && !result.contains(name)) result.add(name);
    }
    return result;
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

  /// Группы через запятую для показа на карточке. [ownGroup] — группа,
  /// чьё расписание открыто: пара только этой группы ничего нового не
  /// говорит, и строку тогда не показываем.
  String groupsLabel({String? ownGroup}) {
    if (groups.isEmpty) return '';
    if (ownGroup != null && groups.length == 1 && groups.first == ownGroup) {
      return '';
    }
    return groups.join(', ');
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
