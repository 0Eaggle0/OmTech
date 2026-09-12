import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_work.dart';
import '../../services/report_work_service.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/accent_bar.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/pill_filter_row.dart';
import '../../widgets/section_caption.dart';
import '../../widgets/status_banners.dart';
import '../../widgets/status_pill.dart';
import 'report_work_detail_screen.dart';

/// Отладка: делится сырыми HTML-дампами страниц отчётных работ.
/// Свободная функция, а не метод вью — состояние экрана ей не нужно,
/// поэтому кнопку может держать шапка хаба.
Future<void> shareReportDebugDumps(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final api = context.read<LkController>().reportWorkApi;
  final paths = <String>[];
  for (final name in ['vkr2_shell', 'otherlist']) {
    final p = await api.lastDumpPath(name);
    if (p != null) paths.add(p);
  }
  if (paths.isEmpty) {
    messenger.showSnackBar(const SnackBar(
      content: Text('Дампы пока не сохранены — потяни список вниз для обновления.'),
    ));
    return;
  }
  await Share.shareXFiles(paths.map((p) => XFile(p)).toList(),
      subject: 'reports debug dumps');
}

/// Список отчётных работ. Без своего `Scaffold` — живёт внутри
/// `WorkHubScreen`, который владеет шапкой и переключателем разделов.
class ReportWorkListView extends StatefulWidget {
  const ReportWorkListView({super.key});

  @override
  State<ReportWorkListView> createState() => _ReportWorkListViewState();
}

class _ReportWorkListViewState extends State<ReportWorkListView> {
  ReportWorksOutcome? _outcome;
  bool _loading = true;
  String? _error;

