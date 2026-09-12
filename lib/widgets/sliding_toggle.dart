import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
///
/// Переключается тапом по сегменту и горизонтальным свайпом — подсветка
/// едет за пальцем, как у плашки в нижней навигации.
class SlidingToggle extends StatefulWidget {
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
  State<SlidingToggle> createState() => _SlidingToggleState();
}

class _SlidingToggleState extends State<SlidingToggle> {
  /// Индекс, с которого начали тащить; null — не тащим.
  double? _dragBase;

  /// Накопленное смещение пальца в пикселях.
  double _dragDx = 0;

  bool get _dragging => _dragBase != null;

  void _onDragStart(DragStartDetails _) {
    setState(() {
      _dragBase = widget.selected.toDouble();
      _dragDx = 0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _dragDx += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details, double slot) {
    final base = _dragBase;
    if (base == null) return;

    var continuous = base + _dragDx / slot;
    final velocity = details.primaryVelocity ?? 0;
    // Короткий, но быстрый смах листает на соседний сегмент.
    if (velocity.abs() > 300 && (continuous - base).abs() < 0.5) {
      continuous = base + (velocity < 0 ? 1 : -1);
    }
    final target = continuous.round().clamp(0, widget.items.length - 1);

    setState(() {
      _dragBase = null;
      _dragDx = 0;
    });
    if (target != widget.selected) widget.onSelected(target);
  }

  void _onDragCancel() {
    setState(() {
      _dragBase = null;
      _dragDx = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final shape = BorderRadius.circular(AppRadius.pill);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: glass.elevatedFill,
        borderRadius: shape,
        border: Border.all(color: glass.hairline),
      ),
      padding: const EdgeInsets.all(3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / widget.items.length;
          final base = _dragBase;
          final position = base == null
              ? widget.selected.toDouble()
              : (base + _dragDx / slot)
                  .clamp(0.0, widget.items.length - 1.0);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: (d) => _onDragEnd(d, slot),
            onHorizontalDragCancel: _onDragCancel,
            child: Stack(
              children: [
                AnimatedPositioned(
                  // Пока тащим — без анимации, иначе плашка «догоняет» палец.
                  duration: _dragging
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  left: position * slot,
                  width: slot,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(AppRadius.pill - 3),
                      boxShadow: glass.glow(theme.colorScheme.primary),
                    ),
                  ),
                ),
                // Подписи растягиваем на всю высоту трека: непозиционированный
                // ребёнок Stack иначе схлопнется по высоте текста и прилипнет
                // к верхнему краю.
                Positioned.fill(
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.items.length; i++)
                        Expanded(
                          child: _ToggleItem(
                            item: widget.items[i],
                            selected: i == widget.selected,
                            onTap: () => widget.onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        // scaleDown вместо ellipsis: длинная подпись уменьшается целиком,
        // а не обрезается многоточием.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16, color: color),
                const SizedBox(width: 6),
              ],
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
                child: Text(item.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
