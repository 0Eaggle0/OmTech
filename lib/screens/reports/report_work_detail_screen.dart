import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contact_work.dart';
import '../../models/report_work.dart';
import '../../services/lk/lk_file_downloader.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/info_row.dart';
import '../../widgets/link_text.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/work_file_row.dart';

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
      final files = await lk.reportWorkApi.fetchOtherWorkFiles(
        widget.work.fileId,
        fnpp: widget.work.fnpp,
      );
      if (!mounted) return;
      setState(() {
        _files = files;
        _loadingFiles = false;
      });
    } catch (e) {
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
              _shareHtmlButton(context, lk, l),
            ],
            if (_files != null && _files!.isEmpty && !_loadingFiles) ...[
              Text(l.reportNoFiles,
                  style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted)),
              const SizedBox(height: 6),
              _shareHtmlButton(context, lk, l),
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
          ],
        ],
      ),
    );
  }

  Widget _shareHtmlButton(BuildContext context, LkController lk, AppLocalizations l) {
    if (widget.work.fileId.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.bug_report_outlined, size: 16),
        label: Text(l.reportShareHtml, style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final path = await lk.reportWorkApi.lastDumpPath(widget.work.fileId);
          if (path == null) {
            messenger.showSnackBar(const SnackBar(content: Text('Дамп не найден')));
            return;
          }
          await Share.shareXFiles([XFile(path)], subject: 'otherpage_${widget.work.fileId}.html');
        },
      ),
    );
  }
}
