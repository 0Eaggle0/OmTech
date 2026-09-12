import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule_entity.dart';

/// Запись истории поиска — то же, что `ScheduleEntity`, но с собственной
/// сериализацией: `ScheduleEntity` не обязана уметь превращаться в JSON.
class SearchHistoryEntry {
  final EntityType type;
  final int id;
  final String label;
  final String description;

  const SearchHistoryEntry({
    required this.type,
    required this.id,
    required this.label,
    this.description = '',
  });

  factory SearchHistoryEntry.fromEntity(ScheduleEntity e) => SearchHistoryEntry(
        type: e.type,
        id: e.id,
        label: e.label,
        description: e.description,
      );

  ScheduleEntity toEntity() =>
      ScheduleEntity(id: id, label: label, description: description, type: type);

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) => SearchHistoryEntry(
        type: EntityType.values[json['type'] as int],
        id: json['id'] as int,
        label: (json['label'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'id': id,
        'label': label,
        'description': description,
      };
}

/// Недавние результаты общего поиска — до 10 штук, самый свежий сверху.
class SearchHistoryService {
  static const _key = 'search_recent_v1';
  static const _maxEntries = 10;

  Future<List<SearchHistoryEntry>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) {
          try {
            return SearchHistoryEntry.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<SearchHistoryEntry>()
        .toList();
  }

  Future<void> add(ScheduleEntity entity) async {
    final list = await readAll();
    list.removeWhere((e) => e.type == entity.type && e.id == entity.id);
    list.insert(0, SearchHistoryEntry.fromEntity(entity));
    await _write(list.take(_maxEntries).toList());
  }

  Future<void> remove(SearchHistoryEntry entry) async {
    final list = await readAll();
    list.removeWhere((e) => e.type == entry.type && e.id == entry.id);
    await _write(list);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _write(List<SearchHistoryEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
