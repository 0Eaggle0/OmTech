import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/grade.dart';
import '../../models/student_record.dart';
import '../../services/grades_service.dart';
import '../../widgets/demo_banner.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen>
    with SingleTickerProviderStateMixin {
  GradesResult? _result;
  bool _loading = true;
  String? _error;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final lk = context.read<LkController>();
    final service = GradesService(lk: lk);
    setState(() {
      if (_result == null) _loading = true;
      _error = null;
    });
    try {
      await for (final r in service.watch(forceRefresh: forceRefresh)) {
        if (!mounted) return;
        setState(() {
          _result = r;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.lkLoadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // Перерисовка при изменении состояния ЛК.
    context.watch<LkController>();

    return Scaffold(
      appBar: AppBar(title: Text(l.gradesTitle)),
      body: _loading && _result == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(forceRefresh: true),
              child: _content(context, l),
            ),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l) {
    final result = _result;
    if (result == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 200),
          Center(child: Text(_error ?? l.error)),
        ],
      );
    }

    final record = result.record;
    final sections = record?.sections ?? const <Semester>[];

    if (_tabController == null || _tabController!.length != sections.length) {
      _tabController?.dispose();
      _tabController = TabController(length: sections.length, vsync: this);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.isDemo)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DemoBanner(text: l.gradesDemoNote),
          )
        else if (record != null && record.profile.fullName.isNotEmpty)
          _profileHeader(context, record.profile, result.fromCache),
        if (record != null && record.semesters.isNotEmpty)
          _semesterAccessStrip(context, record.semesters),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _errorBanner(context, l),
          ),
        const SizedBox(height: 8),
        if (sections.isEmpty)
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Icon(Icons.school_outlined,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    l.newsEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: sections
                .map((s) => Tab(text: _shortTitle(s.title, l)))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: sections.map((s) => _section(context, s)).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _profileHeader(
      BuildContext context, StudentProfile profile, bool fromCache) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profile.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (fromCache)
                    Tooltip(
                      message: l.lkCacheShown,
                      child: Icon(Icons.offline_pin_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  if (profile.groupLabel.isNotEmpty)
                    _meta(theme, Icons.groups_outlined, profile.groupLabel),
                  if (profile.bookNumber.isNotEmpty)
                    _meta(theme, Icons.menu_book_outlined,
                        '${l.lkBookNumber} ${profile.bookNumber}'),
                  if (profile.studyForm.isNotEmpty)
                    _meta(theme, Icons.history_edu_outlined, profile.studyForm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
        const SizedBox(width: 4),
        Text(text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            )),
      ],
    );
  }

  Widget _semesterAccessStrip(
      BuildContext context, List<SemesterAccess> semesters) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: semesters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = semesters[i];
          final color = s.hasAccess
              ? const Color(0xFF49C18B)
              : const Color(0xFFE05A6B);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  s.hasAccess ? Icons.check_circle_outline : Icons.block_outlined,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  '${s.number}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _errorBanner(BuildContext context, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 18, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(_error ?? l.error)),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, Semester semester) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          semester.title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...semester.grades.asMap().entries.map((entry) {
          return _gradeTile(context, entry.value)
              .animate(delay: (entry.key * 50).ms)
              .fadeIn(duration: 240.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut);
        }),
      ],
    );
  }

  Widget _gradeTile(BuildContext context, Grade g) {
    final theme = Theme.of(context);
    final markColor = _markColor(g.mark, g.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.discipline,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          _controlIcon(g.controlType),
                          size: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            g.controlType,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        if (g.date != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.event,
                              size: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('dd.MM.yyyy').format(g.date!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (g.teacher != null && g.teacher!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        g.teacher!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: markColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      g.mark,
                      style: TextStyle(
                        color: markColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (g.score != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${g.score} б.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                  if (g.hours != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      '${g.hours} ч.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortTitle(String title, AppLocalizations l) {
    final t = title.toLowerCase();
    if (t.contains('экзам')) return l.lkExamsSection;
    if (t.contains('зач')) return l.lkCreditsSection;
    if (t.contains('курс')) return l.lkCourseworkSection;
    return title;
  }

  Color _markColor(String mark, GradeStatus status) {
    if (status == GradeStatus.success) return const Color(0xFF49C18B);
    if (status == GradeStatus.warning) return const Color(0xFFE0A03A);
    if (status == GradeStatus.danger) return const Color(0xFFE05A6B);
    final m = mark.toLowerCase();
    if (m.contains('отл')) return const Color(0xFF49C18B);
    if (m.contains('хор')) return const Color(0xFF4F9DDE);
    if (m.contains('удовл')) return const Color(0xFFE0A03A);
    if (m.contains('зачт')) return const Color(0xFF8B5CF6);
    if (m.contains('незачт') || m.contains('неуд')) return const Color(0xFFE05A6B);
    return const Color(0xFF9A97A8);
  }

  IconData _controlIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('экзам')) return Icons.fact_check_outlined;
    if (t.contains('зачёт') || t.contains('зачет')) return Icons.check_circle_outline;
    if (t.contains('курс')) return Icons.menu_book_outlined;
    if (t.contains('вкр')) return Icons.school_outlined;
    return Icons.grade_outlined;
  }
}
