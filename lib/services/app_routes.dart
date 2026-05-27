import 'package:flutter/material.dart';

class AppRoutes {
  AppRoutes._();

  static Route<T> fadeScale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.93, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
