import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/group.dart';

/// Хранит выбранную учебную группу и сохраняет её между запусками.
class GroupController extends ChangeNotifier {
  static const _idKey = 'group_id';
  static const _labelKey = 'group_label';
  static const _subgroupKey = 'user_subgroup';

  Group? _group;
  int? _subgroup; // null = все подгруппы, 1 или 2 = конкретная

  Group? get group => _group;
  int? get subgroup => _subgroup;
  bool get hasGroup => _group != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_idKey);
    final label = prefs.getString(_labelKey);
    if (id != null && label != null) {
      _group = Group(id: id, label: label, description: '');
    }
    final sg = prefs.getInt(_subgroupKey);
    _subgroup = (sg == 1 || sg == 2) ? sg : null;
    notifyListeners();
  }

  Future<void> select(Group group) async {
    _group = group;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idKey, group.id);
    await prefs.setString(_labelKey, group.label);
  }

  Future<void> setSubgroup(int? sg) async {
    _subgroup = (sg == 1 || sg == 2) ? sg : null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_subgroup != null) {
      await prefs.setInt(_subgroupKey, _subgroup!);
    } else {
      await prefs.remove(_subgroupKey);
    }
  }
}
