import 'package:flutter/material.dart';

import '../models/schedule_event.dart';
import '../theme/app_colors.dart';

class LessonCard extends StatelessWidget {
  final ScheduleEvent event;
  final VoidCallback? onTap;

  const LessonCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppColors.forKindOfWork(event.kindOfWork);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.12 : 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          // Stack вместо IntrinsicHeight+Row: цветная полоска через Positioned,
          // содержимое имеет нормально ограниченную ширину → Expanded работает.
          child: Stack(
            children: [
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, accent.withValues(alpha: 0.6)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  19, 12,
                  onTap != null ? 38 : 14,
                  14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${event.beginLesson} – ${event.endLesson}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                        if (event.kindOfWork.isNotEmpty)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 160),
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  event.kindOfWork,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.discipline,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (event.location.isNotEmpty)
                      _row(context, Icons.place_outlined, event.location, accent),
                    if (event.lecturer.isNotEmpty)
                      _row(context, Icons.person_outline, event.lecturer, accent),
                    if (event.stream.isNotEmpty)
                      _row(context, Icons.groups_2_outlined, event.stream, accent),
                    if (event.subgroupLabel.isNotEmpty)
                      _row(context, Icons.people_outline, event.subgroupLabel, accent),
                  ],
                ),
              ),
              if (onTap != null)
                Positioned(
                  right: 10, top: 0, bottom: 0,
                  child: Center(
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text, Color accent) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: muted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
