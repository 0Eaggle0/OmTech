import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

class SlidingToggleItem {
  final IconData? icon;
  final String label;

  const SlidingToggleItem({this.icon, required this.label});
}

/// Единый переключатель на 2–4 равных сегмента: скруглённый трек с бегущей
/// подсветкой выбранного сегмента — вместо стандартного `SegmentedButton`,
/// у которого в светлой теме почти нет контраста.
class SlidingToggle extends StatelessWidget {
  final List<SlidingToggleItem> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final double height;

  const SlidingToggle({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final shape = BorderRadius.circular(AppRadius.pill);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: glass.elevatedFill,
        borderRadius: shape,
        border: Border.all(color: glass.hairline),
      ),
      padding: const EdgeInsets.all(3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: selected * slot,
                width: slot,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill - 3),
                    boxShadow: glass.glow(theme.colorScheme.primary),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _ToggleItem(
                        item: items[i],
                        selected: i == selected,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final SlidingToggleItem item;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = selected ? Colors.white : glass.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
