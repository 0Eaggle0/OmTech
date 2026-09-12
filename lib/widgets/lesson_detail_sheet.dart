import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/schedule_event.dart';
import '../services/campus_map.dart';
import '../theme/app_colors.dart';

class LessonDetailSheet extends StatelessWidget {
  final ScheduleEvent event;

  const LessonDetailSheet({super.key, required this.event});

  static Future<void> show(BuildContext context, ScheduleEvent event) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => LessonDetailSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = AppColors.forKindOfWork(event.kindOfWork);
    final e = event;
    final address = campusAddresses[e.building];

    final bottomPad = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка: время + тип
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${e.beginLesson} – ${e.endLesson}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (e.kindOfWork.isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        e.kindOfWork,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Дисциплина
            Text(
              e.discipline,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),

            // Инфо-строки
            if (e.streamDisplay.isNotEmpty)
              _infoRow(context, Icons.groups_2_outlined, '${l.lessonDetailStream}: ${e.streamDisplay}', accent),
            if (e.subgroupLabel.isNotEmpty)
              _infoRow(context, Icons.people_outline, '${l.lessonDetailSubgroup}: ${e.subgroupLabel}', accent),

            if (e.auditorium.isNotEmpty)
              _infoRow(context, Icons.door_front_door_outlined, e.auditorium, accent),

            if (e.building.isNotEmpty)
              _buildingRow(context, l, e.building, address, accent),

            if (e.lecturer.isNotEmpty)
              _teacherRow(context, l, e.lecturer, accent),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text, Color accent) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildingRow(BuildContext context, AppLocalizations l, String building, String? address, Color accent) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.apartment_outlined, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(building, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (address != null)
                  Text(address, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  )),
              ],
            ),
          ),
          IconButton(
            onPressed: () => openCampusRoute(context, building),
            icon: Icon(Icons.map_outlined, color: accent),
            tooltip: l.lessonDetailOpenMaps,
          ),
        ],
      ),
    );
  }

  Widget _teacherRow(BuildContext context, AppLocalizations l, String lecturer, Color accent) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_outline, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lecturer,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: () => _showTeacherOptions(context, l, lecturer),
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  void _showTeacherOptions(BuildContext context, AppLocalizations l, String lecturer) {
    final theme = Theme.of(context);
    final dimColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                lecturer,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: Icon(Icons.contacts_outlined, color: dimColor),
              title: Text(l.lessonDetailContacts, style: TextStyle(color: dimColor)),
              subtitle: Text('В разработке', style: TextStyle(color: dimColor, fontSize: 12)),
              enabled: false,
              onTap: null,
            ),
            ListTile(
              leading: Icon(Icons.star_outline, color: dimColor),
              title: Text(l.lessonDetailReviews, style: TextStyle(color: dimColor)),
              subtitle: Text('В разработке', style: TextStyle(color: dimColor, fontSize: 12)),
              enabled: false,
              onTap: null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
