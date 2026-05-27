import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedMeshBackground extends StatefulWidget {
  final Widget child;

  const AnimatedMeshBackground({super.key, required this.child});

  @override
  State<AnimatedMeshBackground> createState() => _AnimatedMeshBackgroundState();
}

class _AnimatedMeshBackgroundState extends State<AnimatedMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => CustomPaint(
            painter: _MeshPainter(_controller.value),
            child: const SizedBox.expand(),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double t;

  _MeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      _Blob(
        color: const Color(0xFF6C5CE7).withValues(alpha: 0.45),
        cx: 0.2 + 0.15 * math.sin(t * math.pi * 2),
        cy: 0.2 + 0.1 * math.cos(t * math.pi * 2 * 0.7),
        r: 0.38 + 0.06 * math.sin(t * math.pi * 2 * 0.5),
      ),
      _Blob(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
        cx: 0.75 + 0.12 * math.cos(t * math.pi * 2 * 0.8),
        cy: 0.15 + 0.12 * math.sin(t * math.pi * 2 * 0.6),
        r: 0.30 + 0.05 * math.cos(t * math.pi * 2 * 0.9),
      ),
      _Blob(
        color: const Color(0xFFEC4899).withValues(alpha: 0.20),
        cx: 0.85 + 0.08 * math.sin(t * math.pi * 2 * 1.1),
        cy: 0.7 + 0.12 * math.cos(t * math.pi * 2 * 0.5),
        r: 0.28 + 0.04 * math.sin(t * math.pi * 2 * 0.7),
      ),
      _Blob(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.20),
        cx: 0.1 + 0.1 * math.cos(t * math.pi * 2 * 0.9),
        cy: 0.8 + 0.1 * math.sin(t * math.pi * 2 * 1.2),
        r: 0.32 + 0.05 * math.cos(t * math.pi * 2 * 0.6),
      ),
    ];

    for (final blob in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [blob.color, blob.color.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(blob.cx * size.width, blob.cy * size.height),
            radius: blob.r * size.width,
          ),
        );
      canvas.drawCircle(
        Offset(blob.cx * size.width, blob.cy * size.height),
        blob.r * size.width,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t;
}

class _Blob {
  final Color color;
  final double cx, cy, r;

  const _Blob({
    required this.color,
    required this.cx,
    required this.cy,
    required this.r,
  });
}
