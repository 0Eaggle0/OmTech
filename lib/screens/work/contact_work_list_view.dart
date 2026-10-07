import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contact_work.dart';
import '../../services/contact_work_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/accent_bar.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/status_banners.dart';
import '../../widgets/status_pill.dart';
import 'work_detail_screen.dart';

/// Список дисциплин контактной работы. Без своего `Scaffold` — живёт внутри
/// `WorkHubScreen`, который владеет шапкой и переключателем разделов.
class ContactWorkListView extends StatefulWidget {
  const ContactWorkListView({super.key});

  @override
  State<ContactWorkListView> createState() => _ContactWorkListViewState();
}

class _ContactWorkListViewState extends State<ContactWorkListView> {
  ContactWorkResult? _result;
  bool _loading = true;
  String? _error;
  DateTime? _syncedAt;

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
          if (!r.fromCache) _syncedAt = DateTime.now();
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
    if (_loading && _result == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: _content(context, l),
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
      padding: EdgeInsets.fromLTRB(16, 8, 16, navBottomPadding(context)),
      children: [
        TextField(
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
        const SizedBox(height: 10),
        if (result.isDemo)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DemoBanner(text: l.workDemoNote),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ErrorBanner(_error!, onRetry: () => _load(forceRefresh: true)),
          ),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text(l.newsEmpty)),
          )
        else
          ...filtered.map((d) => _disciplineCard(context, l, d)),
        const SizedBox(height: 6),
        if (result.fromCache)
          const CacheBanner()
        else if (_syncedAt != null)
          _syncedNotice(context, l, _syncedAt!),
      ],
    );
  }

  Widget _syncedNotice(BuildContext context, AppLocalizations l, DateTime at) {
    final glass = context.glass;
    return Row(
      children: [
        Icon(Icons.cloud_done_outlined, size: 14, color: glass.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l.workSyncedAt(DateFormat('HH:mm').format(at)),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: glass.textMuted),
          ),
        ),
      ],
    );
  }

  /// Цвет акцентной полосы — устойчивый для дисциплины, чтобы список
  /// читался как набор разных предметов, а не однородная простыня.
  static Color _accentFor(String discipline) {
    const palette = [
      AppColors.violet,
      AppColors.statusInfo,
      AppColors.statusSuccess,
      AppColors.statusWarning,
      AppColors.statusDanger,
      AppColors.indigo,
    ];
    return palette[discipline.hashCode.abs() % palette.length];
  }

  Widget _disciplineCard(
      BuildContext context, AppLocalizations l, WorkDiscipline d) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final accent = _accentFor(d.discipline);
    final newCount = d.id == null ? 0 : (_newCounts[d.id] ?? 0);
    final shape = BorderRadius.circular(AppRadius.card);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: glass.cardFill,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: shape,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WorkDetailScreen(discipline: d)),
            );
            if (mounted) unawaited(_recalcBadges());
          },
          child: Stack(
            children: [
              Positioned(left: 0, top: 0, bottom: 0, child: AccentBar(accent)),
              Padding(
                padding: const EdgeInsets.fromLTRB(19, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusPill(
                                l.workMaterialsCount(d.taskCount),
                                color: accent,
                                icon: Icons.folder_outlined,
                                dense: true,
                              ),
                              if (newCount > 0) ...[
                                const SizedBox(width: 6),
                                StatusPill(
                                  l.workNewCount(newCount),
                                  status: AppStatus.danger,
                                  dense: true,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(d.discipline, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 13, color: glass.textMuted),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  d.teachers.isEmpty
                                      ? '—'
                                      : d.teachers.join(', '),
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: glass.textMuted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Одна и та же стрелка у всех строк: раньше здесь были
                    // разные иконки, и это читалось как разное поведение.
                    Icon(Icons.chevron_right, color: glass.textFaint),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate(key: ValueKey(d.discipline))
          .fadeIn(duration: 180.ms)
          .slideY(begin: 0.05, curve: Curves.easeOut),
    );
  }
}
