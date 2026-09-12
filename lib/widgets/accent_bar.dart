import 'package:flutter/material.dart';

/// Цветная полоса слева у карточки — тип занятия, статус работы.
///
/// Растягивается по высоте родителя: кладите в `Positioned(top/bottom: 0)`
/// внутри `Stack` либо в `Row` с `crossAxisAlignment: stretch`.
class AccentBar extends StatelessWidget {
  final Color color;
  final double width;

  const AccentBar(this.color, {super.key, this.width = 5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withValues(alpha: 0.45)],
          ),
        ),
      ),
    );
  }
}
