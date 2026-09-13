import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_work.dart';
import '../../services/app_routes.dart';
import '../../services/cache_manager.dart';
import '../../services/lk/lk_report_work_api.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/status_banners.dart';
import '../../widgets/status_pill.dart';
import '../settings/bug_report_sheet.dart';

/// Загрузка новой «прочей» отчётной работы: дисциплина → название → PDF.
///
/// Повторяет форму `otherpage.php` (fileid=0) с omgtu.ru/ecab/vkr2.php. Сайт
/// отправляет файл сразу при выборе, здесь — только по кнопке, когда всё
/// заполнено: случайно выбранный файл не улетит преподавателю.
class ReportWorkUploadScreen extends StatefulWidget {
  const ReportWorkUploadScreen({super.key});

  /// `true` — работа загружена, список пора обновить.
  static Future<bool?> open(BuildContext context) => Navigator.push<bool>(
      context, AppRoutes.fadeScale(const ReportWorkUploadScreen()));

  @override
  State<ReportWorkUploadScreen> createState() => _ReportWorkUploadScreenState();
}

class _PickedFile {
  final String path;
  final String name;
  final int size;

  const _PickedFile(this.path, this.name, this.size);
}

class _ReportWorkUploadScreenState extends State<ReportWorkUploadScreen> {
  final _titleController = TextEditingController();

  List<ReportUploadDiscipline>? _disciplines;
  bool _loadingDisciplines = true;
  bool _disciplinesFailed = false;

  ReportUploadDiscipline? _discipline;
  _PickedFile? _file;
  bool _pickingFile = false;

  /// Подсвечивать незаполненные поля — только после первой попытки отправки.
  bool _showErrors = false;
  bool _sending = false;
  bool _done = false;
  double _progress = 0;
  String? _sendError;

  LkReportWorkApi get _api => context.read<LkController>().reportWorkApi;

  bool get _titleValid => _titleController.text.trim().isNotEmpty;

  bool get _locked => _sending || _done;

