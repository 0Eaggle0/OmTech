import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_work.dart';
import '../../services/report_work_service.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/lk_required_state.dart';
import '../../widgets/section_header.dart';
import 'report_work_detail_screen.dart';

class ReportWorkScreen extends StatefulWidget {
  const ReportWorkScreen({super.key});

  @override
  State<ReportWorkScreen> createState() => _ReportWorkScreenState();
}

class _ReportWorkScreenState extends State<ReportWorkScreen> {
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
    final lk = context.watch<LkController>();

    return Scaffold(
      appBar: AppBar(title: Text(l.reportWorksTitle)),
      floatingActionButton: lk.isConnected
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.reportUploadStub)),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('+'),
            )
          : null,
      body: !lk.isConnected
          ? const LkRequiredState()
          : _loading && _outcome == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _load(forceRefresh: true),
                  child: _content(context, l),
                ),
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
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
      children: [
        if (out.isDemo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DemoBanner(text: l.reportDemoNote),
          )
        else if (out.fromCache)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _cacheBanner(context, l),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _errorBanner(context, l),
          ),
        const SizedBox(height: 8),
        if (result.courseWorks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(child: SectionHeader(title: l.reportCourseWorks)),
                if (result.academicYear != null)
                  _yearChip(context, result.academicYear!),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...result.courseWorks.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _courseWorkCard(context, e.value, e.key),
                ),
              ),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SectionHeader(title: l.reportOtherWorks),
        ),
        const SizedBox(height: 8),
        // Поиск
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
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
        ),
        const SizedBox(height: 8),
        // Фильтр по статусу
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _filterChip(context, l.reportFilterAll, null),
              _filterChip(context, l.reportStatusAccepted, ReportWorkStatus.accepted),
              _filterChip(context, l.reportStatusRejected, ReportWorkStatus.rejected),
              _filterChip(context, l.reportStatusPending, ReportWorkStatus.pending),
            ],
          ),
        ),
        // Фильтр по семестру
        if (semesters.isNotEmpty) ...[
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _semesterChip(context, l, null),
                for (final s in semesters) _semesterChip(context, l, s),
              ],
            ),
          ),
        ],
        // Фильтр по предмету
        if (disciplines.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _disciplineButton(context, l, disciplines),
          ),
        ],
        const SizedBox(height: 8),
        if (filteredOther.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text(l.reportEmpty)),
          )
        else
          ...filteredOther.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _otherWorkCard(context, l, e.value, e.key),
                ),
              ),
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

  // ───────────── chips / filters ─────────────

  Widget _filterChip(BuildContext context, String label, ReportWorkStatus? value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = value),
      ),
    );
  }

  Widget _semesterChip(BuildContext context, AppLocalizations l, int? value) {
    final selected = _semesterFilter == value;
    final label = value == null
        ? '${l.reportFilterAll} ${l.reportSemesterLabel}'
        : '$value ${l.reportSemesterLabel}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _semesterFilter = value),
      ),
    );
  }

  Widget _disciplineButton(
      BuildContext context, AppLocalizations l, List<String> disciplines) {
    final theme = Theme.of(context);
    final hasFilter = _disciplineFilter != null;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: hasFilter ? theme.colorScheme.primary : null,
        side: hasFilter
            ? BorderSide(color: theme.colorScheme.primary)
            : null,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(l.reportSubjectFilter,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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

  // ───────────── cards ─────────────

  Widget _yearChip(BuildContext context, int yearStart) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$yearStart/${yearStart + 1}',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _courseWorkCard(BuildContext context, ReportCourseWork cw, int index) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cw.groupName,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cw.workType,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cw.title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    )
        .animate(key: ValueKey(cw.title))
        .fadeIn(duration: 180.ms)
        .slideY(begin: 0.04, curve: Curves.easeOut);
  }

  Widget _otherWorkCard(
      BuildContext context, AppLocalizations l, ReportWork w, int index) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportWorkDetailScreen(work: w)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      w.title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(context, l, w.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _metaLine(l, w),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (w.teacher.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  w.teacher,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
              if (w.comment != null && w.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
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
      ),
    )
        .animate(key: ValueKey(w.title))
        .fadeIn(duration: 180.ms)
        .slideY(begin: 0.04, curve: Curves.easeOut);
  }

  String _metaLine(AppLocalizations l, ReportWork w) {
    final parts = <String>[];
    parts.add(w.discipline);
    if (w.semester != null) parts.add('${w.semester} ${l.reportSemesterLabel}');
    if (w.workNumber.isNotEmpty) parts.add('${l.reportWorkNumberLabel} ${w.workNumber}');
    if (w.date != null) parts.add(DateFormat('dd.MM.yyyy').format(w.date!));
    return parts.join(' · ');
  }

  Widget _statusBadge(BuildContext context, AppLocalizations l, ReportWorkStatus status) {
    final (color, label) = switch (status) {
      ReportWorkStatus.accepted => (const Color(0xFF2EA04A), l.reportStatusAccepted),
      ReportWorkStatus.rejected => (const Color(0xFFE05A6B), l.reportStatusRejected),
      ReportWorkStatus.pending  => (const Color(0xFFB58A14), l.reportStatusPending),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  Widget _cacheBanner(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.offline_pin_outlined, size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l.lkCacheShown,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
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
          Icon(Icons.error_outline, size: 18, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(_error ?? l.error)),
        ],
      ),
    );
  }
}
