import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerNewsCard extends StatelessWidget {
  const ShimmerNewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2736) : const Color(0xFFE0E0E0);
    final highlight = isDark ? const Color(0xFF3D3952) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        children: [
          _ShimmerCard(),
          const SizedBox(height: 14),
          _ShimmerCard(),
          const SizedBox(height: 14),
          _ShimmerCard(),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  width: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(height: 14, color: Colors.white),
                const SizedBox(height: 6),
                Container(height: 14, width: 200, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 11, color: Colors.white),
                const SizedBox(height: 4),
                Container(height: 11, width: 240, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerCarousel extends StatelessWidget {
  const ShimmerCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2736) : const Color(0xFFE0E0E0);
    final highlight = isDark ? const Color(0xFF3D3952) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class ShimmerGreeting extends StatelessWidget {
  const ShimmerGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2736) : const Color(0xFFE0E0E0);
    final highlight = isDark ? const Color(0xFF3D3952) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
