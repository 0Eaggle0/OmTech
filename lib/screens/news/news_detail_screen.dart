import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../l10n/app_localizations.dart';
import '../../models/news_item.dart';
import '../../services/link_launcher.dart';
import '../../services/news_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsItem item;

  const NewsDetailScreen({super.key, required this.item});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late final ConfettiController _confetti;
  late NewsItem _item;
  bool _loadingFull = false;

  bool get _isAward =>
      _item.isAward || NewsService.containsAwardKeyword(_item.title);

  String get _bodyText =>
      _item.fullText.isNotEmpty ? _item.fullText : _item.summary;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    if (_isAward) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
    _maybeFetchFullText();
  }

  void _maybeFetchFullText() {
    if (_item.fullText.isNotEmpty) return;
    if (_item.url.isEmpty || _item.url == NewsService.newsPageUrl) return;

    setState(() => _loadingFull = true);

    final service = context.read<NewsService>();
    service.fetchArticleDetail(_item.url).then((fetched) {
      if (!mounted) return;
      setState(() {
        _loadingFull = false;
        if (fetched != null && fetched.fullText.isNotEmpty) {
          _item = fetched;
        }
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _loadingFull = false);
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero-изображение
              SliverAppBar(
                expandedHeight: _item.imageUrl.isNotEmpty ? 260 : 0,
                pinned: true,
                flexibleSpace: _item.imageUrl.isNotEmpty
                    ? FlexibleSpaceBar(
                        background: CachedNetworkImage(
                          imageUrl: _item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _gradientBg(_item),
                          errorWidget: (_, _, _) => _gradientBg(_item),
                        ),
                      )
                    : null,
                backgroundColor: _item.imageUrl.isEmpty
                    ? theme.scaffoldBackgroundColor
                    : null,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Дата + бейдж награды
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              DateFormat('d MMMM yyyy', locale)
                                  .format(_item.date),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_isAward) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.emoji_events,
                                      size: 14, color: Color(0xFFFFD700)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Награда',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFD700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Заголовок
                      Text(
                        _item.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Тело статьи или shimmer пока грузится
              if (_loadingFull)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _TextShimmer(theme: theme),
                  ),
                )
              else if (_bodyText.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: _buildParagraphs(_bodyText).length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final para = _buildParagraphs(_bodyText)[i];
                      return _ParagraphWidget(paragraph: para, theme: theme);
                    },
                  ),
                ),

              // Галерея дополнительных фото
              if (_item.extraImages.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: _PhotoGallery(images: _item.extraImages),
                  ),
                ),

              // Кнопка + отступ снизу
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              openExternal(context, _item.url),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text(l.newsOpenFull),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Конфетти при наградах
          if (_isAward)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                gravity: 0.12,
                emissionFrequency: 0.05,
                colors: const [
                  Color(0xFF8B5CF6),
                  Color(0xFF6C5CE7),
                  Color(0xFFFFD700),
                  Color(0xFFEC4899),
                  Color(0xFF3B82F6),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<_Paragraph> _buildParagraphs(String text) {
    final lines = text.split('\n');
    final result = <_Paragraph>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final isQuestion = trimmed.endsWith('?');
      final isMedal = trimmed.startsWith('🥇') ||
          trimmed.startsWith('🥈') ||
          trimmed.startsWith('🥉');
      final isSubheader = !isQuestion &&
          !isMedal &&
          trimmed.length < 80 &&
          (trimmed.startsWith('Кейс') || trimmed.startsWith('Из Ирана'));
      result.add(_Paragraph(
        text: trimmed,
        isQuestion: isQuestion,
        isMedal: isMedal,
        isSubheader: isSubheader,
      ));
    }
    return result;
  }

  Widget _gradientBg(NewsItem item) {
    final hue = (item.title.hashCode.abs() % 360).toDouble();
    final c1 = HSLColor.fromAHSL(1, hue, 0.55, 0.35).toColor();
    final c2 = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.65, 0.50).toColor();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ),
      ),
    );
  }
}

class _TextShimmer extends StatelessWidget {
  final ThemeData theme;

  const _TextShimmer({required this.theme});

  @override
  Widget build(BuildContext context) {
    final base = theme.colorScheme.onSurface.withValues(alpha: 0.08);
    final highlight = theme.colorScheme.onSurface.withValues(alpha: 0.18);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 6; i++) ...[
            Container(
              height: 14,
              width: i == 5 ? 200 : double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          for (int i = 0; i < 4; i++) ...[
            Container(
              height: 14,
              width: i == 3 ? 140 : double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _Paragraph {
  final String text;
  final bool isQuestion;
  final bool isMedal;
  final bool isSubheader;

  const _Paragraph({
    required this.text,
    this.isQuestion = false,
    this.isMedal = false,
    this.isSubheader = false,
  });
}

class _ParagraphWidget extends StatelessWidget {
  final _Paragraph paragraph;
  final ThemeData theme;

  const _ParagraphWidget({required this.paragraph, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (paragraph.isQuestion) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        child: Text(
          paragraph.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
            height: 1.4,
          ),
        ),
      );
    }

    if (paragraph.isSubheader) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          paragraph.text,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
      );
    }

    if (paragraph.isMedal) {
      return Text(
        paragraph.text,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      );
    }

    return Text(
      paragraph.text,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  final List<String> images;

  const _PhotoGallery({required this.images});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Фотографии',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: images[i],
                width: 220,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  width: 220,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                ),
                errorWidget: (_, _, _) => Container(
                  width: 220,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
