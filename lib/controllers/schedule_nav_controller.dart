import 'package:flutter/foundation.dart';

import '../models/schedule_entity.dart';

/// Просьба показать в расписании конкретного преподавателя или аудиторию,
/// поданная извне (сейчас — из полноэкранного поиска).
///
/// Группа сюда не попадает — она идёт через `GroupController`, который
/// `ScheduleScreen` уже слушает.
class ScheduleNavController extends ChangeNotifier {
  ScheduleEntity? _pending;

  ScheduleEntity? get pending => _pending;

  void request(ScheduleEntity entity) {
    assert(entity.type != EntityType.group,
        'группа идёт через GroupController, не через этот контроллер');
    _pending = entity;
    notifyListeners();
  }

  /// Забирает и сбрасывает отложенную сущность. Без уведомления — это не
  /// новое событие, а подтверждение уже полученного.
  void clear() => _pending = null;
}
