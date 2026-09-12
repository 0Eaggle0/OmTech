import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_nav_controller.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/schedule_nav_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/group.dart';
import '../../models/schedule_entity.dart';
import '../../services/schedule_api.dart';
import '../../services/search_history.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/pill_filter_row.dart';
import '../../widgets/status_pill.dart';

/// Полноэкранный поиск по группам, преподавателям и аудиториям.
///
/// Открывается с главной и с расписания. Выбор результата (или недавнего
/// запроса) сразу применяет его — группа через [GroupController], препод/
/// аудитория через [ScheduleNavController] — и переключает на вкладку
/// расписания через [AppNavController], после чего экран сам закрывается.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ScheduleApi.instance;
  final _historyService = SearchHistoryService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _debounce;
  List<ScheduleEntity> _results = const [];
  List<SearchHistoryEntry> _recent = const [];
  bool _loading = false;
  bool _searched = false;
  bool _hasText = false;
  EntityType? _typeFilter;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await _historyService.readAll();
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final term = value.trim();
    setState(() => _hasText = value.isNotEmpty);
    if (term.length < 2) {
      setState(() {
        _results = const [];
        _searched = false;
        _loading = false;
        _typeFilter = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(term));
  }

  Future<void> _search(String term) async {
    try {
      final results = await _api.universalSearch(term);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searched = true;
      });
    }
  }

  void _clearQuery() {
    _controller.clear();
    _onChanged('');
    _focusNode.requestFocus();
  }

  List<ScheduleEntity> get _filtered {
    final type = _typeFilter;
    if (type == null) return _results;
    return _results.where((e) => e.type == type).toList();
  }

  int _countOf(EntityType type) =>
      _results.where((e) => e.type == type).length;

  Future<void> _select(ScheduleEntity entity) async {
    await _historyService.add(entity);
    if (!mounted) return;

    if (entity.type == EntityType.group) {
      await context.read<GroupController>().select(
            Group(id: entity.id, label: entity.label, description: entity.description),
          );
    } else {
      context.read<ScheduleNavController>().request(entity);
    }
    if (!mounted) return;
    context.read<AppNavController>().openTab(1);
    Navigator.of(context).pop();
  }

  Future<void> _removeRecent(SearchHistoryEntry entry) async {
    await _historyService.remove(entry);
    _loadRecent();
  }

  Future<void> _clearRecent() async {
    await _historyService.clearAll();
    if (!mounted) return;
    setState(() => _recent = const []);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.searchTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.searchSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.glass.textMuted,
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    onChanged: _onChanged,
                    decoration: InputDecoration(
                      hintText: l.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _hasText
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: _clearQuery,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(l)),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l) {
    if (!_searched) return _recentBody(l);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return _EmptyHint(text: l.searchNoResults, icon: Icons.search_off);
    }

    final total = _results.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: PillFilterRow(
            items: [
              PillFilterItem('${l.searchAll} $total'),
              PillFilterItem(
                  '${l.scheduleModeGroup} ${_countOf(EntityType.group)}'),
              PillFilterItem(
                  '${l.scheduleModeTeacher} ${_countOf(EntityType.teacher)}'),
              PillFilterItem(
                  '${l.scheduleModeAuditorium} ${_countOf(EntityType.auditorium)}'),
            ],
            selected: switch (_typeFilter) {
              null => 0,
              EntityType.group => 1,
              EntityType.teacher => 2,
              EntityType.auditorium => 3,
            },
            onSelected: (i) => setState(() {
              _typeFilter = switch (i) {
                1 => EntityType.group,
                2 => EntityType.teacher,
                3 => EntityType.auditorium,
                _ => null,
              };
            }),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _filtered.isEmpty
              ? _EmptyHint(text: l.searchNoResults, icon: Icons.search_off)
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                      16, 4, 16, navBottomPadding(context, extra: 8)),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ResultCard(
                    entity: _filtered[i],
                    onTap: () => _select(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _recentBody(AppLocalizations l) {
    if (_recent.isEmpty) {
      return _EmptyHint(text: l.searchStartTyping, icon: Icons.search);
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, navBottomPadding(context, extra: 8)),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.searchRecentTitle.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.glass.textMuted,
                    ),
              ),
            ),
            TextButton(
              onPressed: _clearRecent,
              child: Text(l.searchClearAll),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _recent)
              InputChip(
                avatar: Icon(_typeIcon(entry.type), size: 16),
                label: Text(entry.label),
                onPressed: () => _select(entry.toEntity()),
                onDeleted: () => _removeRecent(entry),
              ),
          ],
        ),
      ],
    );
  }

  static IconData _typeIcon(EntityType type) => switch (type) {
        EntityType.group => Icons.groups_outlined,
        EntityType.teacher => Icons.person_outline,
        EntityType.auditorium => Icons.place_outlined,
      };
}

class _EmptyHint extends StatelessWidget {
  final String text;
  final IconData icon;

  const _EmptyHint({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: glass.textFaint),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: glass.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ScheduleEntity entity;
  final VoidCallback onTap;

  const _ResultCard({required this.entity, required this.onTap});

  static (IconData, AppStatus) _visual(EntityType type) => switch (type) {
        EntityType.group => (Icons.groups_outlined, AppStatus.accent),
        EntityType.teacher => (Icons.person_outline, AppStatus.info),
        EntityType.auditorium => (Icons.place_outlined, AppStatus.success),
      };

  static String _typeLabel(AppLocalizations l, EntityType type) => switch (type) {
        EntityType.group => l.scheduleModeGroup,
        EntityType.teacher => l.scheduleModeTeacher,
        EntityType.auditorium => l.scheduleModeAuditorium,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final (icon, status) = _visual(entity.type);
    final tone = glass.statusColor(status);
    final shape = BorderRadius.circular(AppRadius.card);

    return Material(
      color: glass.cardFill,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: glass.tint(tone),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entity.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusPill(_typeLabel(l, entity.type), color: tone, dense: true),
                      ],
                    ),
                    if (entity.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entity.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: glass.textMuted),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          l.searchOpenSchedule,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 16, color: theme.colorScheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
