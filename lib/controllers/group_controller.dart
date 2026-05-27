import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/group.dart';

/// Хранит выбранную учебную группу и сохраняет её между запусками.
class GroupController extends ChangeNotifier {
  static const _idKey = 'group_id';
  static const _labelKey = 'group_label';

  Group? _group;
  Group? get group => _group;
  bool get hasGroup => _group != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_idKey);
    final label = prefs.getString(_labelKey);
    if (id != null && label != null) {
      _group = Group(id: id, label: label, description: '');
    }
    notifyListeners();
  }

  Future<void> select(Group group) async {
    _group = group;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idKey, group.id);
    await prefs.setString(_labelKey, group.label);
  }
}
