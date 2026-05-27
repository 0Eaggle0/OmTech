/// Новость университета.
class NewsItem {
  final String title;
  final String summary;
  final String fullText;
  final DateTime date;
  final String url;
  final String imageUrl;
  final List<String> extraImages;
  final bool isAward;

  const NewsItem({
    required this.title,
    required this.summary,
    required this.date,
    required this.url,
    required this.imageUrl,
    this.fullText = '',
    this.extraImages = const [],
    this.isAward = false,
  });
}
