import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/group_controller.dart';
import '../../controllers/schedule_nav_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_entity.dart';
import '../../models/schedule_event.dart';
import '../../services/academic_week.dart';
import '../../services/schedule_api.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/entity_search_sheet.dart';
import '../../widgets/group_search_sheet.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/lesson_detail_sheet.dart';
import '../../widgets/pill_filter_row.dart';
import '../../widgets/sliding_toggle.dart';
import '../../widgets/status_banners.dart';
import '../../widgets/status_pill.dart';
import '../search/search_screen.dart';

enum _ScheduleMode { group, teacher, auditorium }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  /// Старый ключ: bool «только моя подгруппа». Заменён на выбор подгруппы,
  /// читаем один раз ради переноса настройки.
  static const _prefKeyOnlyMySubgroup = 'schedule_only_my_subgroup';
  static const _prefKeySubgroupFilter = 'schedule_subgroup_filter';
  static const _prefKeyHideRetake = 'schedule_hide_retake';

  final _api = ScheduleApi.instance;

  _ScheduleMode _mode = _ScheduleMode.group;
  ScheduleEntity? _teacher;
  ScheduleEntity? _auditorium;

  late DateTime _weekStart;
  Stream<ScheduleSnapshot>? _stream;
  int? _loadedGroupId;
  DateTime? _dateFilter;
  bool _weekView = false;

  /// null — показывать все подгруппы, иначе номер подгруппы.
  int? _subgroupFilter;
  bool _hideRetake = false;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = mondayOf(now);
    // По умолчанию — сегодняшний день.
    _dateFilter = DateTime(now.year, now.month, now.day);
    _loadFilterPrefs();
  }

  Future<void> _loadFilterPrefs() async {
    final profileSubgroup = context.read<GroupController>().subgroup;
    final prefs = await SharedPreferences.getInstance();
    final hideRetake = prefs.getBool(_prefKeyHideRetake) ?? false;

    int? subgroup = prefs.getInt(_prefKeySubgroupFilter);
    // Перенос старой настройки «только моя подгруппа» на выбор подгруппы.
    if (subgroup == null && (prefs.getBool(_prefKeyOnlyMySubgroup) ?? false)) {
      subgroup = profileSubgroup;
      await prefs.remove(_prefKeyOnlyMySubgroup);
      if (subgroup != null) {
        await prefs.setInt(_prefKeySubgroupFilter, subgroup);
      }
    }

    if (!mounted) return;
    if (subgroup == _subgroupFilter && hideRetake == _hideRetake) return;
    setState(() {
      _subgroupFilter = subgroup;
      _hideRetake = hideRetake;
    });
  }

  Future<void> _setSubgroupFilter(int? value) async {
    setState(() => _subgroupFilter = value);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_prefKeySubgroupFilter);
    } else {
      await prefs.setInt(_prefKeySubgroupFilter, value);
    }
  }

  Future<void> _saveFilterBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mode == _ScheduleMode.group) {
      final group = context.watch<GroupController>().group;
      if (group != null && group.id != _loadedGroupId) {
        _loadedGroupId = group.id;
        _reload();
      }
    }
    // Препод/аудитория, выбранные в полноэкранном поиске (на любой вкладке),
    // прилетают сюда через провайдер — сама вкладка не обязана быть открыта.
    final nav = context.watch<ScheduleNavController>();
    final pending = nav.pending;
    if (pending != null) {
      nav.clear();
      _applyPendingEntity(pending);
    }
  }

  void _reload() {
    final group = context.read<GroupController>().group;
    final (type, id) = switch (_mode) {
      _ScheduleMode.group => (EntityType.group, group?.id),
      _ScheduleMode.teacher => (EntityType.teacher, _teacher?.id),
      _ScheduleMode.auditorium => (EntityType.auditorium, _auditorium?.id),
    };
    if (id == null) return;
    setState(() { _stream = _watch(type, id); });
  }

  Stream<ScheduleSnapshot> _watch(EntityType type, int id) => _api.watchSchedule(
        type: type,
        id: id,
        start: _weekStart,
        finish: _weekStart.add(const Duration(days: 6)),
      );

  void _shiftWeek(int weeks) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * weeks));
      _dateFilter = null;
    });
    _reload();
  }

  /// Сдвигает выбранный день на [delta] дней. При выходе за границы недели — меняет неделю.
  void _shiftDay(int delta) {
    final now = DateTime.now();
    final base = _dateFilter ?? DateTime(now.year, now.month, now.day);
    final next = base.add(Duration(days: delta));
    final nextMonday = mondayOf(next);
    final weekChanged = nextMonday != _weekStart;
    setState(() {
      _weekStart = nextMonday;
      _dateFilter = next;
      _weekView = false;
    });
    if (weekChanged) _reload();
  }

  void _switchMode(_ScheduleMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _stream = null;
      _dateFilter = null;
    });
    _reload();
  }

  Future<void> _pickEntity() async {
    switch (_mode) {
      case _ScheduleMode.group:
        final group = await GroupSearchSheet.show(context);
        if (group != null && mounted) {
          await context.read<GroupController>().select(group);
        }
      case _ScheduleMode.teacher:
        final entity = await EntitySearchSheet.showForTeacher(context);
        if (entity != null && mounted) {
          _setEntityAndReload(teacher: entity);
        }
      case _ScheduleMode.auditorium:
        final entity = await EntitySearchSheet.showForAuditorium(context);
        if (entity != null && mounted) {
          _setEntityAndReload(auditorium: entity);
        }
    }
  }

  void _setEntityAndReload({ScheduleEntity? teacher, ScheduleEntity? auditorium}) {
    if (teacher != null) {
      setState(() {
        _teacher = teacher;
        _stream = _watch(EntityType.teacher, teacher.id);
      });
    } else if (auditorium != null) {
      setState(() {
        _auditorium = auditorium;
        _stream = _watch(EntityType.auditorium, auditorium.id);
      });
    }
  }

  /// Полноэкранный поиск сам применяет результат — через `GroupController`
  /// для группы и через `ScheduleNavController` для препода/аудитории
  /// (см. `_applyPendingEntity`, вызывается из `didChangeDependencies`).
  Future<void> _openUniversalSearch() {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  void _applyPendingEntity(ScheduleEntity entity) {
    setState(() {
      _dateFilter = null;
      switch (entity.type) {
        case EntityType.teacher:
          _mode = _ScheduleMode.teacher;
          _teacher = entity;
          _stream = _watch(EntityType.teacher, entity.id);
        case EntityType.auditorium:
          _mode = _ScheduleMode.auditorium;
          _auditorium = entity;
          _stream = _watch(EntityType.auditorium, entity.id);
        case EntityType.group:
          break; // группа идёт через GroupController, см. didChangeDependencies
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _weekStart = mondayOf(picked);
      _dateFilter = DateTime(picked.year, picked.month, picked.day);
      _weekView = false;
    });
    _reload();
  }

  bool get _hasEntity {
    final group = context.read<GroupController>().group;
    return switch (_mode) {
      _ScheduleMode.group => group != null,
      _ScheduleMode.teacher => _teacher != null,
      _ScheduleMode.auditorium => _auditorium != null,
    };
  }


  List<ScheduleEvent> _applyFilters(List<ScheduleEvent> events) {
    var filtered = events;
    if (!_weekView && _dateFilter != null) {
      filtered = filtered.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return d == _dateFilter;
      }).toList();
    }
    // Фильтр по подгруппе.
    final subgroup = _subgroupFilter;
    if (subgroup != null) {
      final wanted = subgroup.toString();
      filtered = filtered.where((e) {
        if (e.subgroupNumber.isEmpty) return true; // общие для всех
        return e.subgroupNumber == wanted;
      }).toList();
    }
    // Фильтр пересдач.
    if (_hideRetake) {
      filtered = filtered.where((e) {
        final k = e.kindOfWork.toLowerCase();
        return !k.contains('пересдач') && !k.contains('допуск') && !k.contains('консультац');
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // watch, а не read: смена группы должна перерисовать чип в шапке.
    final groupCtrl = context.watch<GroupController>();
    final label = switch (_mode) {
      _ScheduleMode.group => groupCtrl.group?.label,
      _ScheduleMode.teacher => _teacher?.label,
      _ScheduleMode.auditorium => _auditorium?.label,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l.scheduleTitle),
        actions: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ActionChip(
                avatar: Icon(_modeIcon(_mode), size: 16),
                label: Text(
                  label ?? _modePlaceholder(l, _mode),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _pickEntity,
              ),
            ),
          ),
          IconButton(
            onPressed: _openUniversalSearch,
            tooltip: l.scheduleSearch,
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _actionRow(l),
          _modeSwitcher(l),
          _weekSwitcher(l),
          _dayRow(l),
          if (_mode == _ScheduleMode.group) ...[
            _subgroupFilterRow(l),
            _retakeFilterRow(l),
          ],
          Expanded(
            child: GestureDetector(
              // В пустой день контент — маленький блок по центру, и при
              // deferToChild свайп по остальной площади не долетает сюда.
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _dragDx = 0,
              onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                final distance = _dragDx;
                _dragDx = 0;
                final flicked = velocity.abs() > 300;
                final dragged = distance.abs() > 60;
                if (!flicked && !dragged) return;
                // Медленный, но длинный свайп листает день наравне с рывком.
                _shiftDay((flicked ? velocity : distance) < 0 ? 1 : -1);
              },
              child: _buildContent(l),
            ),
          ),
        ],
      ),
    );
  }

  /// Три действия одной плашкой: вид недели/дня, календарь и поиск.
  Widget _actionRow(AppLocalizations l) {
    final glass = context.glass;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: glass.elevatedFill,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(color: glass.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: _action(
                icon: _weekView ? Icons.today_outlined : Icons.view_week_outlined,
                label: _weekView ? l.scheduleDayView : l.scheduleWeekView,
                active: _weekView,
                onTap: _toggleView,
              ),
            ),
            Expanded(
              child: _action(
                icon: Icons.calendar_today_outlined,
                label: l.schedulePickDate,
                onTap: _pickDate,
              ),
            ),
            Expanded(
              child: _action(
                icon: Icons.manage_search,
                label: l.scheduleSearch,
                onTap: _openUniversalSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final color = active ? theme.colorScheme.primary : glass.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSwitcher(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SlidingToggle(
        items: [
          SlidingToggleItem(icon: Icons.groups_outlined, label: l.scheduleModeGroup),
          SlidingToggleItem(icon: Icons.person_outline, label: l.scheduleModeTeacher),
          SlidingToggleItem(icon: Icons.place_outlined, label: l.scheduleModeAuditorium),
        ],
        selected: _mode.index,
        onSelected: (i) => _switchMode(_ScheduleMode.values[i]),
      ),
    );
  }

  Widget _weekSwitcher(AppLocalizations l) {
    final end = _weekStart.add(const Duration(days: 6));
    final locale = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('d MMM', locale);
    final week = academicWeekOf(_weekStart);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _shiftWeek(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    '${fmt.format(_weekStart)} – ${fmt.format(end)}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(
                  '${week.isOdd ? l.dashboardWeekOdd : l.dashboardWeekEven}'
                  ' (${week.number})',
                  status: AppStatus.accent,
                  dense: true,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _shiftWeek(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /// 7 кнопок дней — все видимые в одну строку.
  Widget _dayRow(AppLocalizations l) {
    final locale = Localizations.localeOf(context).languageCode;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final dayNames = locale == 'ru'
        ? ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
        : ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: List.generate(7, (i) {
          final day = _weekStart.add(Duration(days: i));
          final dayOnly = DateTime(day.year, day.month, day.day);
          final isSelected = !_weekView && _dateFilter == dayOnly;
          final isToday = dayOnly == today;
          final theme = Theme.of(context);
          final glass = context.glass;
          final primary = theme.colorScheme.primary;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                if (_weekView) {
                  _weekView = false;
                  _dateFilter = dayOnly;
                } else if (_dateFilter == dayOnly) {
                  _dateFilter = null; // снять фильтр
                } else {
                  _dateFilter = dayOnly;
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary
                      : isToday
                          ? glass.tint(primary)
                          : glass.elevatedFill,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                  border: Border.all(
                    color: isSelected ? primary : glass.hairline,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayNames[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? primary
                                : glass.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? primary
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Все подгруппы / 1-я / 2-я — независимо от подгруппы в профиле.
  Widget _subgroupFilterRow(AppLocalizations l) {
    final selected = switch (_subgroupFilter) {
      1 => 1,
      2 => 2,
      _ => 0,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: PillFilterRow(
        items: [
          PillFilterItem(l.scheduleAllSubgroups),
          PillFilterItem(l.scheduleSubgroupN(1)),
          PillFilterItem(l.scheduleSubgroupN(2)),
        ],
        selected: selected,
        onSelected: (i) => _setSubgroupFilter(i == 0 ? null : i),
      ),
    );
  }

  Widget _retakeFilterRow(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          PillToggle(
            label: l.scheduleHideRetake,
            icon: Icons.filter_alt_outlined,
            selected: _hideRetake,
            onChanged: (v) {
              setState(() => _hideRetake = v);
              _saveFilterBool(_prefKeyHideRetake, v);
            },
          ),
        ],
      ),
    );
  }

  void _toggleView() {
    if (_weekView) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayMonday = mondayOf(today);
      final weekChanged = todayMonday != _weekStart;
      setState(() {
        _weekView = false;
        _weekStart = todayMonday;
        _dateFilter = today;
      });
      if (weekChanged) _reload();
    } else {
      setState(() {
        _weekView = true;
        _dateFilter = null;
      });
    }
  }

  Widget _buildContent(AppLocalizations l) {
    if (!_hasEntity) {
      return EmptyState(
        icon: _modeIcon(_mode),
        title: _modeEmptyTitle(l, _mode),
        message: _modeEmptyMsg(l, _mode),
        actionLabel: _modePlaceholder(l, _mode),
        onAction: _pickEntity,
      );
    }

    if (_stream == null) {
      // Сущность уже выбрана, а поток ещё не создан — такого не должно
      // происходить, но `StreamBuilder(stream: null)` завис бы в спиннере
      // навсегда без единого шанса на восстановление. Досоздаём поток сразу
      // после кадра вместо того, чтобы полагаться только на побочный эффект
      // в `didChangeDependencies`.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _stream == null) _reload();
      });
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<ScheduleSnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return EmptyState(
            icon: Icons.wifi_off_outlined,
            title: l.scheduleLoadError,
            message: snapshot.error.toString(),
            actionLabel: l.scheduleRetry,
            onAction: _reload,
          );
        }
        final events = snapshot.data?.events ?? [];
        if (events.isEmpty) {
          return EmptyState(
            icon: Icons.event_available_outlined,
            title: l.scheduleNoLessons,
            message: l.scheduleNoLessonsMsg,
          );
        }
        final filtered = _applyFilters(events);
        if (filtered.isEmpty) {
          final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          final isToday = _dateFilter == today;
          final isSunday = _dateFilter?.weekday == DateTime.sunday;
          return EmptyState(
            icon: (isToday || isSunday) ? Icons.nature_people_outlined : Icons.filter_list_off,
            title: isSunday && !isToday
                ? l.scheduleSunday
                : isToday
                    ? l.scheduleNoLessonsToday.split('\n').first
                    : l.scheduleNoLessonsDay,
            message: (isToday || isSunday)
                ? (isSunday && !isToday
                    ? l.scheduleSundayMsg
                    : l.scheduleNoLessonsTodayMsg)
                : l.scheduleNoLessonsDayMsg,
            actionLabel: l.scheduleShowWeek,
            onAction: () => setState(() {
              _dateFilter = null;
              _weekView = true;
            }),
          );
        }
        final data = snapshot.data;
        final at = data?.fetchedAt;
        if (data == null || at == null) return _eventsList(filtered);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: data.fromCache
                  ? CacheBanner(updatedAt: at)
                  : _syncedNotice(l, at),
            ),
            Expanded(child: _eventsList(filtered)),
          ],
        );
      },
    );
  }

  /// Данные свежие — показываем время последней синхронизации.
  Widget _syncedNotice(AppLocalizations l, DateTime at) {
    final theme = Theme.of(context);
    final glass = context.glass;
    return Row(
      children: [
        Icon(Icons.sync, size: 14, color: glass.textMuted),
        const SizedBox(width: 6),
        Text(
          l.scheduleCachedAt(DateFormat('HH:mm').format(at)),
          style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
        ),
      ],
    );
  }

  Widget _eventsList(List<ScheduleEvent> events) {
    final byDay = <DateTime, List<ScheduleEvent>>{};
    for (final e in events) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      byDay.putIfAbsent(day, () => []).add(e);
    }
    final days = byDay.keys.toList()..sort();
    final locale = Localizations.localeOf(context).languageCode;
    final dayFmt = DateFormat('EEEE, d MMMM', locale);

    int cardIndex = 0;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, navBottomPadding(context)),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final lessons = byDay[day]!;
        final headerDelay = (i * 40).ms;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_weekView || days.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                child: Text(
                  _capitalize(dayFmt.format(day)),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ).animate(delay: headerDelay).fadeIn(duration: 250.ms),
              ),
            for (final e in lessons) ...[
              () {
                final delay = (cardIndex++ * 55).ms;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LessonCard(
                    event: e,
                    onTap: () => LessonDetailSheet.show(context, e),
                  ).animate(delay: delay).fadeIn(duration: 280.ms).slideY(begin: 0.05, curve: Curves.easeOut),
                );
              }(),
            ],
          ],
        );
      },
    );
  }

  static IconData _modeIcon(_ScheduleMode m) => switch (m) {
        _ScheduleMode.group => Icons.groups_outlined,
        _ScheduleMode.teacher => Icons.person_outline,
        _ScheduleMode.auditorium => Icons.place_outlined,
      };

  static String _modePlaceholder(AppLocalizations l, _ScheduleMode m) =>
      switch (m) {
        _ScheduleMode.group => l.schedulePickGroup,
        _ScheduleMode.teacher => l.schedulePickTeacher,
        _ScheduleMode.auditorium => l.schedulePickAuditorium,
      };

  static String _modeEmptyTitle(AppLocalizations l, _ScheduleMode m) =>
      switch (m) {
        _ScheduleMode.group => l.scheduleNoGroup,
        _ScheduleMode.teacher => l.scheduleNoTeacher,
        _ScheduleMode.auditorium => l.scheduleNoAuditorium,
      };

  static String _modeEmptyMsg(AppLocalizations l, _ScheduleMode m) =>
      switch (m) {
        _ScheduleMode.group => l.scheduleNoGroupMsg,
        _ScheduleMode.teacher => l.scheduleNoTeacherMsg,
        _ScheduleMode.auditorium => l.scheduleNoAuditoriumMsg,
      };

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
