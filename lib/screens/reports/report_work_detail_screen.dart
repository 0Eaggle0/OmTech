import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contact_work.dart';
import '../../models/report_work.dart';
import '../../services/lk/lk_file_downloader.dart';

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
    setState(() { _loadingFiles = true; _filesError = null; });
    try {
      final files = await lk.reportWorkApi.fetchOtherWorkFiles(
        widget.work.fileId,
        fnpp: widget.work.fnpp,
      );
      if (!mounted) return;
      setState(() { _files = files; _loadingFiles = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingFiles = false; _filesError = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lk = context.watch<LkController>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.work.discipline)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.work.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              _statusBadge(context, l, widget.work.status),
            ],
          ),
          const SizedBox(height: 16),
          _infoTile(context, icon: Icons.menu_book_outlined, label: 'Предмет', value: widget.work.discipline),
          if (widget.work.semester != null)
            _infoTile(context, icon: Icons.calendar_view_month_outlined,
                label: l.reportSemesterLabel, value: '${widget.work.semester}'),
          if (widget.work.workNumber.isNotEmpty)
            _infoTile(context, icon: Icons.tag,
                label: l.reportWorkNumberLabel, value: widget.work.workNumber),
          if (widget.work.date != null)
            _infoTile(context, icon: Icons.event_outlined, label: l.workTaskDate,
                value: DateFormat('dd.MM.yyyy').format(widget.work.date!)),
          if (widget.work.teacher.isNotEmpty)
            _infoTile(context, icon: Icons.person_outline,
                label: l.reportTeacher, value: widget.work.teacher),
          if (widget.work.comment != null && widget.work.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l.reportComment,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
              ),
              child: Text(widget.work.comment!, style: theme.textTheme.bodyMedium),
            ),
          ],

          // ─── Блок скачивания ───
          if (lk.isConnected) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_file_outlined, size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(l.reportDownload,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_loadingFiles)
                  const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 10),
            if (_filesError != null) ...[
              Text(l.reportNoFiles,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
              const SizedBox(height: 6),
              _shareHtmlButton(context, lk, l),
            ],
            if (_files != null && _files!.isEmpty && !_loadingFiles) ...[
              Text(l.reportNoFiles,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
              const SizedBox(height: 6),
              _shareHtmlButton(context, lk, l),
            ],
            if (_files != null && _files!.isNotEmpty)
              ..._files!.map((f) => _fileRow(context, l, f, lk)),
          ],
        ],
      ),
    );
  }

  Widget _fileRow(BuildContext context, AppLocalizations l, WorkFile file, LkController lk) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(_fileIcon(file.type), size: 18),
              label: Text(
                file.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: () => openWorkFile(context, lk.session, file),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: l.fileSave,
            icon: const Icon(Icons.download_outlined, size: 20),
            onPressed: () => saveWorkFile(context, lk.session, file),
          ),
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

  IconData _fileIcon(String type) {
    return switch (type) {
      'pdf'  => Icons.picture_as_pdf_outlined,
      'docx' => Icons.description_outlined,
      'pptx' => Icons.slideshow_outlined,
      _      => Icons.download_outlined,
    };
  }

  Widget _infoTile(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, AppLocalizations l, ReportWorkStatus status) {
    final (color, label) = switch (status) {
      ReportWorkStatus.accepted => (const Color(0xFF2EA04A), l.reportStatusAccepted),
      ReportWorkStatus.rejected => (const Color(0xFFE05A6B), l.reportStatusRejected),
      ReportWorkStatus.pending  => (const Color(0xFFB58A14), l.reportStatusPending),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
