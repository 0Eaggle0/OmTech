import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/group_controller.dart';
import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/group.dart';
import '../../models/news_item.dart';
import '../../models/schedule_entity.dart';
import '../../models/schedule_event.dart';
import '../../models/student_record.dart';
import '../../services/app_routes.dart';
import '../../services/news_service.dart';
import '../../services/schedule_api.dart';
import '../../services/weather_service.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/animated_mesh_background.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/lesson_detail_sheet.dart';
import '../../widgets/news_carousel.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_placeholder.dart';
import '../../widgets/tilt_card.dart';
import '../../widgets/universal_search_sheet.dart';
import '../grades/grades_screen.dart';
import '../news/news_detail_screen.dart';
import '../reports/report_work_screen.dart';
import '../work/work_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onOpenTab;

  const DashboardScreen({super.key, required this.onOpenTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scheduleApi = ScheduleApi.instance;
  final _newsService = NewsService();
  final _weatherService = WeatherService();

  late Future<List<NewsItem>> _newsFuture;
  late Future<WeatherInfo?> _weatherFuture;
  List<ScheduleEvent> _thisWeek = const [];
  List<ScheduleEvent> _nextWeek = const [];
  bool _scheduleLoading = false;
  int? _loadedGroupId;
  String _firstName = '';
  LkStatus? _lastLkStatus;
  bool _lkSummaryRequested = false;
  double? _gpa;
  int? _workCount;
  int? _reportCount;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchNews();
    // Уходит в сеть уже после первого кадра — не задерживает запуск и
    // не мешает, если запрос упадёт: строка погоды просто не появится.
    _weatherFuture = _weatherService.fetch();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    // Новый формат: отдельное поле имени.
    final firstName = prefs.getString('user_first_name') ?? '';
    if (firstName.isNotEmpty) {
      if (mounted) setState(() { _firstName = firstName; });
      return;
    }
    // Легаси: user_name.
    // Формат из ЛК: «РОГОЗА Владислав Юрьевич» — первое слово CAPS = фамилия,
    // имя на второй позиции. Ручной ввод обычно начинается с имени.
    final saved = prefs.getString('user_name') ?? '';
    if (saved.isNotEmpty) {
      final parts = saved.trim().split(' ');
      final name = parts.length >= 2 ? parts[1] : (parts.isNotEmpty ? parts[0] : '');
      // Авто-мигрируем: сохраняем имя в новый ключ чтобы следующий запуск был быстрее.
      if (name.isNotEmpty) {
        await prefs.setString('user_first_name', name);
      }
      if (!mounted) return;
      setState(() { _firstName = name; });
      return;
    }
    // Нет сохранённого — пробуем из ЛК.
    if (!mounted) return;
    final lk = context.read<LkController>();
    final lkName = lk.profile?.fullName ?? '';
    if (lkName.isNotEmpty) {
      final parts = lkName.trim().split(' ');
      // Формат ЛК: Фамилия Имя Отчество → берём parts[1].
      final name = parts.length >= 2 ? parts[1] : parts.first;
      await prefs.setString('user_first_name', name);
      if (!mounted) return;
      setState(() { _firstName = name; });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = context.watch<GroupController>().group;
    if (group != null && group.id != _loadedGroupId) {
      _loadedGroupId = group.id;
      _loadSchedule(group.id);
    }
    // Подхватываем имя из ЛК когда авто-логин завершается.
    final lk = context.watch<LkController>();
    if (_lastLkStatus != lk.status) {
      final wasConnected = _lastLkStatus == LkStatus.connected;
      _lastLkStatus = lk.status;
      if (lk.isConnected && _firstName.isEmpty) {
        final lkName = lk.profile?.fullName ?? '';
        if (lkName.isNotEmpty) {
          final parts = lkName.trim().split(' ');
          setState(() {
            _firstName = parts.length >= 2 ? parts[1] : parts.first;
          });
        }
        // Автозаполнение группы из ЛК.
        lk.autoFillGroupIfNeeded(context.read<GroupController>());
      }
      // Кэш сводки (GPA, счётчики) читаем и сразу после входа, и один раз
      // при первом построении экрана — он локальный, сети не трогает.
      if (lk.isConnected && !wasConnected) _loadLkSummary(lk);
    }
    if (!_lkSummaryRequested) {
      _lkSummaryRequested = true;
      _loadLkSummary(lk);
    }
  }

  /// Только кэш — GPA и счётчики на плитках не должны ждать сеть.
  Future<void> _loadLkSummary(LkController lk) async {
    final record = await lk.gradesApi.readCache();
    final disciplines = await lk.contactWorkApi.readDisciplinesCache();
    final reports = await lk.reportWorkApi.readCache();
    if (!mounted) return;
    setState(() {
      _gpa = record == null ? null : _calcGpa(record);
      _workCount = disciplines?.length;
      _reportCount = reports?.otherWorks.length;
    });
  }

  static double? _calcGpa(StudentRecord record) {
    final marks = record.allSections
        .expand((s) => s.grades)
        .map((g) => _markValue(g.mark))
        .whereType<double>()
        .toList();
    if (marks.isEmpty) return null;
    return marks.reduce((a, b) => a + b) / marks.length;
  }

  /// Зачёты («зачтено») в среднем балле не участвуют — у них нет оценки.
  static double? _markValue(String mark) {
    final m = mark.toLowerCase();
    if (m.contains('отл')) return 5;
    if (m.contains('хор')) return 4;
    if (m.contains('удовл')) return 3;
    if (m.contains('неуд')) return 2;
    return double.tryParse(mark.replaceAll(',', '.'));
  }

  /// Границы недели те же, что у экрана расписания, — значит тот же ключ
  /// кэша и один сетевой запрос на двоих. Следующую неделю трогаем, только
  /// если до конца текущей пар уже не осталось.
  Future<void> _loadSchedule(int groupId) async {
    setState(() {
      _thisWeek = const [];
      _nextWeek = const [];
      _scheduleLoading = true;
    });

    final monday = _mondayOf(DateTime.now());
    await _consumeWeek(groupId, monday, (events) => _thisWeek = events);

    if (!mounted || groupId != _loadedGroupId) return;
    if (!_hasUpcoming(_thisWeek)) {
      await _consumeWeek(groupId, monday.add(const Duration(days: 7)),
          (events) => _nextWeek = events);
    }

    if (!mounted || groupId != _loadedGroupId) return;
    setState(() => _scheduleLoading = false);
  }

  Future<void> _consumeWeek(
    int groupId,
    DateTime monday,
    void Function(List<ScheduleEvent>) assign,
  ) async {
    final stream = _scheduleApi.watchSchedule(
      type: EntityType.group,
      id: groupId,
      start: monday,
      finish: monday.add(const Duration(days: 6)),
    );
    try {
      await for (final snapshot in stream) {
        if (!mounted || groupId != _loadedGroupId) return;
        setState(() => assign(snapshot.events));
      }
    } catch (_) {
      // Ни сети, ни кэша — блок «ближайшая пара» просто останется пустым.
    }
  }

  bool _hasUpcoming(List<ScheduleEvent> events) {
    final now = DateTime.now();
    return events.any((e) => _parseTime(e.date, e.endLesson).isAfter(now));
  }

  static DateTime _mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String get _greetingName {
    if (_firstName.isNotEmpty) return _firstName;
    return 'Студент';
  }

  /// Номер учебной недели и её чётность — от понедельника недели, в которую
  /// попадает 1 сентября текущего учебного года. В API `rasp.omgtu.ru` этого
  /// поля нет, поэтому считаем локально: неделя 1 (с 1 сентября) — нечётная.
  (int number, bool isOdd) get _academicWeek {
    final now = DateTime.now();
    final academicYearStart = now.month >= 9 ? now.year : now.year - 1;
    final firstMonday = _mondayOf(DateTime(academicYearStart, 9, 1));
    final thisMonday = _mondayOf(now);
    final weeksSince = thisMonday.difference(firstMonday).inDays ~/ 7;
    final number = weeksSince + 1;
    return (number, number.isOdd);
  }

  int get _lessonsToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [..._thisWeek, ..._nextWeek]
        .where((e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day)
        .length;
  }

  Future<void> _openSearch() async {
    final entity = await UniversalSearchSheet.show(context);
    if (entity == null || !mounted) return;
    if (entity.type == EntityType.group) {
      await context.read<GroupController>().select(
            Group(id: entity.id, label: entity.label, description: entity.description),
          );
      return;
    }
    // Преподаватель/аудитория: полноценный переход на них будет в отдельном
    // экране поиска — пока просто открываем расписание.
    widget.onOpenTab(1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: AnimatedMeshBackground(
        child: SafeArea(
          // Низ не отрезаем: список уходит под плавающую панель.
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(top: 8, bottom: navBottomPadding(context)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _header(context, l)
                    .animate()
                    .fadeIn(duration: 300.ms),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _greeting(context, l)
                    .animate(delay: 40.ms)
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: -0.04, curve: Curves.easeOut),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _nextLessonSection(context, l)
                    .animate(delay: 80.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.04, curve: Curves.easeOut),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _tiles(context, l)
                    .animate(delay: 140.ms)
                    .fadeIn(duration: 300.ms),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeader(
                  title: l.dashboardNews,
                  actionLabel: l.dashboardAllNews,
                  onAction: () => widget.onOpenTab(2),
                ).animate(delay: 180.ms).fadeIn(duration: 300.ms),
              ),
              const SizedBox(height: 8),
              _newsPreview(context)
                  .animate(delay: 220.ms)
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final initial = _greetingName.isNotEmpty
        ? _greetingName[0].toUpperCase()
        : 'O';

    return Row(
      children: [
        GestureDetector(
          onTap: () => widget.onOpenTab(4),
          child: CircleAvatar(
            radius: 19,
            backgroundColor: glass.tint(theme.colorScheme.primary),
            child: Text(
              initial,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.appTitle, style: theme.textTheme.titleMedium),
              Text(
                l.dashboardSubtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: glass.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _openSearch,
          icon: const Icon(Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: glass.elevatedFill,
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _greeting(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final group = context.watch<GroupController>().group;
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr =
        _capitalize(DateFormat('EEEE, d MMMM', locale).format(DateTime.now()));
    final (weekNumber, weekOdd) = _academicWeek;
    final weekLabel = weekOdd ? l.dashboardWeekOdd : l.dashboardWeekEven;
    final lessonsToday = _lessonsToday;

    return GestureDetector(
      onTap: () => widget.onOpenTab(4),
      child: GlassSurface(
        radius: 24,
        blur: 18,
        border: false,
        gradient: glass.accentGradient,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _chip(dateStr),
                const SizedBox(width: 8),
                _chip('$weekLabel ($weekNumber)'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l.dashboardHello(_greetingName),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              group != null ? 'Группа ${group.label}' : l.dashboardNoGroup,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (group == null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => widget.onOpenTab(1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l.dashboardSelectGroup,
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
            const Divider(color: Colors.white24, height: 24),
            Row(
              children: [
                Expanded(child: _weatherLine(context)),
                Text(
                  lessonsToday > 0
                      ? l.dashboardLessonsToday(lessonsToday)
                      : l.dashboardNoLessonsToday,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _weatherLine(BuildContext context) {
    return FutureBuilder<WeatherInfo?>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        // Нет данных — сети/кэша не было: строка молча не рисуется.
        if (info == null) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, size: 15, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              '${info.tempC.round()}°C · Омск',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _nextLessonSection(BuildContext context, AppLocalizations l) {
    if (_loadedGroupId == null) {
      return _hintCard(context, l.dashboardNoGroup);
    }
    if (_scheduleLoading && _thisWeek.isEmpty && _nextWeek.isEmpty) {
      return const ShimmerGreeting();
    }
    final next = _findNextOrCurrent([..._thisWeek, ..._nextWeek]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l.dashboardNextLesson,
          actionLabel: l.navSchedule,
          onAction: () => widget.onOpenTab(1),
        ),
        const SizedBox(height: 8),
        if (next == null)
          _hintCard(context, l.dashboardNoNextLesson)
        else
          LessonCard(
            event: next,
            onTap: () => LessonDetailSheet.show(context, next),
          ),
      ],
    );
  }

  /// Сначала ищет текущую пару (идёт прямо сейчас), затем ближайшую.
  ScheduleEvent? _findNextOrCurrent(List<ScheduleEvent> events) {
    final now = DateTime.now();
    // 1) Пара, идущая прямо сейчас.
    for (final e in events) {
      final begin = _parseTime(e.date, e.beginLesson);
      final end = _parseTime(e.date, e.endLesson);
      if (!now.isBefore(begin) && now.isBefore(end)) return e;
    }
    // 2) Следующая предстоящая пара.
    for (final e in events) {
      final begin = _parseTime(e.date, e.beginLesson);
      if (begin.isAfter(now)) return e;
    }
    return events.isNotEmpty ? events.first : null;
  }

  DateTime _parseTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return date;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  Widget _tiles(BuildContext context, AppLocalizations l) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = (constraints.maxWidth - 20) / 3;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: w,
                child: TiltCard(
                  child: _Tile(
                    icon: Icons.grade_outlined,
                    label: l.dashboardGrades,
                    caption: _gpa == null
                        ? null
                        : l.dashboardGpaCaption(_gpa!.toStringAsFixed(2)),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F9DDE), Color(0xFF6C5CE7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    neonColor: const Color(0xFF4F9DDE),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GradesScreen()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: w,
                child: TiltCard(
                  child: _Tile(
                    icon: Icons.assignment_outlined,
                    label: l.dashboardTasks,
                    caption: _workCount == null
                        ? null
                        : l.dashboardWorkCountCaption(_workCount!),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF26C6DA), Color(0xFF00ACC1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    neonColor: const Color(0xFF26C6DA),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WorkListScreen()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: w,
                child: TiltCard(
                  child: _Tile(
                    icon: Icons.assignment_turned_in_outlined,
                    label: l.dashboardReportWorks,
                    caption: _reportCount == null
                        ? null
                        : l.dashboardReportCountCaption(_reportCount!),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE08F4F), Color(0xFFE05A6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    neonColor: const Color(0xFFE08F4F),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportWorkScreen()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _newsPreview(BuildContext context) {
    return FutureBuilder<List<NewsItem>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ShimmerCarousel();
        }
        final items = snapshot.data!.take(4).toList();
        return NewsCarousel(
          items: items,
          onTap: (item) => Navigator.push(
            context,
            AppRoutes.fadeScale(NewsDetailScreen(item: item)),
          ),
        );
      },
    );
  }

  Widget _hintCard(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? caption;
  final LinearGradient gradient;
  final Color neonColor;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
    this.caption,
    required this.gradient,
    required this.neonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: neonColor.withValues(alpha: 0.45),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: Colors.white)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 2200.ms,
                      color: Colors.white.withValues(alpha: 0.4),
                      delay: 800.ms,
                    ),
                const SizedBox(height: 7),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
