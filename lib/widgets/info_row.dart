import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

/// Строка «иконка — подпись — значение»: параметры работы, детали пары,
/// пункты профиля.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  /// Произвольное значение вместо текста (пилюля, ссылка).
  final Widget? valueWidget;

  final Widget? trailing;
  final VoidCallback? onTap;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: glass.elevatedFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: glass.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
                ),
                const SizedBox(height: 2),
                if (valueWidget != null)
                  valueWidget!
                else
                  Text(
                    value ?? '—',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: content,
      ),
    );
  }
}
