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
/// с «пилюлей», которая едет от предыдущей вкладки к новой.
///
/// Анимация приходит снаружи (`progress` + `prevIndex`), потому что владелец
/// вкладок и так держит контроллер: панель не хранит своё состояние и не
/// рассинхронизируется с содержимым.
class FloatingNavBar extends StatelessWidget {
  final List<NavItemData> items;
  final int index;
  final int prevIndex;
  final Animation<double> progress;
  final ValueChanged<int> onSelected;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.prevIndex,
    required this.progress,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final shape = BorderRadius.circular(AppRadius.sheet);

    Widget content = SizedBox(
      height: kFloatingNavHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / items.length;
          return Stack(
            children: [
              // Перестраивается только пилюля: иконки остаются вне анимации.
              AnimatedBuilder(
                animation: progress,
                builder: (context, _) {
                  final t = Curves.easeOutCubic
                      .transform(progress.value.clamp(0.0, 1.0));
                  final pos =
                      lerpDouble(prevIndex.toDouble(), index.toDouble(), t)!;
                  return Positioned(
                    left: pos * slot + 6,
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
                  );
                },
              ),
              Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavBarItem(
                        item: items[i],
                        selected: i == index,
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