  @override
  void initState() {
    super.initState();
    _loadDisciplines();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadDisciplines() async {
    setState(() {
      _loadingDisciplines = true;
      _disciplinesFailed = false;
    });
    try {
      final list = await _api.fetchUploadDisciplines();
      if (!mounted) return;
      setState(() {
        _disciplines = list;
        _loadingDisciplines = false;
      });
    } catch (e) {
      debugPrint('[Upload] список дисциплин не получен: $e');
      if (!mounted) return;
      setState(() {
        _loadingDisciplines = false;
        _disciplinesFailed = true;
      });
    }
  }

  Future<void> _chooseDiscipline(List<ReportUploadDiscipline> items) async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<ReportUploadDiscipline>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) =>
          _DisciplinePickerSheet(items: items, selected: _discipline),
    );
    if (picked != null && mounted) {
      setState(() {
        _discipline = picked;
        _sendError = null;
      });
    }
  }

  Future<void> _pickFile() async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _pickingFile = true);
    try {
      final path = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(
          fileExtensionsFilter: ['pdf'],
          mimeTypesFilter: ['application/pdf'],
          copyFileToCacheDir: true,
        ),
      );
      if (path == null) return;
      final file = File(path);
      if (!await _looksLikePdf(file)) {
        messenger.showSnackBar(SnackBar(content: Text(l.reportUploadOnlyPdf)));
        return;
      }
      final size = await file.length();
      if (size > LkReportWorkApi.maxUploadBytes) {
        messenger.showSnackBar(SnackBar(content: Text(l.reportUploadTooLarge)));
        return;
      }
      var name = p.basename(path);
      if (!name.toLowerCase().endsWith('.pdf')) name = '$name.pdf';
      if (!mounted) return;
      setState(() {
        _file = _PickedFile(path, name, size);
        _sendError = null;
      });
    } catch (e) {
      debugPrint('[Upload] выбор файла не удался: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.reportUploadPickFailed)));
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  /// Проверяем сигнатуру, а не расширение: копия файла из системного
  /// диалога может прийти без `.pdf` в имени.
  static Future<bool> _looksLikePdf(File file) async {
    final raf = await file.open();
    try {
      return String.fromCharCodes(await raf.read(5)).startsWith('%PDF');
    } finally {
      await raf.close();
    }
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final discipline = _discipline;
    final file = _file;
    if (discipline == null || file == null || !_titleValid) {
      setState(() => _showErrors = true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _progress = 0;
      _sendError = null;
    });
    try {
      await _api.uploadOtherWork(
        discipline: discipline,
        title: _titleController.text.trim(),
        filePath: file.path,
        fileName: file.name,
        onProgress: (sent, total) {
          if (total <= 0 || !mounted) return;
          setState(() => _progress = sent / total);
        },
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _done = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) navigator.pop(true);
    } on ReportSiteException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendError = e.serverMessage ?? l.reportUploadFailed;
      });
    } catch (e) {
      debugPrint('[Upload] отправка не удалась: $e');
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendError = l.reportUploadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;

    return Scaffold(
      appBar: AppBar(title: Text(l.reportUploadTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          _hero(context, l),
          const SizedBox(height: 16),
          if (_sendError != null) ...[
            ErrorBanner(
              _sendError!,
              title: l.reportUploadServerError,
              onDismiss: () => setState(() => _sendError = null),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _reportProblemButton(l),
            ),
            const SizedBox(height: 8),
          ],
          _StepCard(
            index: 1,
            title: l.reportUploadDiscipline,
            done: _discipline != null,
            child: _disciplineStep(context, l),
          ),
          const SizedBox(height: 12),
          _StepCard(
            index: 2,
            title: l.reportUploadWorkTitle,
            done: _titleValid,
            child: _titleStep(l),
          ),
          const SizedBox(height: 12),
          _StepCard(
            index: 3,
            title: l.reportUploadFile,
            done: _file != null,
            child: _fileStep(context, l),
          ),
          const SizedBox(height: 20),
          _sendButton(context, l),
          const SizedBox(height: 12),
          Text(
            l.reportUploadNote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final glass = context.glass;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: glass.accentGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: glass.glow(glass.accent),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.reportOtherWorks,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.reportUploadHeroSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(
        begin: 0.05, curve: Curves.easeOutCubic);
  }

  Widget _disciplineStep(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final glass = context.glass;

    if (_loadingDisciplines) {
      return Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.reportUploadDisciplinesLoading,
              style: theme.textTheme.bodyMedium?.copyWith(color: glass.textMuted),
            ),
          ),
        ],
      );
    }

    final items = _disciplines ?? const <ReportUploadDiscipline>[];
    if (_disciplinesFailed || items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _disciplinesFailed
                ? l.reportUploadDisciplinesError
                : l.reportUploadNoDisciplines,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: _loadDisciplines,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(l.retry),
              ),
              _reportProblemButton(l),
            ],
          ),
        ],
      );
    }

    final selected = _discipline;
    final showError = _showErrors && selected == null;
    return _FieldTile(
      leading: Icons.menu_book_outlined,
      error: showError,
      onTap: _locked ? null : () => _chooseDiscipline(items),
      trailing: Icon(Icons.unfold_more_rounded, color: glass.textFaint),
      child: selected == null
          ? Text(
              l.reportUploadDisciplineHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: showError ? theme.colorScheme.error : glass.textFaint,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                _disciplinePills(l, selected),
              ],
            ),
    );
  }

  Widget _titleStep(AppLocalizations l) {
    return TextField(
      controller: _titleController,
      enabled: !_locked,
      maxLength: 250,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: l.reportUploadWorkTitleHint,
        prefixIcon: const Icon(Icons.edit_note_rounded),
        errorText:
            _showErrors && !_titleValid ? l.reportUploadTitleRequired : null,
      ),
    );
  }

  Widget _fileStep(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final file = _file;

    if (file == null) {
      final showError = _showErrors;
      final tone = showError ? theme.colorScheme.error : glass.accent;
      final shape = BorderRadius.circular(AppRadius.tile);
      return Material(
        color: glass.tint(tone),
        borderRadius: shape,
        child: InkWell(
          borderRadius: shape,
          onTap: _pickingFile || _locked ? null : _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: shape,
              border: Border.all(color: tone.withValues(alpha: 0.45), width: 1.4),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: _pickingFile
                      ? const Padding(
                          padding: EdgeInsets.all(15),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.upload_file_rounded, color: tone, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  l.reportUploadPickFile,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: tone, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  showError ? l.reportUploadFileRequired : l.reportUploadFileHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: showError ? theme.colorScheme.error : glass.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _FieldTile(
      leading: Icons.picture_as_pdf_outlined,
      tone: glass.statusColor(AppStatus.danger),
      onTap: _locked ? null : _pickFile,
      trailing: IconButton(
        tooltip: l.reportUploadRemoveFile,
        icon: Icon(Icons.close_rounded, color: glass.textFaint),
        onPressed: _locked ? null : () => setState(() => _file = null),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            file.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            CacheManager.formatBytes(file.size),
            style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _sendButton(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final success = glass.statusColor(AppStatus.success);
    final percent = (_progress * 100).clamp(0, 100).round();

    final Widget label;
    if (_done) {
      label = Row(
        key: const ValueKey('done'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 20),
          const SizedBox(width: 8),
          Text(l.reportUploadDone),
        ],
      );
    } else if (_sending) {
      label = Row(
        key: const ValueKey('sending'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Text(percent >= 100
              ? l.reportUploadProcessing
              : l.reportUploadSending(percent)),
        ],
      );
    } else {
      label = Row(
        key: const ValueKey('idle'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_upload_rounded, size: 20),
          const SizedBox(width: 8),
          Text(l.reportUploadSend),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _locked ? null : _send,
            style: FilledButton.styleFrom(
              backgroundColor: _done ? success : null,
              disabledBackgroundColor:
                  _done ? success : theme.colorScheme.primary,
              disabledForegroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              textStyle: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: label,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _sending
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: percent >= 100 ? null : _progress,
                      minHeight: 6,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _reportProblemButton(AppLocalizations l) {
    return TextButton.icon(
      onPressed: () => BugReportSheet.show(context, attachPages: true),
      icon: const Icon(Icons.bug_report_outlined, size: 16),
      label: Text(l.bugReportAction),
    );
  }
}

Widget _disciplinePills(AppLocalizations l, ReportUploadDiscipline d) {
  return Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      if (d.group.isNotEmpty)
        StatusPill(d.group, status: AppStatus.accent, dense: true),
      if (d.semester.isNotEmpty)
        StatusPill('${d.semester} ${l.reportSemesterLabel}', dense: true),
    ],
  );
}

/// Шаг формы: номер (или галочка, когда шаг заполнен), заголовок, содержимое.
class _StepCard extends StatelessWidget {
  final int index;
  final String title;
  final bool done;
  final Widget child;

  const _StepCard({
    required this.index,
    required this.title,
    required this.done,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final tone = done ? glass.statusColor(AppStatus.success) : glass.accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: glass.cardFill,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: glass.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: glass.tint(tone), shape: BoxShape.circle),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: done
                      ? Icon(Icons.check_rounded,
                          key: const ValueKey('done'), size: 16, color: tone)
                      : Text(
                          '$index',
                          key: const ValueKey('index'),
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: tone, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style:
                    theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    )
        .animate(delay: (70 * index).ms)
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }
}

/// Поле-плитка: тонированная иконка слева, содержимое, действие справа.
class _FieldTile extends StatelessWidget {
  final IconData leading;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tone;
  final bool error;

  const _FieldTile({
    required this.leading,
    required this.child,
    this.trailing,
    this.onTap,
    this.tone,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final errorColor = theme.colorScheme.error;
    final iconTone = error ? errorColor : (tone ?? glass.accent);
    final shape = BorderRadius.circular(AppRadius.tile);

    return Material(
      color: glass.elevatedFill,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(
              color: error ? errorColor.withValues(alpha: 0.6) : glass.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: glass.tint(iconTone),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(leading, size: 17, color: iconTone),
              ),
              const SizedBox(width: 12),
              Expanded(child: child),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Выбор дисциплины: поиск и список, свежие семестры сверху.
class _DisciplinePickerSheet extends StatefulWidget {
  final List<ReportUploadDiscipline> items;
  final ReportUploadDiscipline? selected;

  const _DisciplinePickerSheet({required this.items, this.selected});

  @override
  State<_DisciplinePickerSheet> createState() => _DisciplinePickerSheetState();
}

class _DisciplinePickerSheetState extends State<_DisciplinePickerSheet> {
  String _query = '';

  late final List<ReportUploadDiscipline> _sorted = () {
    final indexed = widget.items.indexed.toList()
      ..sort((a, b) {
        final bySemester = b.$2.semesterNumber.compareTo(a.$2.semesterNumber);
        return bySemester != 0 ? bySemester : a.$1.compareTo(b.$1);
      });
    return [for (final (_, d) in indexed) d];
  }();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _sorted
        : _sorted
            .where((d) =>
                d.name.toLowerCase().contains(q) ||
                d.group.toLowerCase().contains(q))
            .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.reportUploadDiscipline,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                StatusPill('${filtered.length}', status: AppStatus.accent),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l.reportUploadSearch,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      l.searchNoResults,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: glass.textMuted),
                    ),
                  )
                : ListView.separated(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(
                        12, 4, 12, 16 + MediaQuery.viewInsetsOf(context).bottom),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) =>
                        _row(context, l, filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppLocalizations l, ReportUploadDiscipline d) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final isSelected = d.hexnrec == widget.selected?.hexnrec;
    final shape = BorderRadius.circular(AppRadius.tile);

    return Material(
      color: isSelected ? glass.tint(glass.accent) : glass.elevatedFill,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: () => Navigator.pop(context, d),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _disciplinePills(l, d),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: isSelected ? glass.accent : glass.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
