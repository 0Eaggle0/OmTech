import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/group_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/group.dart';
import '../../models/schedule_entity.dart';
import '../../models/schedule_event.dart';
import '../../services/schedule_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/entity_search_sheet.dart';
import '../../widgets/group_search_sheet.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/lesson_detail_sheet.dart';
import '../../widgets/universal_search_sheet.dart';

enum _ScheduleMode { group, teacher, auditorium }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _api = ScheduleApi();

  _ScheduleMode _mode = _ScheduleMode.group;
  ScheduleEntity? _teacher;
  ScheduleEntity? _auditorium;

  late DateTime _weekStart;
  Future<List<ScheduleEvent>>? _future;
  int? _loadedGroupId;
  DateTime? _dateFilter;
  bool _weekView = false;
  bool _showOnlyMySubgroup = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = _mondayOf(now);
    // По умолчанию — сегодняшний день.
    _dateFilter = DateTime(now.year, now.month, now.day);
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
  }

  void _reload() {
    final group = context.read<GroupController>().group;
    final start = _weekStart;
    final finish = _weekStart.add(const Duration(days: 6));
    Future<List<ScheduleEvent>>? next;
    switch (_mode) {
      case _ScheduleMode.group:
        if (group != null) next = _api.getSchedule(group.id, start: start, finish: finish);
      case _ScheduleMode.teacher:
        if (_teacher != null) next = _api.getTeacherSchedule(_teacher!.id, start: start, finish: finish);
      case _ScheduleMode.auditorium:
        if (_auditorium != null) next = _api.getAuditoriumSchedule(_auditorium!.id, start: start, finish: finish);
    }
    if (next != null) setState(() { _future = next; });
  }

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
    final nextMonday = _mondayOf(next);
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
      _future = null;
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
    final start = _weekStart;
    final finish = _weekStart.add(const Duration(days: 6));
    Future<List<ScheduleEvent>> future;
    if (teacher != null) {
      future = _api.getTeacherSchedule(teacher.id, start: start, finish: finish);
      setState(() {
        _teacher = teacher;
        _future = future;
      });
    } else if (auditorium != null) {
      future = _api.getAuditoriumSchedule(auditorium.id, start: start, finish: finish);
      setState(() {
        _auditorium = auditorium;
        _future = future;
      });
    }
  }

  Future<void> _openUniversalSearch() async {
    final entity = await UniversalSearchSheet.show(context);
    if (entity == null || !mounted) return;

    switch (entity.type) {
      case EntityType.group:
        setState(() {
          _mode = _ScheduleMode.group;
          _future = null;
          _dateFilter = null;
        });
        if (!mounted) return;
        final g = Group(id: entity.id, label: entity.label, description: entity.description);
        await context.read<GroupController>().select(g);
      case EntityType.teacher:
        setState(() {
          _mode = _ScheduleMode.teacher;
          _dateFilter = null;
        });
        _setEntityAndReload(teacher: entity);
      case EntityType.auditorium:
        setState(() {
          _mode = _ScheduleMode.auditorium;
          _dateFilter = null;
        });
        _setEntityAndReload(auditorium: entity);
    }
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
      _weekStart = _mondayOf(picked);
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

  String? get _entityLabel {
    final group = context.read<GroupController>().group;
    return switch (_mode) {
      _ScheduleMode.group => group?.label,
      _ScheduleMode.teacher => _teacher?.label,
      _ScheduleMode.auditorium => _auditorium?.label,
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
    final groupCtrl = context.read<GroupController>();
    if (_showOnlyMySubgroup && groupCtrl.subgroup != null) {
      final mySg = groupCtrl.subgroup.toString();
      filtered = filtered.where((e) {
        if (e.subgroupNumber.isEmpty) return true; // общие для всех
        return e.subgroupNumber == mySg;
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = _entityLabel;
    final groupCtrl = context.watch<GroupController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.scheduleTitle),
        actions: [
          // Переключатель вида: день / неделя
          _viewToggle(l),
          // Выбор даты через календарь
          _appBarAction(
            icon: Icons.calendar_today_outlined,
            label: l.schedulePickDate,
            onTap: _pickDate,
          ),
          _appBarAction(
            icon: Icons.search,
            label: 'Поиск',
            onTap: _openUniversalSearch,
          ),
          TextButton.icon(
            onPressed: _pickEntity,
            icon: Icon(_modeIcon(_mode), size: 18),
            label: Text(
              label ?? _modePlaceholder(_mode),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _modeSwitcher(),
          _weekSwitcher(l),
          _dayRow(l),
          // Фильтр подгруппы — только если подгруппа задана
          if (groupCtrl.subgroup != null && _mode == _ScheduleMode.group)
            _subgroupFilterRow(l, groupCtrl.subgroup!),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -300) _shiftDay(1);
                if (v > 300) _shiftDay(-1);
              },
              child: _buildContent(l),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SegmentedButton<_ScheduleMode>(
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 13),
        ),
        segments: const [
          ButtonSegment(
            value: _ScheduleMode.group,
            icon: Icon(Icons.groups_outlined, size: 16),
            label: Text('Группа'),
          ),
          ButtonSegment(
            value: _ScheduleMode.teacher,
            icon: Icon(Icons.person_outline, size: 16),
            label: Text('Препод.'),
          ),
          ButtonSegment(
            value: _ScheduleMode.auditorium,
            icon: Icon(Icons.place_outlined, size: 16),
            label: Text('Аудит.'),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => _switchMode(s.first),
        showSelectedIcon: false,
      ),
    );
  }

  Widget _weekSwitcher(AppLocalizations l) {
    final end = _weekStart.add(const Duration(days: 6));
    final locale = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('d MMM', locale);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _shiftWeek(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '${fmt.format(_weekStart)} – ${fmt.format(end)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary
                      : isToday
                          ? primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
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
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

  Widget _subgroupFilterRow(AppLocalizations l, int mySubgroup) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Icon(Icons.people_outline, size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(
              _showOnlyMySubgroup
                  ? l.scheduleOnlyMySubgroup(mySubgroup)
                  : 'Все подгруппы',
            ),
            selected: _showOnlyMySubgroup,
            onSelected: (v) => setState(() => _showOnlyMySubgroup = v),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Иконка AppBar с подписью под ней — единый стиль для всех action-кнопок.
  Widget _appBarAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewToggle(AppLocalizations l) {
    return _appBarAction(
      icon: _weekView ? Icons.today_outlined : Icons.view_week_outlined,
      label: _weekView ? l.scheduleDayView : l.scheduleWeekView,
      onTap: _toggleView,
    );
  }

  void _toggleView() {
    if (_weekView) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayMonday = _mondayOf(today);
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
        title: _modeEmptyTitle(_mode),
        message: _modeEmptyMsg(_mode),
        actionLabel: _modePlaceholder(_mode),
        onAction: _pickEntity,
      );
    }

    return FutureBuilder<List<ScheduleEvent>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.none ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.wifi_off_outlined,
            title: l.scheduleLoadError,
            message: snapshot.error.toString(),
            actionLabel: l.scheduleRetry,
            onAction: _reload,
          );
        }
        final events = snapshot.data ?? [];
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
                ? 'Воскресенье!'
                : isToday
                    ? l.scheduleNoLessonsToday.split('\n').first
                    : 'Нет занятий',
            message: (isToday || isSunday)
                ? (isSunday && !isToday
                    ? 'Законный выходной — трогай траву! 🌿'
                    : l.scheduleNoLessonsTodayMsg)
                : 'В выбранный день пар нет',
            actionLabel: l.scheduleShowWeek,
            onAction: () => setState(() {
              _dateFilter = null;
              _weekView = true;
            }),
          );
        }
        return _eventsList(filtered);
      },
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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

  static String _modePlaceholder(_ScheduleMode m) => switch (m) {
        _ScheduleMode.group => 'Выбрать группу',
        _ScheduleMode.teacher => 'Выбрать препода',
        _ScheduleMode.auditorium => 'Выбрать аудит.',
      };

  static String _modeEmptyTitle(_ScheduleMode m) => switch (m) {
        _ScheduleMode.group => 'Группа не выбрана',
        _ScheduleMode.teacher => 'Преподаватель не выбран',
        _ScheduleMode.auditorium => 'Аудитория не выбрана',
      };

  static String _modeEmptyMsg(_ScheduleMode m) => switch (m) {
        _ScheduleMode.group => 'Выберите учебную группу для просмотра расписания',
        _ScheduleMode.teacher => 'Найдите любого преподавателя и смотрите его расписание на неделю',
        _ScheduleMode.auditorium => 'Найдите аудиторию и смотрите её занятость на неделю',
      };

  static DateTime _mondayOf(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
