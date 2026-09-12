import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Плавающая нижняя панель: скруглённая плашка, оторванная от края экрана,
/// с «пилюлей», которую можно и тапнуть, и утащить пальцем, и смахнуть.
///
/// Индикатор — `AnimatedPositioned`: при обычном тапе едет плавно (duration
/// > 0), во время перетаскивания следует за пальцем один в один
/// (duration: 0), а отпустив — довязывает анимацию до ближайшей вкладки.
/// Так вся анимация живёт в одном месте вместо внешнего контроллера.
class FloatingNavBar extends StatefulWidget {
  final List<NavItemData> items;
  final int index;
  final ValueChanged<int> onSelected;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  /// Индекс, с которого началось перетаскивание. `null` — не тащим сейчас.
  double? _dragBase;

  /// Накопленное смещение пальца в пикселях с начала жеста.
  double _dragDx = 0;

  bool get _dragging => _dragBase != null;

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _dragBase = widget.index.toDouble();
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

    // Короткий быстрый смах — даже если палец прошёл меньше половины
    // слота, засчитываем переключение на соседнюю вкладку по скорости.
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() > 300 && (continuous - base).abs() < 0.5) {
      continuous = base + (velocity < 0 ? 1 : -1);
    }

    final target = continuous.round().clamp(0, widget.items.length - 1);
    setState(() {
      _dragBase = null;
      _dragDx = 0;
    });
    if (target != widget.index) widget.onSelected(target);
  }

  void _onDragCancel() {
    setState(() {
      _dragBase = null;
      _dragDx = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final shape = BorderRadius.circular(AppRadius.sheet);

    Widget content = SizedBox(
      height: kFloatingNavHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / widget.items.length;
          final base = _dragBase;
          final position = base == null
              ? widget.index.toDouble()
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
                // Перестраивается только пилюля: иконки не завязаны на жест.
                AnimatedPositioned(
                  duration: _dragging
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: position * slot + 6,
                  top: 7,
                  bottom: 7,
                  width: slot - 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: glass.navIndicator,
                      borderRadius: BorderRadius.circular(AppRadius.tile),
                      border: Border.all(
                        color: glass.accent.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: _NavBarItem(
                          item: widget.items[i],
                          selected: i == widget.index,
                          onTap: () => widget.onSelected(i),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (glassBlurEnabled) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: ColoredBox(color: glass.navFill, child: content),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Под размытием заливку кладёт ColoredBox выше, иначе — здесь.
              color: glassBlurEnabled ? null : glass.navFill,
              borderRadius: shape,
              border: Border.all(color: glass.hairline),
              boxShadow: glass.floatShadow,
            ),
            child: ClipRRect(borderRadius: shape, child: content),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final color = selected ? theme.colorScheme.primary : glass.textFaint;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: Icon(
              selected ? item.activeIcon : item.icon,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(item.label, maxLines: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
