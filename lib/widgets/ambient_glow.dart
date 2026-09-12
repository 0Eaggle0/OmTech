import 'package:flutter/material.dart';

import '../theme/app_glass.dart';

/// Спокойный фон экрана: два неподвижных радиальных пятна поверх фона темы.
///
/// В отличие от `AnimatedMeshBackground` ничего не анимирует и не
/// перерисовывается — годится под любой экран со списком.
class AmbientGlow extends StatelessWidget {
  final Widget child;

  const AmbientGlow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.85, -0.95),
          radius: 1.1,
          colors: [glass.ambientTop, Colors.transparent],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.0, 0.55),
            radius: 1.2,
            colors: [glass.ambientBottom, Colors.transparent],
          ),
        ),
        child: child,
      ),
    );
  }
}
