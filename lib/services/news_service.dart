import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/news_item.dart';
import 'news_database.dart';

class NewsService {
  static const newsPageUrl = 'https://www.omgtu.ru/news/';
  static const _baseUrl = 'https://www.omgtu.ru';

  final NewsDatabase db;

  List<NewsItem>? _listCache;
  DateTime? _listCacheTime;

  NewsService({NewsDatabase? database}) : db = database ?? NewsDatabase();

  Future<void> init() => db.init();

  Future<List<NewsItem>> fetchNews({bool forceRefresh = false}) async {
    await db.init();
    if (!forceRefresh && _listCache != null && _listCacheTime != null) {
      if (DateTime.now().difference(_listCacheTime!).inMinutes < 30) {
        return _listCache!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse(newsPageUrl),
        headers: {
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'ru-RU,ru;q=0.9',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = _decodeBody(response);
        final items = _parseHtml(body);
        if (items.isNotEmpty && _looksValid(items)) {
          await db.upsertList(items);
          _listCache = items;
          _listCacheTime = DateTime.now();
          return items;
        }
      }
    } catch (_) {}

    // Сеть недоступна — грузим из базы
    final cached = await db.getAll();
    if (cached.isNotEmpty) return cached;

    // База пуста — показываем демо
    return _demo;
  }

  /// Загружает полный текст статьи со страницы [url].
  /// Если полный текст уже есть в базе — возвращает из базы.
  /// Сохраняет результат в БД.
  Future<NewsItem?> fetchArticleDetail(String url) async {
    await db.init();
    // Проверяем базу
    final cached = await db.getByUrl(url);
    if (cached != null && cached.fullText.isNotEmpty) return cached;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'ru-RU,ru;q=0.9',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final body = _decodeBody(response);
      final parsed = _parseArticle(url, body, cached);
      if (parsed != null) {
        await db.upsertArticle(parsed);
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  NewsItem? _parseArticle(String url, String body, NewsItem? existing) {
    final doc = html_parser.parse(body);

    // Bitrix CMS — пробуем в порядке приоритета
    final contentSelectors = [
      '.news-detail-text',
      '.news-detail__text',
      '.article__body',
      '.article-body',
      '[data-entity="detail-text"]',
      '#article-body',
      '.bx-news-detail',
      '.detail_text',
      '.news-detail',
    ];

    var contentEl = contentSelectors
        .map((sel) => doc.querySelector(sel))
        .firstWhere((el) => el != null, orElse: () => null);

    // Fallback: main article tag
    contentEl ??= doc.querySelector('article');

    if (contentEl == null) return null;

    // Собираем параграфы
    final paragraphs = contentEl
        .querySelectorAll('p, h2, h3, h4')
        .map((el) => el.text.trim())
        .where((t) => t.length >= 20)
        .toList();

    if (paragraphs.isEmpty) return null;

    final fullText = paragraphs.join('\n\n');

    // Дополнительные изображения из контента
    final mainImage = existing?.imageUrl ?? '';
    final extraImages = contentEl
        .querySelectorAll('img')
        .map((img) {
          var src = img.attributes['src'] ??
              img.attributes['data-src'] ??
              img.attributes['data-lazy-src'] ??
              '';
          if (src.isEmpty) return '';
          if (!src.startsWith('http')) {
            src = _baseUrl + (src.startsWith('/') ? src : '/$src');
          }
          return src;
        })
        .where((src) => src.isNotEmpty && src != mainImage)
        .toSet()
        .toList();

    // Если existing есть — обновляем его fullText и extraImages
    if (existing != null) {
      return NewsItem(
        url: existing.url,
        title: existing.title,
        summary: existing.summary,
        fullText: fullText,
        date: existing.date,
        imageUrl: existing.imageUrl,
        extraImages: extraImages.isNotEmpty ? extraImages : existing.extraImages,
        isAward: existing.isAward,
      );
    }

    // Иначе создаём минимальный NewsItem
    final titleEl = doc.querySelector('h1, .news-detail-title, .news__title');
    final title = (titleEl?.text ?? '').trim();
    if (title.isEmpty) return null;

    return NewsItem(
      url: url,
      title: title,
      summary: paragraphs.first,
      fullText: fullText,
      date: DateTime.now(),
      imageUrl: '',
      extraImages: extraImages,
      isAward: containsAwardKeyword(title),
    );
  }

  bool _looksValid(List<NewsItem> items) {
    if (items.isEmpty) return false;
    final title = items.first.title;
    final hasCyrillic = RegExp(r'[а-яёА-ЯЁ]').hasMatch(title);
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(title);
    return hasCyrillic || hasLatin;
  }

  List<NewsItem> _parseHtml(String body) {
    final doc = html_parser.parse(body);
    final items = <NewsItem>[];

    var elements = doc.querySelectorAll(
      '.news-list .news-item, '
      '.news-list-section .section-item, '
      '.catItem, '
      '.bx-newslist .bx-newsitem, '
      '.news__list .news__item, '
      'section.news article',
    );

    if (elements.isEmpty) {
      elements = doc.querySelectorAll('li:has(a[href*="/news/"])');
    }

    if (elements.isEmpty) {
      elements =
          doc.querySelectorAll('div:has(a[href*="/?ID="]), article:has(a)');
    }

    for (final el in elements.take(20)) {
      try {
        final titleEl = el.querySelector(
          'h1, h2, h3, h4, '
          '.item-title, .news-title, .news__title, '
          '.section-item-title a, '
          'a.name',
        );
        final title = (titleEl?.text ?? '').trim();
        if (title.isEmpty || title.length < 5) continue;

        final linkEl = el.querySelector('a[href]');
        var url = linkEl?.attributes['href'] ?? '';
        if (url.isNotEmpty && !url.startsWith('http')) {
          url = _baseUrl + (url.startsWith('/') ? url : '/$url');
        }

        final imgEl = el.querySelector('img');
        var imageUrl = imgEl?.attributes['src'] ??
            imgEl?.attributes['data-src'] ??
            imgEl?.attributes['data-lazy-src'] ??
            '';
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          imageUrl =
              _baseUrl + (imageUrl.startsWith('/') ? imageUrl : '/$imageUrl');
        }

        final dateEl = el.querySelector(
          'time, [datetime], '
          '.date, .item-date, .news-date, .news__date, '
          '.section-item-date',
        );
        final dateStr =
            dateEl?.attributes['datetime'] ?? dateEl?.text.trim() ?? '';
        final date = _parseDate(dateStr);

        final summaryEl = el.querySelector(
          'p, .preview-text, .introtext, '
          '.item-intro, .news__intro, '
          '.section-item-text',
        );
        final summary = (summaryEl?.text ?? '').trim();

        items.add(NewsItem(
          title: title,
          summary: summary,
          date: date,
          url: url.isNotEmpty ? url : newsPageUrl,
          imageUrl: imageUrl,
          isAward: containsAwardKeyword(title),
        ));
      } catch (_) {}
    }

    if (items.isEmpty) {
      final seen = <String>{};
      for (final a in doc.querySelectorAll('a[href]')) {
        final href = a.attributes['href'] ?? '';
        if (!href.contains('/news/') && !href.contains('/?ID=')) continue;
        final title = a.text.trim();
        if (title.length < 10 || seen.contains(title)) continue;
        seen.add(title);
        final url = href.startsWith('http') ? href : _baseUrl + href;
        items.add(NewsItem(
          title: title,
          summary: '',
          date: DateTime.now(),
          url: url,
          imageUrl: '',
          isAward: containsAwardKeyword(title),
        ));
        if (items.length >= 10) break;
      }
    }

    return items;
  }

  static bool containsAwardKeyword(String title) {
    final t = title.toLowerCase();
    return t.contains('приз') ||
        t.contains('серебр') ||
        t.contains('золот') ||
        t.contains('победа') ||
        t.contains('победи') ||
        t.contains('место') ||
        t.contains('чемпион') ||
        t.contains('лауреат') ||
        t.contains('награда');
  }

  // Детектирует кодировку из заголовка Content-Type и мета-тега charset.
  // Bitrix CMS может отдавать страницы как в UTF-8, так и в Windows-1251.
  String _decodeBody(http.Response response) {
    final ct = (response.headers['content-type'] ?? '').toLowerCase();
    if (ct.contains('1251')) return _win1251(response.bodyBytes);
    if (ct.contains('utf-8') || ct.contains('utf8')) {
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    }

    // Первые 2 КБ совместимы с Latin-1 — ищем charset в мета-теге
    final end = response.bodyBytes.length.clamp(0, 2048);
    final peek = latin1.decode(response.bodyBytes.sublist(0, end)).toLowerCase();
    if (peek.contains('1251')) return _win1251(response.bodyBytes);

    try {
      return utf8.decode(response.bodyBytes);
    } catch (_) {
      return _win1251(response.bodyBytes);
    }
  }

  static String _win1251(List<int> bytes) {
    // Верхняя половина Windows-1251 (0x80–0xFF) → Unicode code points
    const upper = <int>[
      0x0402,0x0403,0x201A,0x0453,0x201E,0x2026,0x2020,0x2021,
      0x20AC,0x2030,0x0409,0x2039,0x040A,0x040C,0x040B,0x040F,
      0x0452,0x2018,0x2019,0x201C,0x201D,0x2022,0x2013,0x2014,
      0xFFFD,0x2122,0x0459,0x203A,0x045A,0x045C,0x045B,0x045F,
      0x00A0,0x040E,0x045E,0x0408,0x00A4,0x0490,0x00A6,0x00A7,
      0x0401,0x00A9,0x0404,0x00AB,0x00AC,0x00AD,0x00AE,0x0407,
      0x00B0,0x00B1,0x0406,0x0456,0x0491,0x00B5,0x00B6,0x00B7,
      0x0451,0x2116,0x0454,0x00BB,0x0458,0x0405,0x0455,0x0457,
      0x0410,0x0411,0x0412,0x0413,0x0414,0x0415,0x0416,0x0417,
      0x0418,0x0419,0x041A,0x041B,0x041C,0x041D,0x041E,0x041F,
      0x0420,0x0421,0x0422,0x0423,0x0424,0x0425,0x0426,0x0427,
      0x0428,0x0429,0x042A,0x042B,0x042C,0x042D,0x042E,0x042F,
      0x0430,0x0431,0x0432,0x0433,0x0434,0x0435,0x0436,0x0437,
      0x0438,0x0439,0x043A,0x043B,0x043C,0x043D,0x043E,0x043F,
      0x0440,0x0441,0x0442,0x0443,0x0444,0x0445,0x0446,0x0447,
      0x0448,0x0449,0x044A,0x044B,0x044C,0x044D,0x044E,0x044F,
    ];
    return String.fromCharCodes(
      bytes.map((b) => b < 0x80 ? b : upper[b - 0x80]),
    );
  }

  DateTime _parseDate(String raw) {
    if (raw.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(raw);
    } catch (_) {}
    final dmy = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(raw);
    if (dmy != null) {
      return DateTime(int.parse(dmy.group(3)!), int.parse(dmy.group(2)!),
          int.parse(dmy.group(1)!));
    }
    return DateTime.now();
  }

  static final List<NewsItem> _demo = [
    NewsItem(
      title: 'Из Ирана в Россию: путь студента в тысячи километров ради мечты',
      summary:
          'Али Курех Паз приехал в ОмГТУ из Ирана. Сейчас он осваивает русский язык '
          'и базовые дисциплины на подготовительном отделении, а уже в сентябре начнёт '
          'обучаться по специальности «Ракетные комплексы и космонавтика».',
      fullText:
          'Али Курех Паз приехал в ОмГТУ из Ирана. Сейчас он осваивает русский язык и базовые дисциплины на подготовительном отделении факультета довузовской подготовки, а уже в сентябре начнёт обучаться по специальности «Ракетные комплексы и космонавтика». В интервью Али рассказал, почему ему нравится в России, а также поделился, какая русская еда нравится ему больше всего, как он любит проводить время в университете и в городе.\n\n'
          'Откуда ты приехал в Россию?\n\n'
          'Я родился на юге Ирана, в городе с богатой культурой, который называется Ахваз.\n\n'
          'Как узнал про Омский политех? Что стало решающим фактором при выборе вуза?\n\n'
          'Я узнал об Омском государственном техническом университете через программу поступления по стипендии. При выборе университета у меня было несколько вариантов, но по моей специальности список был ограничен. В итоге я выбрал ОмГТУ, потому что он соответствовал условиям и возможностям по обучению и получению стипендии.\n\n'
          'Чем заинтересовала специальность, на которой планируешь обучаться?\n\n'
          'Моя специальность привлекла меня своей актуальностью и возможностью применять знания на практике. Я считаю её перспективной для будущей карьеры.\n\n'
          'Какой был самый большой страх перед переездом в Сибирь?\n\n'
          'Перед переездом больше всего меня беспокоили суровый климат Сибири, а также новая культура и образ жизни. Однако со временем я адаптировался, ближе познакомился с местными традициями и постепенно привык.',
      date: DateTime(2026, 5, 27),
      url: 'https://omgtu.ru/news/?eid=101392',
      imageUrl:
          'https://omgtu.ru/upload/iblock/80f/96ivcxy8yc3ves30l908sux3tyalumxy/IMG_9118_.jpg',
      extraImages: [
        'https://omgtu.ru/upload/iblock/266/p8tr8su9rc8yf6ncob2efaefocp2uwq1/prrogono.jpg',
        'https://omgtu.ru/upload/iblock/7b7/52ix3f5fcbfyiiu9kxtr3zommeoj26f2/aFCdhSxNDnnptdyFlF4Y_QamuJSV02ddi1VRGRTs9NPDA_t4u2N3JFgnpdclfbNHFWtju79c5yzUyywAEeJIeUAT.jpg',
      ],
    ),
    NewsItem(
      title: 'Политехники взяли призовые места на чемпионате по большим данным и ИИ',
      summary:
          'Чемпионат «Технологии больших данных и ИИ» был организован кафедрой '
          'прикладной математики и фундаментальной информатики ОмГТУ на площадке Школы 21.',
      fullText:
          'Чемпионат «Технологии больших данных и ИИ» был организован кафедрой прикладной математики и фундаментальной информатики ОмГТУ на площадке Школы 21. В нём приняли участие более 70 человек из разных вузов города в составе 18 команд. Команды Омского политеха показали отличные результаты и взяли 5 призовых мест в нескольких кейсах.\n\n'
          'Кейс 1. Навигация в закрытой среде: создание агента на основе GigaChat (Сбер)\n\n'
          '🥇 1-е место — «Морские кодики» (ОмГТУ)\n'
          '🥈 2-е место — «BabaCh_AI» (ОмГУ им. Ф.М. Достоевского)\n'
          '🥉 3-е место — «Капучинатор» (ОмГТУ)',
      date: DateTime(2026, 5, 26),
      url: 'https://omgtu.ru/news/?eid=101389',
      imageUrl:
          'https://omgtu.ru/upload/iblock/978/87v0kwtcf77dnfo3fsqpwpnet9p3o0d5/6.jpg',
      isAward: true,
    ),
    NewsItem(
      title: 'ОмГТУ доказывает высокое качество подготовки студентов',
      summary:
          'Результаты независимой оценки качества образования подтвердили высокий '
          'уровень подготовки выпускников Омского государственного технического университета.',
      date: DateTime(2026, 5, 26),
      url: 'https://omgtu.ru/news/?eid=101385',
      imageUrl:
          'https://omgtu.ru/upload/iblock/d24/ms3u124v8cybsx9bsthrr332p90syajs/MG_8395_.png',
    ),
    NewsItem(
      title: 'Серебро и народная любовь: студентки ОмГТУ в финале CASE-IN',
      summary:
          'Студентки ОмГТУ триумфально выступили в финале международного чемпионата '
          'CASE-IN в Москве, завоевав серебряные медали и приз зрительских симпатий.',
      date: DateTime(2026, 5, 25),
      url: 'https://omgtu.ru/news/?eid=101375',
      imageUrl:
          'https://omgtu.ru/upload/iblock/297/610ixbv18mzplwq7b829lv04x7t476ho/O3QIdtGYbkjW_PLZYcdxCGFioWlCeR39xlCEBpF2rWwJqBx94QqPrjs9uk6ZAWGPYRl75ikcOg0p4o4c7M0guEz9.jpg',
      isAward: true,
    ),
  ];
}
