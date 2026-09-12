import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/contact_work.dart';
import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

/// Вложенный файл: открыть во внешнем приложении или сохранить на устройство.
///
/// Один виджет на контактные и на отчётные работы — раньше это была пара
/// почти одинаковых приватных методов с двумя разными наборами иконок.
class WorkFileRow extends StatelessWidget {
  final WorkFile file;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  const WorkFileRow({
    super.key,
    required this.file,
    required this.onOpen,
    required this.onSave,
  });

  static IconData iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (t.contains('doc')) return Icons.description_outlined;
    if (t.contains('ppt')) return Icons.slideshow_outlined;
    if (t.contains('xls')) return Icons.table_chart_outlined;
    if (t.contains('zip') || t.contains('rar')) return Icons.folder_zip_outlined;
    if (t.contains('link')) return Icons.link;
    return Icons.insert_drive_file_outlined;
  }

  static Color _colorFor(BuildContext context, String type) {
    final t = type.toLowerCase();
    final glass = context.glass;
    if (t.contains('pdf')) return glass.statusColor(AppStatus.danger);
    if (t.contains('doc')) return glass.statusColor(AppStatus.info);
    if (t.contains('xls')) return glass.statusColor(AppStatus.success);
    if (t.contains('ppt')) return glass.statusColor(AppStatus.warning);
    return glass.accent;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final tone = _colorFor(context, file.type);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: glass.elevatedFill,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: glass.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: glass.tint(tone),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(iconFor(file.type), size: 17, color: tone),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l.fileOpen),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: Text(l.fileSave),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: glass.hairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.tile),
                    ),
                    textStyle: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
