import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/group_controller.dart';
import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_item.dart';
import '../../models/schedule_event.dart';
import '../../services/app_routes.dart';
import '../../services/news_service.dart';
import '../../services/schedule_api.dart';
import '../../widgets/animated_mesh_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/lesson_detail_sheet.dart';
import '../../widgets/news_carousel.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_placeholder.dart';
import '../../widgets/tilt_card.dart';
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
  final _scheduleApi = ScheduleApi();
  final _newsService = NewsService();

  late Future<List<NewsItem>> _newsFuture;
  Future<List<ScheduleEvent>>? _scheduleFuture;
  int? _loadedGroupId;
  String _firstName = '';
  LkStatus? _lastLkStatus;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchNews();
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
      final now = DateTime.now();
      _scheduleFuture = _scheduleApi.getSchedule(
        group.id,
        start: DateTime(now.year, now.month, now.day),
        finish: now.add(const Duration(days: 7)),
      );
    }
    // Подхватываем имя из ЛК когда авто-логин завершается.
    final lk = context.watch<LkController>();
    if (_lastLkStatus != lk.status) {
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
    }
  }

  String get _greetingName {
    if (_firstName.isNotEmpty) return _firstName;
    return 'Студент';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: AnimatedMeshBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _greeting(context, l)
                    .animate()
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

  Widget _greeting(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final group = context.watch<GroupController>().group;
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr =
        _capitalize(DateFormat('EEEE, d MMMM', locale).format(DateTime.now()));

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 30, bottom: -30,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dateStr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.dashboardHello(_greetingName),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextLessonSection(BuildContext context, AppLocalizations l) {
    if (_scheduleFuture == null) {
      return _hintCard(context, l.dashboardNoGroup);
    }
    return FutureBuilder<List<ScheduleEvent>>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerGreeting();
        }
        final next = _findNextOrCurrent(snapshot.data ?? []);
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
      },
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
    return Row(
      children: [
        Expanded(
          child: TiltCard(
            child: _Tile(
              icon: Icons.grade_outlined,
              label: l.dashboardGrades,
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
        Expanded(
          child: TiltCard(
            child: _Tile(
              icon: Icons.assignment_outlined,
              label: l.dashboardTasks,
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
        Expanded(
          child: TiltCard(
            child: _Tile(
              icon: Icons.assignment_turned_in_outlined,
              label: l.dashboardReportWorks,
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
  final LinearGradient gradient;
  final Color neonColor;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
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
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 26, color: Colors.white)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 2200.ms,
                      color: Colors.white.withValues(alpha: 0.4),
                      delay: 800.ms,
                    ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