  final _searchController = TextEditingController();
  String _query = '';
  ReportWorkStatus? _statusFilter;
  int? _semesterFilter;
  String? _disciplineFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final lk = context.read<LkController>();
    final service = ReportWorkService(lk: lk);
    setState(() {
      if (_outcome == null) _loading = true;
      _error = null;
    });
    try {
      await for (final out in service.watch(forceRefresh: forceRefresh)) {
        if (!mounted) return;
        setState(() {
          _outcome = out;
          _loading = false;
        });
      }
    } catch (_) {
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
    if (_loading && _outcome == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: _content(context, l),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l) {
    final out = _outcome;
    if (out == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 200),
          Center(child: Text(_error ?? l.error)),
        ],
      );
    }

    final result = out.result;
    final allOther = result.otherWorks;
    final semesters = allOther
        .map((w) => w.semester)
        .whereType<int>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final disciplines = allOther
        .map((w) => w.discipline)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final filteredOther = _applyFilters(allOther);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, navBottomPadding(context)),
      children: [
        if (out.isDemo)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DemoBanner(text: l.reportDemoNote),
          )
        else if (out.fromCache)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: CacheBanner(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ErrorBanner(_error!, onRetry: () => _load(forceRefresh: true)),
          ),
        if (result.courseWorks.isNotEmpty) ...[
          SectionCaption(
            l.reportCourseWorks,
            trailing: result.academicYear == null
                ? null
                : _yearChip(context, result.academicYear!),
          ),
          ...result.courseWorks.map((cw) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _courseWorkCard(context, cw),
              )),
          const SizedBox(height: 8),
        ],
        SectionCaption(l.reportOtherWorks),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: l.reportSearch,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        PillFilterRow(
          items: [
            PillFilterItem(l.reportFilterAll),
            PillFilterItem(l.reportStatusAccepted,
                dot: context.glass.statusColor(AppStatus.success)),
            PillFilterItem(l.reportStatusPending,
                dot: context.glass.statusColor(AppStatus.warning)),
            PillFilterItem(l.reportStatusRejected,
                dot: context.glass.statusColor(AppStatus.danger)),
          ],
          selected: switch (_statusFilter) {
            null => 0,
            ReportWorkStatus.accepted => 1,
            ReportWorkStatus.pending => 2,
            ReportWorkStatus.rejected => 3,
          },
          onSelected: (i) => setState(() {
            _statusFilter = switch (i) {
              1 => ReportWorkStatus.accepted,
              2 => ReportWorkStatus.pending,
              3 => ReportWorkStatus.rejected,
              _ => null,
            };
          }),
        ),
        if (semesters.isNotEmpty) ...[
          const SizedBox(height: 8),
          PillFilterRow(
            items: [
              PillFilterItem('${l.reportFilterAll} ${l.reportSemesterLabel}'),
              for (final s in semesters)
                PillFilterItem('$s ${l.reportSemesterLabel}'),
            ],
            selected: _semesterFilter == null
                ? 0
                : semesters.indexOf(_semesterFilter!) + 1,
            onSelected: (i) => setState(() {
              _semesterFilter = i == 0 ? null : semesters[i - 1];
            }),
          ),
        ],
        if (disciplines.isNotEmpty) ...[
          const SizedBox(height: 8),
          _disciplineButton(context, l, disciplines),
        ],
        const SizedBox(height: 10),
        if (filteredOther.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text(l.reportEmpty)),
          )
        else
          ...filteredOther.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _otherWorkCard(context, l, w),
              )),
      ],
    );
  }

  List<ReportWork> _applyFilters(List<ReportWork> items) {
    final q = _query.trim().toLowerCase();
    var filtered = items.where((w) {
      if (_statusFilter != null && w.status != _statusFilter) return false;
      if (_semesterFilter != null && w.semester != _semesterFilter) return false;
      if (_disciplineFilter != null && w.discipline != _disciplineFilter) return false;
      if (q.isEmpty) return true;
      return w.title.toLowerCase().contains(q) ||
          w.discipline.toLowerCase().contains(q);
    }).toList();
    // Сортируем: новые сверху.
    filtered.sort((a, b) =>
        (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    return filtered;
  }

  Widget _disciplineButton(
      BuildContext context, AppLocalizations l, List<String> disciplines) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final hasFilter = _disciplineFilter != null;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: hasFilter ? theme.colorScheme.primary : glass.textMuted,
        side: BorderSide(
          color: hasFilter ? theme.colorScheme.primary : glass.hairline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
      ),
      icon: const Icon(Icons.menu_book_outlined, size: 16),
      label: Text(
        _disciplineFilter ?? l.reportSubjectFilter,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () => _showDisciplineSheet(context, l, disciplines),
    );
  }

  void _showDisciplineSheet(
      BuildContext context, AppLocalizations l, List<String> disciplines) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(l.reportSubjectFilter,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: Text(l.reportAllSubjects),
              selected: _disciplineFilter == null,
              onTap: () {
                setState(() => _disciplineFilter = null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: disciplines.length,
                itemBuilder: (_, i) {
                  final d = disciplines[i];
                  return ListTile(
                    title: Text(d),
                    selected: _disciplineFilter == d,
                    onTap: () {
                      setState(() => _disciplineFilter = d);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yearChip(BuildContext context, int yearStart) {
    return StatusPill('$yearStart/${yearStart + 1}', status: AppStatus.accent);
  }

  Widget _courseWorkCard(BuildContext context, ReportCourseWork cw) {
    final theme = Theme.of(context);
    final glass = context.glass;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(cw.groupName, status: AppStatus.accent, dense: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cw.workType,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: glass.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(cw.title, style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    )
        .animate(key: ValueKey(cw.title))
        .fadeIn(duration: 180.ms)
        .slideY(begin: 0.04, curve: Curves.easeOut);
  }

  Widget _otherWorkCard(BuildContext context, AppLocalizations l, ReportWork w) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final status = switch (w.status) {
      ReportWorkStatus.accepted => AppStatus.success,
      ReportWorkStatus.pending => AppStatus.warning,
      ReportWorkStatus.rejected => AppStatus.danger,
    };
    final statusLabel = switch (w.status) {
      ReportWorkStatus.accepted => l.reportStatusAccepted,
      ReportWorkStatus.pending => l.reportStatusPending,
      ReportWorkStatus.rejected => l.reportStatusRejected,
    };
    final accent = glass.statusColor(status);
    final shape = BorderRadius.circular(AppRadius.card);

    return Material(
      color: glass.cardFill,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: shape,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportWorkDetailScreen(work: w)),
        ),
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0, child: AccentBar(accent)),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatusPill(w.discipline,
                            color: glass.textMuted, filled: false, dense: true),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(statusLabel, status: status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(w.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    _metaLine(l, w),
                    style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
                  ),
                  if (w.teacher.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      w.teacher,
                      style: theme.textTheme.bodySmall?.copyWith(color: glass.textFaint),
                    ),
                  ],
                  if (w.status == ReportWorkStatus.rejected &&
                      w.comment != null &&
                      w.comment!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: glass.tint(accent),
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                      ),
                      child: Text(
                        w.comment!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(key: ValueKey(w.title))
        .fadeIn(duration: 180.ms)
        .slideY(begin: 0.04, curve: Curves.easeOut);
  }

  String _metaLine(AppLocalizations l, ReportWork w) {
    final parts = <String>[];
    if (w.semester != null) parts.add('${w.semester} ${l.reportSemesterLabel}');
    if (w.workNumber.isNotEmpty) parts.add('${l.reportWorkNumberLabel} ${w.workNumber}');
    if (w.date != null) parts.add(DateFormat('dd.MM.yyyy').format(w.date!));
    return parts.join(' · ');
  }
}
