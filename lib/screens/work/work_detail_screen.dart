import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contact_work.dart';
import '../../services/contact_work_service.dart';
import '../../services/link_launcher.dart';
import '../../services/lk/lk_file_downloader.dart';
import '../../services/teacher_contacts_service.dart';
import '../../theme/app_glass.dart';
import '../../widgets/link_text.dart';
import '../../widgets/status_banners.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/teacher_contacts_card.dart';
import '../../widgets/work_file_row.dart';

class WorkDetailScreen extends StatefulWidget {
  final WorkDiscipline discipline;

  const WorkDetailScreen({super.key, required this.discipline});

  @override
  State<WorkDetailScreen> createState() => _WorkDetailScreenState();
}

class _WorkDetailScreenState extends State<WorkDetailScreen> {
  List<ContactWorkItem> _items = const [];
  bool _loading = false;
  bool _fromCache = false;
  String? _error;
  bool _errorDismissed = false;
  DateTime? _cachedAt;

  bool get _isRealDiscipline => widget.discipline.id != null;

  @override
  void initState() {
    super.initState();
    if (_isRealDiscipline) {
      _load();
    } else {
      _items = widget.discipline.items;
    }
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final lk = context.read<LkController>();
    final service = ContactWorkService(lk: lk);
    setState(() {
      if (_items.isEmpty) _loading = true;
      _error = null;
      _errorDismissed = false;
    });
    var sawAny = false;
    try {
      await for (final list in service.watchTasks(widget.discipline.id!,
          forceRefresh: forceRefresh)) {
        if (!mounted) return;
        setState(() {
          _items = list;
          _loading = false;
          _fromCache = !sawAny; // первая эмиссия — кэш, вторая — свежие
          if (_fromCache) _cachedAt = DateTime.now();
          sawAny = true;
        });
      }
      if (mounted && sawAny) {
        setState(() => _fromCache = false);
      }
      // Фиксируем baseline для бейджа «новых заданий»:
      // считаем дисциплину «увиденной» с её текущим числом заданий.
      if (sawAny && lk.isConnected) {
        await lk.contactWorkApi
            .setKnownTaskCount(widget.discipline.id!, _items.length);
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
    final theme = Theme.of(context);
    final glass = context.glass;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('d MMMM, HH:mm', locale);

    final sorted = [..._items]
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    final body = _loading && _items.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => _isRealDiscipline
                ? _load(forceRefresh: true)
                : Future<void>.value(),
            child: _buildContent(context, l, theme, glass, dateFmt, sorted),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.discipline.discipline,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: widget.discipline.teachers.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.discipline.teachers.join(', '),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: glass.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
      ),
      body: body,
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
    AppGlass glass,
    DateFormat dateFmt,
    List<ContactWorkItem> sorted,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        if (_error != null && !_errorDismissed) ...[
          ErrorBanner(
            _error!,
            title: l.workServerUnavailable,
            onRetry: () => _load(forceRefresh: true),
            onDismiss: () => setState(() => _errorDismissed = true),
          ),
          const SizedBox(height: 10),
        ],
        if (_fromCache) ...[
          CacheBanner(updatedAt: _cachedAt),
          const SizedBox(height: 6),
        ],
        ..._lecturerContacts(),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Center(
              child: Text(
                l.workTaskNoFiles,
                style: theme.textTheme.bodyMedium?.copyWith(color: glass.textMuted),
              ),
            ),
          )
        else
          ...sorted.asMap().entries.map(
                (e) => _itemCard(context, l, theme, glass, dateFmt, e.value, e.key),
              ),
      ],
    );
  }

  /// Контакты преподаватели обычно пишут в первом задании дисциплины —
  /// показываем найденное там. Ничего не нашли — блока нет.
  List<Widget> _lecturerContacts() {
    final discipline = widget.discipline;
    // Задания без автора `scanTasksForContacts` отдаёт любому преподавателю
    // дисциплины. Если у дисциплины их двое, один и тот же набор контактов
    // иначе выводится дважды под разными именами — второй раз пропускаем.
    final shown = <String>{};
    final cards = <Widget>[];
    for (final teacher in discipline.teachers) {
      final items = scanTasksForContacts(_items, teacher);
      if (items.isEmpty) continue;
      if (!shown.add(items.map((c) => c.uri).join('|'))) continue;
      cards.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TeacherContactsCard(
          contacts: TeacherContacts(
            items: items,
            discipline: discipline.discipline,
          ),
          name: teacher,
          showSource: false,
        ),
      ));
    }
    return cards;
  }

  Widget _itemCard(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
    AppGlass glass,
    DateFormat dateFmt,
    ContactWorkItem item,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusPill(
                    '№ ${item.number}',
                    status: AppStatus.accent,
                    dense: true,
                  ),
                  const Spacer(),
                  if (item.createdAt != null)
                    Text(
                      dateFmt.format(item.createdAt!),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: glass.textFaint),
                    ),
                ],
              ),
              if (item.comment.isNotEmpty) ...[
                const SizedBox(height: 10),
                LinkText(
                  text: item.comment,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (item.teacher.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: glass.textMuted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.teacher,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: glass.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
              if (item.files.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final f in item.files)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: WorkFileRow(
                      file: f,
                      onOpen: () => _openFile(context, f),
                      onSave: () => _saveFile(context, f),
                    ),
                  ),
              ],
            ],
          ),
        ),
      )
          .animate(delay: (index * 55).ms)
          .fadeIn(duration: 280.ms)
          .slideY(begin: 0.05, curve: Curves.easeOut),
    );
  }

  Future<void> _openFile(BuildContext context, WorkFile file) async {
    final lk = context.read<LkController>();
    // Авторизованные ссылки на up.omgtu.ru качаем через сессию;
    // внешние ссылки (или демо) — отдаём браузеру.
    if (lk.isConnected && file.url.contains('up.omgtu.ru')) {
      await openWorkFile(context, lk.session, file);
    } else {
      await openExternal(context, file.url);
    }
  }

  Future<void> _saveFile(BuildContext context, WorkFile file) async {
    final lk = context.read<LkController>();
    if (lk.isConnected && file.url.contains('up.omgtu.ru')) {
      await saveWorkFile(context, lk.session, file);
    } else {
      await openExternal(context, file.url);
    }
  }
}
