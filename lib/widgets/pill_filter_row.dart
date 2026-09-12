import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

class PillFilterItem {
  final String label;

  /// Цветная точка слева (статус работы, тип занятия).
  final Color? dot;

  const PillFilterItem(this.label, {this.dot});
}

/// Ряд фильтр-пилюль с одним выбранным элементом.
class PillFilterRow extends StatelessWidget {
  final List<PillFilterItem> items;
  final int selected;
  final ValueChanged<int> onSelected;

  /// Горизонтальная прокрутка, если пилюли не влезают в ширину.
  final bool scrollable;

  final EdgeInsetsGeometry padding;

  const PillFilterRow({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final pills = [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        _Pill(
          item: items[i],
          selected: i == selected,
          onTap: () => onSelected(i),
        ),
      ],
    ];

    if (!scrollable) {
      return Padding(padding: padding, child: Row(children: pills));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(children: pills),
    );
  }
}

/// Одна пилюля-переключатель (вкл/выкл), с той же гарантированной
/// контрастностью, что и у `PillFilterRow` — в отличие от голого
/// `FilterChip`, у которого в светлой теме заливка почти сливается с фоном.
class PillToggle extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const PillToggle({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final accent = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? glass.tint(accent) : glass.elevatedFill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.45) : glass.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? (selected ? Icons.check : Icons.filter_alt_outlined),
              size: 15,
              color: selected ? accent : glass.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? accent : glass.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final PillFilterItem item;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final accent = item.dot ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? glass.tint(accent) : glass.elevatedFill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.45) : glass.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.dot != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
            ] else if (selected) ...[
              Icon(Icons.check, size: 14, color: accent),
              const SizedBox(width: 6),
            ],
            Text(
              item.label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : glass.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
