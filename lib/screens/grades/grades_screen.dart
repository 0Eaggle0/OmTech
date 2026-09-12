import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/grade.dart';
import '../../models/student_record.dart';
import '../../services/grades_service.dart';
import '../../services/grades_summary.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/accent_bar.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/lk_required_state.dart';
import '../../widgets/pill_filter_row.dart';
import '../../widgets/section_caption.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/status_banners.dart';
import '../../widgets/status_pill.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  GradesResult? _result;
  bool _loading = true;
  String? _error;
  int? _selectedSemester;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final lk = context.read<LkController>();
    final service = GradesService(lk: lk);
    setState(() {
      if (_result == null) _loading = true;
      _error = null;
    });
    try {
      final stream = service.watch(forceRefresh: forceRefresh).timeout(
        const Duration(seconds: 25),
        onTimeout: (sink) => sink.addError(TimeoutException('grades load timeout')),
      );
      await for (final r in stream) {
        if (!mounted) return;
        setState(() {
          _result = r;
          _loading = false;
          _selectedSemester ??= _defaultSemester(r);
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

  int? _defaultSemester(GradesResult r) {
    final panels = r.record?.panels ?? const <SemesterPanel>[];
    if (panels.isEmpty) return null;
    final active = panels.where((p) => p.isActive).cast<SemesterPanel?>().firstWhere(
          (_) => true,
          orElse: () => null,
        );
    return (active ?? panels.first).number;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lk = context.watch<LkController>();

    return Scaffold(
      appBar: AppBar(title: Text(l.gradesTitle)),
      body: !lk.isConnected
          ? const LkRequiredState()
          : _loading && _result == null
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
    final panels = record?.panels ?? const <SemesterPanel>[];
    final selected = panels
        .where((p) => p.number == _selectedSemester)
        .cast<SemesterPanel?>()
        .firstWhere((_) => true, orElse: () => null);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        if (result.isDemo)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DemoBanner(text: l.gradesDemoNote),
          )
        else if (record != null && record.profile.fullName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _profileHeader(context, record, result.fromCache),
          ),
        if (result.fromCache && !result.isDemo)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: CacheBanner(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ErrorBanner(_error!, onRetry: () => _load(forceRefresh: true)),
          ),
        if (record != null && record.semesters.isNotEmpty) ...[
          _progressSection(context, l, record),
          const SizedBox(height: 14),
        ],
        if (panels.isNotEmpty) ...[
          _semesterTabs(context, l, panels),
          const SizedBox(height: 10),
        ],
        if (selected == null)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text(l.newsEmpty)),
          )
        else
          _semesterContent(context, l, selected),
      ],
    );
  }

  Widget _profileHeader(BuildContext context, StudentRecord record, bool fromCache) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final l = AppLocalizations.of(context)!;
    final profile = record.profile;
    final gpa = calcGpa(record);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: glass.tint(theme.colorScheme.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_outlined, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.fullName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      if (profile.groupLabel.isNotEmpty)
                        _meta(theme, glass, Icons.groups_outlined, profile.groupLabel),
                      if (profile.bookNumber.isNotEmpty)
                        _meta(theme, glass, Icons.menu_book_outlined,
                            '${l.lkBookNumber} ${profile.bookNumber}'),
                      if (profile.studyForm.isNotEmpty)
                        _meta(theme, glass, Icons.history_edu_outlined, profile.studyForm),
                    ],
                  ),
                ],
              ),
            ),
            if (gpa != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: glass.accentGradient,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
                child: Column(
                  children: [
                    Text(
                      gpa.toStringAsFixed(2),
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    Text('GPA',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 10,
                        )),
                  ],
                ),
              )
            else if (fromCache)
              Tooltip(
                message: l.lkCacheShown,
                child: Icon(Icons.offline_pin_outlined, size: 18, color: glass.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _meta(ThemeData theme, AppGlass glass, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: glass.textMuted),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted)),
      ],
    );
  }

  Widget _progressSection(
      BuildContext context, AppLocalizations l, StudentRecord record) {
    final activeNumber = record.panels
        .where((p) => p.isActive)
        .cast<SemesterPanel?>()
        .firstWhere((_) => true, orElse: () => null)
        ?.number;
    final course = activeNumber == null ? null : ((activeNumber + 1) / 2).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCaption(
          l.gradesProgress(record.semesters.length),
          trailing: course == null
              ? null
              : Text(
                  l.gradesCourse(course),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
        ),
        Row(
          children: [
            for (final access in record.semesters) ...[
              Expanded(
                child: _SemesterDot(
                  number: access.number,
                  isCurrent: access.number == activeNumber,
                  hasAccess: access.hasAccess,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _semesterTabs(BuildContext context, AppLocalizations l, List<SemesterPanel> panels) {
    final index = panels.indexWhere((p) => p.number == _selectedSemester);
    return PillFilterRow(
      items: [
        for (final p in panels) PillFilterItem(l.gradesSemesterLabel(p.number)),
      ],
      selected: index < 0 ? 0 : index,
      onSelected: (i) => setState(() => _selectedSemester = panels[i].number),
    );
  }

  Widget _semesterContent(
      BuildContext context, AppLocalizations l, SemesterPanel panel) {
    final glass = context.glass;
    if (panel.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 16),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: glass.textFaint),
            const SizedBox(height: 8),
            Text(
              l.gradesNoGradesYet(panel.number),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: glass.textMuted),
            ),
          ],
        ),
      );
    }

    final counts = countMarks(panel.sections.expand((s) => s.grades));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatTileRow([
          StatTile(
            value: '${counts.excellent}',
            caption: l.gradesExcellent,
            accent: glass.statusColor(AppStatus.success),
          ),
          StatTile(
            value: '${counts.good}',
            caption: l.gradesGood,
            accent: glass.statusColor(AppStatus.info),
          ),
          StatTile(
            value: '${counts.credited}',
            caption: l.gradesCredited,
            accent: glass.accent,
          ),
        ]),
        for (final section in panel.sections) ...[
          if (section.grades.isNotEmpty) _section(context, section),
        ],
      ],
    );
  }

  Widget _section(BuildContext context, Semester section) {
    final theme = Theme.of(context);
    final glass = context.glass;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_sectionIcon(section.title), size: 15, color: glass.textMuted),
              const SizedBox(width: 6),
              Text(
                section.title,
                style: theme.textTheme.labelSmall?.copyWith(color: glass.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...section.grades.asMap().entries.map((entry) {
            return _gradeTile(context, entry.value)
                .animate(delay: (entry.key * 40).ms)
                .fadeIn(duration: 220.ms)
                .slideY(begin: 0.04, curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }

  IconData _sectionIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('экзам')) return Icons.fact_check_outlined;
    if (t.contains('дифференц')) return Icons.verified_outlined;
    if (t.contains('зач')) return Icons.check_circle_outline;
    if (t.contains('курс')) return Icons.menu_book_outlined;
    if (t.contains('практ')) return Icons.engineering_outlined;
    return Icons.grade_outlined;
  }

  Widget _gradeTile(BuildContext context, Grade g) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final markColor = _markColor(glass, g.mark, g.status);
    final shape = BorderRadius.circular(AppRadius.card);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: glass.cardFill,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0, child: AccentBar(markColor)),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 14, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.discipline, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(_controlIcon(g.controlType), size: 13, color: glass.textFaint),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                g.controlType,
                                style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
                              ),
                            ),
                            if (g.date != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.event, size: 12, color: glass.textFaint),
                              const SizedBox(width: 3),
                              Text(
                                DateFormat('dd.MM.yyyy').format(g.date!),
                                style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
                              ),
                            ],
                          ],
                        ),
                        if (g.teacher != null && g.teacher!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            g.teacher!,
                            style: theme.textTheme.bodySmall?.copyWith(color: glass.textFaint),
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
                      StatusPill(g.mark, color: markColor),
                      if (g.score != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${g.score} б.',
                          style: theme.textTheme.bodySmall?.copyWith(color: glass.textFaint),
                        ),
                      ],
                      if (g.hours != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          '${g.hours} ч.',
                          style: theme.textTheme.bodySmall?.copyWith(color: glass.textFaint),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _markColor(AppGlass glass, String mark, GradeStatus status) {
    if (status == GradeStatus.success) return glass.statusColor(AppStatus.success);
    if (status == GradeStatus.warning) return glass.statusColor(AppStatus.warning);
    if (status == GradeStatus.danger) return glass.statusColor(AppStatus.danger);
    final m = mark.toLowerCase();
    if (m.contains('отл')) return glass.statusColor(AppStatus.success);
    if (m.contains('хор')) return glass.statusColor(AppStatus.info);
    if (m.contains('удовл')) return glass.statusColor(AppStatus.warning);
    if (m.contains('зачт')) return glass.accent;
    if (m.contains('незачт') || m.contains('неуд')) {
      return glass.statusColor(AppStatus.danger);
    }
    return glass.textMuted;
  }

  IconData _controlIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('экзам')) return Icons.fact_check_outlined;
    if (t.contains('дифф')) return Icons.verified_outlined;
    if (t.contains('зач')) return Icons.check_circle_outline;
    if (t.contains('курс')) return Icons.menu_book_outlined;
    if (t.contains('вкр')) return Icons.school_outlined;
    return Icons.grade_outlined;
  }
}

/// Кружок в ряду «Прогресс обучения»: пройден / текущий / закрыт.
class _SemesterDot extends StatelessWidget {
  final int number;
  final bool isCurrent;
  final bool hasAccess;

  const _SemesterDot({
    required this.number,
    required this.isCurrent,
    required this.hasAccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final passed = hasAccess && !isCurrent;

    final Color fg;
    final Color bg;
    final Widget child;
    if (isCurrent) {
      fg = Colors.white;
      bg = theme.colorScheme.primary;
      child = Text('$number',
          style: theme.textTheme.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w800));
    } else if (passed) {
      fg = glass.statusColor(AppStatus.success);
      bg = glass.tint(fg);
      child = Icon(Icons.check, size: 15, color: fg);
    } else {
      fg = glass.textFaint;
      bg = glass.elevatedFill;
      child = Icon(Icons.lock_outline, size: 13, color: fg);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: child,
          ),
          const SizedBox(height: 3),
          Text('$number', style: theme.textTheme.bodySmall?.copyWith(color: glass.textFaint)),
        ],
      ),
    );
  }
}
