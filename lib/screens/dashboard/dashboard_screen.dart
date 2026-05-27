import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/group_controller.dart';
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
import '../materials/materials_screen.dart';
import '../news/news_detail_screen.dart';

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
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchNews();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userName = prefs.getString('user_name') ?? '');
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
  }

  /// Имя для приветствия: первое слово из ФИО, иначе «Студент»
  String get _greetingName {
    final trimmed = _userName.trim();
    if (trimmed.isEmpty) return 'Студент';
    return trimmed.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Горизонтальный padding убран с ListView — каждый элемент сам добавляет отступы,
    // чтобы NewsCarousel мог занять всю ширину без overflow.
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
              // Carousel — без горизонтального padding, занимает всю ширину
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
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                'Привет, $_greetingName!',
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l.dashboardSelectGroup,
                      style: TextStyle(
                        color: const Color(0xFF6C5CE7),
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
        final next = _findNext(snapshot.data ?? []);
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

  ScheduleEvent? _findNext(List<ScheduleEvent> events) {
    final now = DateTime.now();
    for (final e in events) {
      final dayEnd =
          DateTime(e.date.year, e.date.month, e.date.day, 23, 59);
      if (dayEnd.isAfter(now)) return e;
    }
    return events.isNotEmpty ? events.first : null;
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
        const SizedBox(width: 12),
        Expanded(
          child: TiltCard(
            child: _Tile(
              icon: Icons.folder_outlined,
              label: l.dashboardMaterials,
              gradient: const LinearGradient(
                colors: [Color(0xFF49C18B), Color(0xFF38A169)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              neonColor: const Color(0xFF49C18B),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MaterialsScreen()),
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
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerNewsCard(),
          );
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
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
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
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 6),
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
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Column(
              children: [
                Icon(icon, size: 32, color: Colors.white)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 2200.ms,
                      color: Colors.white.withValues(alpha: 0.4),
                      delay: 800.ms,
                    ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
