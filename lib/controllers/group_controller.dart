import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/group.dart';
import '../services/app_prefs.dart';

/// Хранит выбранную учебную группу и сохраняет её между запусками.
class GroupController extends ChangeNotifier {
  static const _idKey = 'group_id';
  static const _labelKey = 'group_label';
  static const _subgroupKey = 'user_subgroup';

  /// Старый отдельный фильтр подгруппы с экрана расписания. Теперь подгруппа
  /// одна на всё приложение, поэтому ключ читаем один раз ради переноса.
  static const _legacyScheduleFilterKey = 'schedule_subgroup_filter';

  /// Ещё более старая настройка «только моя подгруппа» (bool).
  static const _legacyOnlyMineKey = 'schedule_only_my_subgroup';

  Group? _group;
  int? _subgroup; // null = все подгруппы, 1 или 2 = конкретная

  Group? get group => _group;
  int? get subgroup => _subgroup;
  bool get hasGroup => _group != null;

  Future<void> load() async {
    final prefs = appPrefs;
    final id = await prefs.getInt(_idKey);
    final label = await prefs.getString(_labelKey);
    if (id != null && label != null) {
      _group = Group(id: id, label: label, description: '');
    }
    _subgroup = await _readSubgroup(prefs);
    notifyListeners();
  }

  /// Подгруппа с переносом двух старых настроек экрана расписания.
  /// Переносим только один раз: после переноса старые ключи удаляем, иначе
  /// они каждый запуск перетирали бы выбор, сделанный в профиле.
  Future<int?> _readSubgroup(SharedPreferencesAsync prefs) async {
    final own = await prefs.getInt(_subgroupKey);
    if (own == 1 || own == 2) {
      await _dropLegacyKeys(prefs);
      return own;
    }

    // Старый bool «только моя подгруппа» переносить не из чего: он опирался
    // на эту же `_subgroupKey`, которой тут нет. Просто убираем ключ.
    final legacy = await prefs.getInt(_legacyScheduleFilterKey);
    await _dropLegacyKeys(prefs);
    if (legacy != 1 && legacy != 2) return null;
    await prefs.setInt(_subgroupKey, legacy!);
    return legacy;
  }

  Future<void> _dropLegacyKeys(SharedPreferencesAsync prefs) async {
    await prefs.remove(_legacyScheduleFilterKey);
    await prefs.remove(_legacyOnlyMineKey);
  }

  Future<void> select(Group group) async {
    _group = group;
    notifyListeners();
    final prefs = appPrefs;
    await prefs.setInt(_idKey, group.id);
    await prefs.setString(_labelKey, group.label);
  }

  Future<void> setSubgroup(int? sg) async {
    _subgroup = (sg == 1 || sg == 2) ? sg : null;
    notifyListeners();
    final prefs = appPrefs;
    if (_subgroup != null) {
      await prefs.setInt(_subgroupKey, _subgroup!);
    } else {
      await prefs.remove(_subgroupKey);
    }
  }
}
