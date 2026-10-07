import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../services/bug_report_service.dart';
import '../../services/screen_capture.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';

/// Шторка «Сообщить об ошибке»: описание от пользователя и файл диагностики,
/// дальше — почтовый клиент с готовым письмом разработчику.
class BugReportSheet extends StatefulWidget {
  /// Дополнительные HTML-дампы (имена для `LkReportWorkApi.lastDumpPath`).
  final List<String> extraDumps;

  /// Включить «Приложить страницы ЛК» заранее — когда шторку открыли
  /// с экрана, где сломался разбор страницы.
  final bool attachPages;

  /// Снимок экрана, с которого открыли отчёт (см. [show]).
  final String? initialScreenshot;

  const BugReportSheet({
    super.key,
    this.extraDumps = const [],
    this.attachPages = false,
    this.initialScreenshot,
  });

  /// [captureScreen] — снять текущий экран до открытия шторки и приложить.
  static Future<void> show(
    BuildContext context, {
    List<String> extraDumps = const [],
    bool attachPages = false,
    bool captureScreen = true,
  }) async {
    final shot = captureScreen ? await ScreenCapture.capture() : null;
    if (!context.mounted) return;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => BugReportSheet(
        extraDumps: extraDumps,
        attachPages: attachPages,
        initialScreenshot: shot,
      ),
    );
  }

  @override
  State<BugReportSheet> createState() => _BugReportSheetState();
}

class _BugReportSheetState extends State<BugReportSheet> {
  static const _maxScreenshots = 5;

  final _controller = TextEditingController();
  late bool _attachPages = widget.attachPages;
  late final List<String> _screenshots = [
    if (widget.initialScreenshot != null) widget.initialScreenshot!,
  ];
  bool _sending = false;

  Future<void> _pickScreenshots() async {
    try {
      // `limit: 1` image_picker не принимает (кидает ArgumentError), поэтому
      // на последнем свободном слоте просим два, а лишнее отсекаем ниже.
      final free = _maxScreenshots - _screenshots.length;
      if (free <= 0) return;
      final picked = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        limit: free < 2 ? 2 : free,
      );
      if (picked.isEmpty || !mounted) return;
      setState(() {
        for (final file in picked) {
          if (_screenshots.length >= _maxScreenshots) break;
          if (!_screenshots.contains(file.path)) _screenshots.add(file.path);
        }
      });
    } catch (e) {
      debugPrint('[BugReport] выбор скриншотов не удался: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final state = BugReportService.describeState(context);
    final reportApi = context.read<LkController>().reportWorkApi;

    setState(() => _sending = true);
    final delivery = await BugReportService.send(
      state: state,
      reportApi: reportApi,
      description: _controller.text,
      attachPages: _attachPages,
      extraDumps: widget.extraDumps,
      screenshots: List.of(_screenshots),
    );
    if (!mounted) return;
    navigator.pop();
    if (delivery == BugReportDelivery.failed) {
      await Clipboard.setData(
          const ClipboardData(text: BugReportService.recipient));
      messenger.showSnackBar(SnackBar(
        content: Text(l.bugReportFailed(BugReportService.recipient)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final danger = glass.statusColor(AppStatus.danger);
    final bottom = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: glass.tint(danger),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.bug_report_outlined, color: danger),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.bugReportTitle,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.bugReportSubtitle(BugReportService.recipient),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: glass.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            enabled: !_sending,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.bugReportHint),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            decoration: BoxDecoration(
              color: glass.elevatedFill,
              borderRadius: BorderRadius.circular(AppRadius.tile),
              border: Border.all(color: glass.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.bugReportIncluded.toUpperCase(),
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: glass.textMuted),
                ),
                const SizedBox(height: 10),
                _includedRow(context, Icons.phone_android_rounded,
                    l.bugReportIncDevice),
                _includedRow(
                    context, Icons.receipt_long_outlined, l.bugReportIncLog),
                const Divider(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _attachPages,
                  onChanged:
                      _sending ? null : (v) => setState(() => _attachPages = v),
                  title: Text(
                    l.bugReportAttachPages,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    l.bugReportAttachPagesHint,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: glass.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.bugReportScreens.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: glass.textMuted),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final path in _screenshots) _screenshotThumb(context, path),
                if (_screenshots.length < _maxScreenshots)
                  _addScreenshotTile(context, l),
              ],
            ),
          ),
          if (widget.initialScreenshot != null &&
              _screenshots.contains(widget.initialScreenshot))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.bugReportScreensHint,
                style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(l.bugReportSend),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenshotThumb(BuildContext context, String path) {
    final glass = context.glass;
    final shape = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          Container(
            width: 74,
            height: 132,
            decoration: BoxDecoration(
              borderRadius: shape,
              border: Border.all(color: glass.hairline),
            ),
            child: ClipRRect(
              borderRadius: shape,
              child: Image.file(File(path), fit: BoxFit.cover, cacheWidth: 220),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending
                    ? null
                    : () => setState(() => _screenshots.remove(path)),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addScreenshotTile(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final shape = BorderRadius.circular(12);
    return Material(
      color: glass.tint(glass.accent),
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: _sending ? null : _pickScreenshots,
        child: Container(
          width: 74,
          height: 132,
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(color: glass.accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: glass.accent),
              const SizedBox(height: 6),
              Text(
                l.bugReportAddScreen,
                style: theme.textTheme.labelSmall?.copyWith(color: glass.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _includedRow(BuildContext context, IconData icon, String text) {
    final glass = context.glass;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: glass.statusColor(AppStatus.success)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
