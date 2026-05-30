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
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm', locale);

    final sorted = [..._items]
      ..sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    final body = _loading && _items.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => _isRealDiscipline
                ? _load(forceRefresh: true)
                : Future<void>.value(),
            child: _buildContent(context, l, theme, dateFmt, sorted),
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
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
    DateFormat dateFmt,
    List<ContactWorkItem> sorted,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_fromCache)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _cacheBanner(context, l, theme),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _errorBanner(context, theme),
          ),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Center(
              child: Text(
                l.workTaskNoFiles,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          ...sorted.asMap().entries.map(
              (e) => _itemCard(context, l, theme, dateFmt, e.value, e.key)),
      ],
    );
  }

  Widget _cacheBanner(BuildContext context, AppLocalizations l, ThemeData theme) {
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

  Widget _errorBanner(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!)),
        ],
      ),
    );
  }

  Widget _itemCard(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '№ ${item.number}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (item.createdAt != null)
                    Text(
                      dateFmt.format(item.createdAt!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (item.comment.isNotEmpty)
                Text(
                  item.comment,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              if (item.teacher.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.teacher,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (item.files.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(
                    height: 1,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                const SizedBox(height: 8),
                ...item.files.map((f) => _fileRow(context, l, theme, f)),
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

  Widget _fileRow(BuildContext context, AppLocalizations l, ThemeData theme, WorkFile file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(_iconFor(file.type), size: 18),
              label: Text(file.name, overflow: TextOverflow.ellipsis, maxLines: 1),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: () => _openFile(context, file),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: l.fileSave,
            icon: const Icon(Icons.download_outlined, size: 20),
            onPressed: () => _saveFile(context, file),
          ),
        ],
      ),
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

  IconData _iconFor(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'docx':
      case 'doc':
        return Icons.description_outlined;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow_outlined;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart_outlined;
      case 'link':
        return Icons.link_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

}
