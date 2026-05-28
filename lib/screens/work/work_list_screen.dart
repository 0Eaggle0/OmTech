import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contact_work.dart';
import '../../services/contact_work_service.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/lk_required_state.dart';
import 'work_detail_screen.dart';

class WorkListScreen extends StatefulWidget {
  const WorkListScreen({super.key});

  @override
  State<WorkListScreen> createState() => _WorkListScreenState();
}

class _WorkListScreenState extends State<WorkListScreen> {
  ContactWorkResult? _result;
  bool _loading = true;
  String? _error;

  /// Кол-во новых заданий по каждой дисциплине: disciplineId → diff.
  Map<String, int> _newCounts = const {};

  final _searchController = TextEditingController();
  String _query = '';

  LkStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Перевзвести загрузку при смене статуса ЛК (login/logout).
    final lk = context.read<LkController>();
    if (_lastStatus != null && _lastStatus != lk.status) {
      _load();
    }
    _lastStatus = lk.status;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final lk = context.read<LkController>();
    final service = ContactWorkService(lk: lk);
    setState(() {
      if (_result == null) _loading = true;
      _error = null;
    });
    try {
      await for (final r
          in service.watchDisciplines(forceRefresh: forceRefresh)) {
        if (!mounted) return;
        final counts = await _calcNewCounts(lk, r);
        if (!mounted) return;
        setState(() {
          _result = r;
          _loading = false;
          _newCounts = counts;
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

  Future<Map<String, int>> _calcNewCounts(
      LkController lk, ContactWorkResult r) async {
    if (r.isDemo || !lk.isConnected) return const {};
    final api = lk.contactWorkApi;
    final out = <String, int>{};
    for (final d in r.items) {
      if (d.id == null) continue;
      out[d.id!] = await api.calcNewCount(d);
    }
    return out;
  }

  /// Пересчитывает бейджи, не делая сетевых запросов — нужно для
  /// мгновенного обновления после возврата с экрана деталей.
  Future<void> _recalcBadges() async {
    final result = _result;
    if (result == null) return;
    final lk = context.read<LkController>();
    final counts = await _calcNewCounts(lk, result);
    if (!mounted) return;
    setState(() => _newCounts = counts);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lk = context.watch<LkController>();

    return Scaffold(
      appBar: AppBar(title: Text(l.workTitle)),
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

    final all = result.items;
    final filtered = _query.isEmpty
        ? all
        : all
            .where((d) =>
                d.discipline.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: l.workSearch,
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
        if (result.isDemo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DemoBanner(text: l.workDemoNote),
          )
        else if (result.fromCache)
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
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text(l.newsEmpty)),
          )
        else
          ...filtered.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _disciplineCard(context, l, e.value, e.key),
                ),
              ),
      ],
    );
  }

  Widget _cacheBanner(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.offline_pin_outlined,
            size: 16,
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
          Icon(Icons.error_outline,
              size: 18, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(_error ?? l.error)),
        ],
      ),
    );
  }

  Widget _disciplineCard(BuildContext context, AppLocalizations l,
      WorkDiscipline d, int index) {
    final theme = Theme.of(context);
    final newCount = d.id == null ? 0 : (_newCounts[d.id] ?? 0);
    final hasNew = newCount > 0;
    final badgeColor =
        hasNew ? const Color(0xFFE05A6B) : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WorkDetailScreen(discipline: d)),
            );
            if (mounted) _recalcBadges();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.discipline,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.teachers.isEmpty
                            ? '${l.workTeachers}: —'
                            : '${l.workTeachers}: ${d.teachers.join(', ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: hasNew
                            ? Border.all(
                                color: badgeColor.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasNew) ...[
                            Icon(Icons.fiber_new_outlined,
                                size: 14, color: badgeColor),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            hasNew ? '+$newCount' : '${d.taskCount}',
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasNew ? 'новых' : l.workTaskCount,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeColor.withValues(alpha: 0.85),
                        fontWeight:
                            hasNew ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.search, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      )
          .animate(key: ValueKey(d.discipline))
          .fadeIn(duration: 180.ms)
          .slideY(begin: 0.05, curve: Curves.easeOut),
    );
  }
}
