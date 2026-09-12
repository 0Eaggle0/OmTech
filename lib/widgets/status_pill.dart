import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

/// Маленькая пилюля: статус работы, тип занятия, счётчик, категория.
///
/// Заменяет тонированные `Container`, которые до этого писались заново
/// на каждом экране.
class StatusPill extends StatelessWidget {
  final String label;
  final AppStatus status;

  /// Явный цвет вместо статусного (например, цвет типа занятия).
  final Color? color;

  final IconData? icon;

  /// `true` — тонированная заливка, `false` — только контур.
  final bool filled;

  final bool dense;

  const StatusPill(
    this.label, {
    super.key,
    this.status = AppStatus.neutral,
    this.color,
    this.icon,
    this.filled = true,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final tone = color ?? glass.statusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: filled ? glass.tint(tone) : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: filled
            ? null
            : Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 13, color: tone),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 10 : 10.5,
              fontWeight: FontWeight.w700,
              color: tone,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
