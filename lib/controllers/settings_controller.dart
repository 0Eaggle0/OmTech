import 'package:flutter/foundation.dart';
import '../services/app_prefs.dart';

/// Категория уведомлений. Совпадает с каналами `NotificationService`.
enum NotifCategory { tasks, reports, grades, schedule }

/// Пользовательские настройки уведомлений.
///
/// Сами флаги лежат в `SharedPreferences`, потому что их читает ещё и фоновый
/// изолят WorkManager — там нет ни провайдеров, ни этого контроллера.
/// Контроллер нужен только для UI.
class SettingsController extends ChangeNotifier {
  static String prefKeyFor(NotifCategory c) => switch (c) {
        NotifCategory.tasks => 'notif_tasks_enabled',
        NotifCategory.reports => 'notif_reports_enabled',
        NotifCategory.grades => 'notif_grades_enabled',
        NotifCategory.schedule => 'notif_schedule_enabled',
      };

  final _enabled = <NotifCategory, bool>{
    NotifCategory.tasks: true,
    NotifCategory.reports: true,
    NotifCategory.grades: true,
    NotifCategory.schedule: true,
  };

  bool isEnabled(NotifCategory c) => _enabled[c] ?? true;

  Future<void> load() async {
    final prefs = appPrefs;
    for (final c in NotifCategory.values) {
      _enabled[c] = await prefs.getBool(prefKeyFor(c)) ?? true;
    }
    notifyListeners();
  }

  Future<void> setEnabled(NotifCategory c, bool value) async {
    _enabled[c] = value;
    notifyListeners();
    final prefs = appPrefs;
    await prefs.setBool(prefKeyFor(c), value);
  }
}
