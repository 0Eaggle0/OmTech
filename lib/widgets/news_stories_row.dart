import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../services/app_routes.dart';
import '../screens/news/news_detail_screen.dart';

class NewsStoriesRow extends StatelessWidget {
  final List<NewsItem> items;

  const NewsStoriesRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, i) => _StoryItem(item: items[i]),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final NewsItem item;

  const _StoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final hue = (item.title.hashCode.abs() % 360).toDouble();
    final c1 = HSLColor.fromAHSL(1, hue, 0.65, 0.45).toColor();
    final c2 = HSLColor.fromAHSL(1, (hue + 50) % 360, 0.70, 0.55).toColor();
    final label = item.title.split(' ').take(2).join(' ');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppRoutes.fadeScale(NewsDetailScreen(item: item)),
      ),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // Градиентное кольцо
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [c1, c2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: item.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _gradientFill(c1, c2),
                            errorWidget: (_, _, _) => _gradientFill(c1, c2),
                          )
                        : _gradientFill(c1, c2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientFill(Color c1, Color c2) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c1, c2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.article, color: Colors.white70, size: 22),
        ),
      );
}
