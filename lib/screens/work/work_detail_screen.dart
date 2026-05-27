import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact_work.dart';
import '../../services/link_launcher.dart';

class WorkDetailScreen extends StatelessWidget {
  final WorkDiscipline discipline;

  const WorkDetailScreen({super.key, required this.discipline});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm', locale);

    // Сортируем по дате убывания (новые сверху)
    final sorted = [...discipline.items]
      ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    return Scaffold(
      appBar: AppBar(
        title: Text(discipline.discipline, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                discipline.teachers.join(', '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: sorted.length,
        itemBuilder: (context, i) {
          final item = sorted[i];
          return _itemCard(context, l, theme, dateFmt, item, i);
        },
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
              // Номер + дата
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Комментарий
              if (item.comment.isNotEmpty)
                Text(
                  item.comment,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),

              // Преподаватель
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.teacher,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),

              // Файлы
              if (item.files.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.files.map((f) => _fileChip(context, theme, f)).toList(),
                ),
              ],
            ],
          ),
        ),
      ).animate(delay: (index * 55).ms).fadeIn(duration: 280.ms).slideY(begin: 0.05, curve: Curves.easeOut),
    );
  }

  Widget _fileChip(BuildContext context, ThemeData theme, WorkFile file) {
    final icon = _iconFor(file.type);
    final color = _colorFor(file.type, theme);
    return InkWell(
      onTap: () => openExternal(context, file.url),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                file.name,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'pdf':   return Icons.picture_as_pdf_outlined;
      case 'docx':  return Icons.description_outlined;
      case 'pptx':  return Icons.slideshow_outlined;
      case 'link':  return Icons.link_outlined;
      default:      return Icons.insert_drive_file_outlined;
    }
  }

  Color _colorFor(String type, ThemeData theme) {
    switch (type) {
      case 'pdf':   return const Color(0xFFE05A6B);
      case 'docx':  return const Color(0xFF4F9DDE);
      case 'pptx':  return const Color(0xFFE0A03A);
      case 'link':  return const Color(0xFF49C18B);
      default:      return theme.colorScheme.primary;
    }
  }
}
