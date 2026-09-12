import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/schedule_event.dart';
import '../services/campus_map.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';
import 'accent_bar.dart';
import 'status_pill.dart';

class LessonCard extends StatelessWidget {
  final ScheduleEvent event;
  final VoidCallback? onTap;

  const LessonCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final accent = AppColors.forKindOfWork(event.kindOfWork);
    final shape = BorderRadius.circular(AppRadius.card);
    final showRoute = hasCampusAddress(event.building);

    return Material(
      color: glass.cardFill,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        // Stack, а не IntrinsicHeight+Row: полоска через Positioned, поэтому
        // у содержимого нормально ограниченная ширина и Expanded работает.
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0, child: AccentBar(accent)),
            Padding(
              padding: EdgeInsets.fromLTRB(19, 12, onTap != null ? 38 : 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusPill(
                        '${event.beginLesson} – ${event.endLesson}',
                        color: accent,
                        icon: Icons.schedule,
                      ),
                      if (event.kindOfWork.isNotEmpty)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 150),
                              margin: const EdgeInsets.only(left: 6),
                              child: StatusPill(
                                event.kindOfWork,
                                color: accent,
                                dense: true,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(event.discipline, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (event.location.isNotEmpty)
                    _row(context, Icons.place_outlined, event.location),
                  if (event.lecturer.isNotEmpty)
                    _row(context, Icons.person_outline, event.lecturer),
                  if (event.streamDisplay.isNotEmpty)
                    _row(context, Icons.groups_2_outlined, event.streamDisplay),
                  if (event.subgroupLabel.isNotEmpty || showRoute) ...[
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        if (event.subgroupLabel.isNotEmpty)
                          StatusPill(
                            event.subgroupLabel,
                            color: accent,
                            icon: Icons.people,
                            dense: true,
                          ),
                        const Spacer(),
                        if (showRoute)
                          GestureDetector(
                            onTap: () => openCampusRoute(context, event.building),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined,
                                    size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  l.scheduleRoute,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.chevron_right,
                      size: 18, color: glass.textFaint),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final muted = context.glass.textMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
