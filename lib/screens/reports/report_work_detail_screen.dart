import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contact_work.dart';
import '../../models/report_work.dart';
import '../../services/lk/lk_file_downloader.dart';
import '../../services/lk/lk_report_work_api.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/info_row.dart';
import '../../widgets/link_text.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/work_file_row.dart';
import '../settings/bug_report_sheet.dart';

class ReportWorkDetailScreen extends StatefulWidget {
  final ReportWork work;

  const ReportWorkDetailScreen({super.key, required this.work});

  @override
  State<ReportWorkDetailScreen> createState() => _ReportWorkDetailScreenState();
}

class _ReportWorkDetailScreenState extends State<ReportWorkDetailScreen> {
  List<WorkFile>? _files;
  bool _loadingFiles = false;
  String? _filesError;

  /// Появляется, только если на странице работы есть кнопка удаления.
  String? _deleteId;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    if (widget.work.fileId.isEmpty) return;
    final lk = context.read<LkController>();
    if (!lk.isConnected) return;
    setState(() {
      _loadingFiles = true;
      _filesError = null;
    });
    try {
      final page = await lk.reportWorkApi.fetchOtherWorkPage(
        widget.work.fileId,
        fnpp: widget.work.fnpp,
      );
      if (!mounted) return;
      setState(() {
        _files = page.files;
        _deleteId = page.deleteId;
        _loadingFiles = false;
      });
    } catch (e) {
      debugPrint('[Reports] файлы работы ${widget.work.fileId}: $e');
      if (!mounted) return;
      setState(() {
        _loadingFiles = false;
        _filesError = e.toString();
      });
    }
  }

  static (AppStatus, String) _statusVisual(AppLocalizations l, ReportWorkStatus status) =>
      switch (status) {
        ReportWorkStatus.accepted => (AppStatus.success, l.reportStatusAccepted),
        ReportWorkStatus.pending => (AppStatus.warning, l.reportStatusPending),
        ReportWorkStatus.rejected => (AppStatus.danger, l.reportStatusRejected),
      };

  void _copyRegistrationNumber(BuildContext context, AppLocalizations l) {
    Clipboard.setData(ClipboardData(text: widget.work.workNumber));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.reportCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final lk = context.watch<LkController>();
    final (status, statusLabel) = _statusVisual(l, widget.work.status);

    return Scaffold(
      appBar: AppBar(title: Text(widget.work.discipline)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(widget.work.title, style: theme.textTheme.headlineSmall),
                  ),
                  const SizedBox(width: 12),
                  StatusPill(statusLabel, status: status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.menu_book_outlined,
                    label: l.reportSubjectFilter,
                    value: widget.work.discipline,
                  ),
                  if (widget.work.semester != null)
                    InfoRow(
                      icon: Icons.calendar_view_month_outlined,
                      label: l.reportSemesterLabel,
                      value: '${widget.work.semester}',
                    ),
                  if (widget.work.workNumber.isNotEmpty)
                    InfoRow(
                      icon: Icons.tag,
                      label: l.reportRegistrationNumber,
                      value: widget.work.workNumber,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        onPressed: () => _copyRegistrationNumber(context, l),
                      ),
                    ),
                  if (widget.work.date != null)
                    InfoRow(
                      icon: Icons.event_outlined,
                      label: l.workTaskDate,
                      value: DateFormat('dd.MM.yyyy').format(widget.work.date!),
                    ),
                  if (widget.work.teacher.isNotEmpty)
                    InfoRow(
                      icon: Icons.person_outline,
                      label: l.reportTeacher,
                      value: widget.work.teacher,
                    ),
                ],
              ),
            ),
          ),
          if (widget.work.comment != null && widget.work.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.reportComment, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: glass.elevatedFill,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: glass.hairline),
              ),
              child: LinkText(text: widget.work.comment!, style: theme.textTheme.bodyMedium),
            ),
          ],
          if (lk.isConnected) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.attach_file_outlined, size: 18, color: glass.textMuted),
                const SizedBox(width: 8),
                Text(l.reportDownload, style: theme.textTheme.titleSmall),
                const Spacer(),
                if (_loadingFiles)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_filesError != null) ...[
              Text(l.reportNoFiles,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              const SizedBox(height: 6),
              _reportProblemButton(context, l),
            ],
            if (_files != null && _files!.isEmpty && !_loadingFiles) ...[
              Text(l.reportNoFiles,
                  style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted)),
              const SizedBox(height: 6),
              _reportProblemButton(context, l),
            ],
            if (_files != null && _files!.isNotEmpty)
              for (final f in _files!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WorkFileRow(
                    file: f,
                    onOpen: () => openWorkFile(context, lk.session, f),
                    onSave: () => saveWorkFile(context, lk.session, f),
                  ),
                ),
            if (_deleteId != null) ...[
              const SizedBox(height: 24),
              _deleteButton(l),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AppLocalizations l) async {
    final deleteId = _deleteId;
    if (deleteId == null) return;
    final error = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: error),
        title: Text(l.reportDeleteTitle),
        content: Text(l.reportDeleteBody(widget.work.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.reportDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final api = context.read<LkController>().reportWorkApi;
    setState(() => _deleting = true);
    try {
      await api.deleteOtherWork(deleteId);
      // `true` — список отчётных работ обновится и покажет «Работа удалена».
      if (mounted) navigator.pop(true);
    } on ReportSiteException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      messenger.showSnackBar(
          SnackBar(content: Text(e.serverMessage ?? l.reportDeleteFailed)));
    } catch (e) {
      debugPrint('[Reports] удаление ${widget.work.fileId}: $e');
      if (!mounted) return;
      setState(() => _deleting = false);
      messenger.showSnackBar(SnackBar(content: Text(l.reportDeleteFailed)));
    }
  }

  Widget _deleteButton(AppLocalizations l) {
    final error = Theme.of(context).colorScheme.error;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _deleting ? null : () => _confirmDelete(l),
        icon: _deleting
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: error),
              )
            : const Icon(Icons.delete_outline_rounded, size: 20),
        label: Text(l.reportDelete),
        style: OutlinedButton.styleFrom(
          foregroundColor: error,
          side: BorderSide(color: error.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
        ),
      ),
    );
  }

  /// Файл не нашёлся — скорее всего, сменилась вёрстка страницы. Отчёт сразу
  /// прикладывает её HTML: по нему разбор и чинится.
  Widget _reportProblemButton(BuildContext context, AppLocalizations l) {
    if (widget.work.fileId.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.bug_report_outlined, size: 16),
        label: Text(l.bugReportAction, style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
        onPressed: () => BugReportSheet.show(
          context,
          extraDumps: [widget.work.fileId],
          attachPages: true,
        ),
      ),
    );
  }
}
