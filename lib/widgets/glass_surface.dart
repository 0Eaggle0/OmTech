import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

/// Базовая поверхность оформления: карточка, шапка, панель.
///
/// По умолчанию `blur` = 0 и `BackdropFilter` вообще не создаётся — это то,
/// что нужно почти всем карточкам. Настоящее размытие стоит кадрового времени,
/// поэтому включается точечно (шапка главной) и только там, где под ним
/// действительно что-то видно.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  /// Сигма размытия. 0 — размытия нет.
  final double blur;

  /// Заливка. По умолчанию — `cardFill` темы.
  final Color? color;

  /// Градиентная заливка вместо однотонной.
  final Gradient? gradient;

  final bool border;

  /// Цветная подсветка под поверхностью.
  final Color? glowColor;

  final VoidCallback? onTap;

  const GlassSurface({
    super.key,
    required this.child,
    this.radius = AppRadius.card,
    this.padding,
    this.blur = 0,
    this.color,
    this.gradient,
    this.border = true,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final shape = BorderRadius.circular(radius);
    final blurred = blur > 0 && glassBlurEnabled;

    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: content,
        ),
      );
    }

    // Заливка и граница живут внутри клипа, тень — снаружи, иначе её срежет.
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? glass.cardFill) : null,
        gradient: gradient,
        borderRadius: shape,
        border: border ? Border.all(color: glass.hairline) : null,
      ),
      child: content,
    );

    if (blurred) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: surface,
      );
    }

    surface = ClipRRect(borderRadius: shape, child: surface);

    if (glowColor != null) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: glass.glow(glowColor!),
        ),
        child: surface,
      );
    }

    return surface;
  }
}
