import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/report_work.dart';

/// Полный просмотр одной отчётной работы (предмет, дата, статус,
/// преподаватель, комментарий). Скачивание файла пока не реализовано.
class ReportWorkDetailScreen extends StatelessWidget {
  final ReportWork work;

  const ReportWorkDetailScreen({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(work.discipline)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  work.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _statusBadge(context, l, work.status),
            ],
          ),
          const SizedBox(height: 16),
          _infoTile(
            context,
            icon: Icons.menu_book_outlined,
            label: l.workTaskComment.isEmpty
                ? 'Предмет'
                : 'Предмет', // не локализуем дополнительно, текст разный
            // Не используем lk-ключи, оставляем русскую подпись —
            // достаточно того, что значения уже локализованы данными.
            value: work.discipline,
          ),
          if (work.semester != null)
            _infoTile(
              context,
              icon: Icons.calendar_view_month_outlined,
              label: l.reportSemesterLabel,
              value: '${work.semester}',
            ),
          if (work.workNumber.isNotEmpty)
            _infoTile(
              context,
              icon: Icons.tag,
              label: l.reportWorkNumberLabel,
              value: work.workNumber,
            ),
          if (work.date != null)
            _infoTile(
              context,
              icon: Icons.event_outlined,
              label: l.workTaskDate,
              value: DateFormat('dd.MM.yyyy').format(work.date!),
            ),
          if (work.teacher.isNotEmpty)
            _infoTile(
              context,
              icon: Icons.person_outline,
              label: l.reportTeacher,
              value: work.teacher,
            ),
          if (work.comment != null && work.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l.reportComment,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      theme.colorScheme.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                work.comment!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
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
          Icon(icon,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
      BuildContext context, AppLocalizations l, ReportWorkStatus status) {
    final (color, label) = switch (status) {
      ReportWorkStatus.accepted => (
          const Color(0xFF2EA04A),
          l.reportStatusAccepted,
        ),
      ReportWorkStatus.rejected => (
          const Color(0xFFE05A6B),
          l.reportStatusRejected,
        ),
      ReportWorkStatus.pending => (
          const Color(0xFFB58A14),
          l.reportStatusPending,
        ),
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
