import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../models/news_item.dart';
import 'tilt_card.dart';

class NewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;
  /// Если true — карточка занимает больше высоты (hero-режим для первой новости)
  final bool hero;

  const NewsCard({
    super.key,
    required this.item,
    required this.onTap,
    this.hero = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final hue = (item.title.hashCode.abs() % 360).toDouble();
    final glowColor =
        HSLColor.fromAHSL(1, hue, 0.55, 0.45).toColor();

    return TiltCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _imageBlock(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMMM yyyy', locale).format(item.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: hero ? 4 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.summary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.summary,
                          maxLines: hero ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageBlock(BuildContext context) {
    final aspectRatio = hero ? 4 / 3 : 16 / 9;

    if (item.imageUrl.isNotEmpty) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: CachedNetworkImage(
          imageUrl: item.imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, _) => _shimmerPlaceholder(context, aspectRatio),
          errorWidget: (_, _, _) => _gradientPlaceholder(context),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: _gradientPlaceholder(context),
    );
  }

  Widget _shimmerPlaceholder(BuildContext context, double aspectRatio) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2736) : const Color(0xFFE0E0E0),
      highlightColor:
          isDark ? const Color(0xFF3D3952) : const Color(0xFFF5F5F5),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(color: Colors.white),
      ),
    );
  }

  Widget _gradientPlaceholder(BuildContext _) {
    final hue = (item.title.hashCode.abs() % 360).toDouble();
    final color1 = HSLColor.fromAHSL(1, hue, 0.55, 0.40).toColor();
    final color2 =
        HSLColor.fromAHSL(1, (hue + 40) % 360, 0.65, 0.55).toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.article_outlined,
          size: 40,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
