import 'package:flutter/material.dart';

import '../theme/app_glass.dart';

/// Мелкая капс-подпись над блоком: «ПРОГРЕСС ОБУЧЕНИЯ», «СЕРВИСЫ УНИВЕРСИТЕТА».
///
/// Отличается от `SectionHeader` (крупный заголовок с кнопкой) — тот остаётся
/// на экране новостей.
class SectionCaption extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionCaption(
    this.text, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(4, 0, 4, 10),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: glass.textMuted,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
