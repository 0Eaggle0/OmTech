import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/news_item.dart';

class NewsDatabase {
  static const _dbName = 'news_cache.db';
  static const _dbVersion = 2;
  static const _table = 'news_articles';

  Database? _db;
  Future<void>? _initFuture;

  /// init() зовут и из main (без await), и лениво из NewsService — храним
  /// Future, чтобы параллельные вызовы не открывали базу дважды.
  Future<void> init() => _initFuture ??= _open();

  Future<void> _open() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, _dbName),
      version: _dbVersion,
      onUpgrade: (db, oldVersion, _) async {
        await db.execute('DROP TABLE IF EXISTS $_table');
        await db.execute('''
          CREATE TABLE $_table (
            url TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            summary TEXT,
            full_text TEXT,
            date_ms INTEGER,
            image_url TEXT,
            extra_images TEXT,
            is_award INTEGER,
            cached_at INTEGER,
            full_fetched INTEGER
          )
        ''');
      },
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $_table (
          url TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          summary TEXT,
          full_text TEXT,
          date_ms INTEGER,
          image_url TEXT,
          extra_images TEXT,
          is_award INTEGER,
          cached_at INTEGER,
          full_fetched INTEGER
        )
      '''),
    );
  }

  Future<void> upsertList(List<NewsItem> items) async {
    final db = _db!;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final item in items) {
      // INSERT OR IGNORE so we don't overwrite full_text already fetched
      batch.rawInsert('''
        INSERT OR IGNORE INTO $_table
          (url, title, summary, full_text, date_ms, image_url, extra_images,
           is_award, cached_at, full_fetched)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
      ''', [
        item.url,
        item.title,
        item.summary,
        item.fullText.isNotEmpty ? item.fullText : null,
        item.date.millisecondsSinceEpoch,
        item.imageUrl,
        jsonEncode(item.extraImages),
        item.isAward ? 1 : 0,
        now,
      ]);
      // Update metadata fields that may have changed (title, summary, image)
      // but preserve full_text / full_fetched if already populated
      batch.rawUpdate('''
        UPDATE $_table SET
          title = ?,
          summary = ?,
          image_url = ?,
          is_award = ?,
          cached_at = ?
        WHERE url = ? AND full_fetched = 0
      ''', [
        item.title,
        item.summary,
        item.imageUrl,
        item.isAward ? 1 : 0,
        now,
        item.url,
      ]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertArticle(NewsItem item) async {
    final db = _db!;
    await db.rawInsert('''
      INSERT OR REPLACE INTO $_table
        (url, title, summary, full_text, date_ms, image_url, extra_images,
         is_award, cached_at, full_fetched)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
    ''', [
      item.url,
      item.title,
      item.summary,
      item.fullText,
      item.date.millisecondsSinceEpoch,
      item.imageUrl,
      jsonEncode(item.extraImages),
      item.isAward ? 1 : 0,
      DateTime.now().millisecondsSinceEpoch,
    ]);
  }

  Future<List<NewsItem>> getAll() async {
    final db = _db!;
    final rows = await db.query(
      _table,
      orderBy: 'date_ms DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<NewsItem?> getByUrl(String url) async {
    final db = _db!;
    final rows = await db.query(_table, where: 'url = ?', whereArgs: [url]);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<bool> needsFullFetch(String url) async {
    final db = _db!;
    final rows = await db.query(
      _table,
      columns: ['full_fetched'],
      where: 'url = ?',
      whereArgs: [url],
    );
    if (rows.isEmpty) return true;
    return (rows.first['full_fetched'] as int) == 0;
  }

  NewsItem _fromRow(Map<String, dynamic> row) {
    List<String> extraImages = [];
    final raw = row['extra_images'] as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        extraImages = List<String>.from(jsonDecode(raw) as List);
      } catch (_) {}
    }
    return NewsItem(
      url: row['url'] as String,
      title: row['title'] as String,
      summary: (row['summary'] as String?) ?? '',
      fullText: (row['full_text'] as String?) ?? '',
      date: DateTime.fromMillisecondsSinceEpoch((row['date_ms'] as int?) ?? 0),
      imageUrl: (row['image_url'] as String?) ?? '',
      extraImages: extraImages,
      isAward: (row['is_award'] as int) == 1,
    );
  }
}
