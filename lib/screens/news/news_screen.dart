import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/news_item.dart';
import '../../services/app_routes.dart';
import '../../services/link_launcher.dart';
import '../../services/news_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/news_card.dart';
import '../../widgets/news_stories_row.dart';
import '../../widgets/shimmer_placeholder.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final NewsService _service;
  late Future<List<NewsItem>> _future;

  @override
  void initState() {
    super.initState();
    _service = context.read<NewsService>();
    _future = _service.fetchNews();
  }

  Future<void> _refresh() async {
    final future = _service.fetchNews(forceRefresh: true);
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.newsTitle),
        actions: [
          IconButton(
            tooltip: l.profileSiteNews,
            onPressed: () => openExternal(context, NewsService.newsPageUrl),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: FutureBuilder<List<NewsItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: ShimmerNewsCard(),
            );
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.wifi_off_outlined,
              title: l.newsLoadError,
              actionLabel: l.retry,
              onAction: _refresh,
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return EmptyState(
                icon: Icons.newspaper_outlined, title: l.newsEmpty);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                // Stories-ряд
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: NewsStoriesRow(items: items.take(5).toList())
                        .animate()
                        .fadeIn(duration: 280.ms)
                        .slideX(begin: -0.04, curve: Curves.easeOut),
                  ),
                ),

                // Hero-карточка (первая новость)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: NewsCard(
                      item: items.first,
                      hero: true,
                      onTap: () => Navigator.push(
                        context,
                        AppRoutes.fadeScale(
                            NewsDetailScreen(item: items.first)),
                      ),
                    ).animate().fadeIn(duration: 320.ms).slideY(
                          begin: 0.04,
                          curve: Curves.easeOut,
                        ),
                  ),
                ),

                // Остальные новости
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: items.length - 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final item = items[i + 1];
                      return NewsCard(
                        item: item,
                        onTap: () => Navigator.push(
                          context,
                          AppRoutes.fadeScale(NewsDetailScreen(item: item)),
                        ),
                      )
                          .animate(key: ValueKey(item.url))
                          .fadeIn(duration: 180.ms)
                          .slideY(begin: 0.04, curve: Curves.easeOut);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
