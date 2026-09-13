import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/lk_controller.dart';
import '../models/contact_work.dart';

/// Вид найденного контакта преподавателя. Порядок — порядок показа.
enum TeacherContactKind { email, telegram, phone, vk, max }

class TeacherContact {
  final TeacherContactKind kind;

  /// Нормализованное значение для показа: `ivanov@omgtu.ru`, `@ivanov`,
  /// `t.me/+invite`, `+7 (913) 123-45-67`, `vk.com/ivanov`.
  final String value;

  const TeacherContact(this.kind, this.value);

  /// Ссылка, которую открывает тап по контакту.
  String get uri => switch (kind) {
        TeacherContactKind.email => 'mailto:$value',
        TeacherContactKind.telegram => value.startsWith('@')
            ? 'https://t.me/${value.substring(1)}'
            : 'https://$value',
        TeacherContactKind.phone =>
          'tel:+${value.replaceAll(RegExp(r'\D'), '')}',
        TeacherContactKind.vk || TeacherContactKind.max => 'https://$value',
      };

  String get _dedupKey => '${kind.name}:${value.toLowerCase()}';

  Map<String, dynamic> toJson() => {'kind': kind.name, 'value': value};

  static TeacherContact? fromJson(Map<String, dynamic> json) {
    final kind = TeacherContactKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final value = json['value'];
    if (kind == null || value is! String || value.isEmpty) return null;
    return TeacherContact(kind, value);
  }
}

class TeacherContacts {
  final List<TeacherContact> items;

  /// Дисциплина контактной работы, в заданиях которой нашлись контакты.
  final String discipline;

  const TeacherContacts({required this.items, required this.discipline});
}

// ───────────────────────── разбор текста ─────────────────────────

final _emailRe = RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}');
final _tmeRe = RegExp(
    r'(?:https?://)?(?:t|telegram)\.me/(\+?[A-Za-z0-9_-]{4,64}(?:/[A-Za-z0-9_-]+)?)',
    caseSensitive: false);
// Собачка не должна быть частью email («ivanov@mail.ru»).
final _atRe = RegExp(r'(?<![\w.@/+-])@([A-Za-z][A-Za-z0-9_]{4,31})(?![\w.@])');
// «тг: ivanov», «Telegram - ivanov» — без собачки. Но не «тг: https://…»
// и не начало email («tg: ivanov@mail.ru»).
final _tgWordRe = RegExp(
    r'(?<![A-Za-zА-Яа-яЁё])(?:тг|телеграм[а-яё]*|telegram|tg)\s*[:–—-]?\s*@?'
    r'(?!(?:https?|www)\b)([A-Za-z][A-Za-z0-9_]{4,31})(?![\w.@/])',
    caseSensitive: false,
    unicode: true);
final _phoneRe = RegExp(
    r'(?<![\d+])(?:\+7|8)[\s(-]*\d{3}[\s)-]*\d{3}[\s-]*\d{2}[\s-]*\d{2}(?!\d)');
final _vkRe = RegExp(r'(?:https?://)?(?:m\.)?vk\.com/([A-Za-z0-9_.]{2,64})',
    caseSensitive: false);
final _maxRe = RegExp(r'(?:https?://)?(?:web\.)?max\.ru/([A-Za-z0-9_+/-]{2,80})',
    caseSensitive: false);

/// Достаёт из текста задания почту, Telegram, телефон, VK и MAX.
/// Дубликаты схлопываются; порядок — по [TeacherContactKind].
List<TeacherContact> extractContacts(String text) {
  if (text.isEmpty) return const [];
  final out = <TeacherContact>[];
  final seen = <String>{};
  void add(TeacherContactKind kind, String value) {
    final contact = TeacherContact(kind, value);
    if (seen.add(contact._dedupKey)) out.add(contact);
  }

  for (final m in _emailRe.allMatches(text)) {
    add(TeacherContactKind.email, m[0]!);
  }
  for (final m in _tmeRe.allMatches(text)) {
    final path = m[1]!;
    final isInvite = path.startsWith('+') || path.contains('/');
    add(TeacherContactKind.telegram, isInvite ? 't.me/$path' : '@$path');
  }
  for (final m in _atRe.allMatches(text)) {
    add(TeacherContactKind.telegram, '@${m[1]}');
  }
  for (final m in _tgWordRe.allMatches(text)) {
    add(TeacherContactKind.telegram, '@${m[1]}');
  }
  for (final m in _phoneRe.allMatches(text)) {
    var d = m[0]!.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) continue;
    if (d.startsWith('8')) d = '7${d.substring(1)}';
    add(
      TeacherContactKind.phone,
      '+7 (${d.substring(1, 4)}) ${d.substring(4, 7)}-'
      '${d.substring(7, 9)}-${d.substring(9)}',
    );
  }
  for (final m in _vkRe.allMatches(text)) {
    add(TeacherContactKind.vk, 'vk.com/${m[1]!.replaceAll(RegExp(r'\.+$'), '')}');
  }
  for (final m in _maxRe.allMatches(text)) {
    add(TeacherContactKind.max, 'max.ru/${m[1]!.replaceAll(RegExp(r'/+$'), '')}');
  }
  return out;
}

// ───────────────────────── сопоставление ФИО ─────────────────────────

const _rankWords = {
  'доц', 'доцент', 'проф', 'профессор', 'ст', 'старший', 'преп',
  'преподаватель', 'асс', 'ассистент', 'зав', 'каф',
};

/// «Иванов Иван Иванович», «ИВАНОВ И.И.», «доц. Иванов И. И.» → «иванов ии».
/// В расписании и в ЛК одно и то же ФИО записано по-разному.
String teacherKey(String name) {
  final parts = name
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[.,]'), ' ')
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty && !_rankWords.contains(p))
      .toList();
  if (parts.isEmpty) return '';
  final initials = parts.skip(1).map((p) => p[0]).join();
  return initials.isEmpty ? parts.first : '${parts.first} $initials';
}

/// Фамилии совпадают, а инициалы не противоречат друг другу
/// («Иванов И.» подходит к «Иванов Иван Иванович»).
bool sameTeacher(String a, String b) {
  final ka = teacherKey(a).split(' ');
  final kb = teacherKey(b).split(' ');
  if (ka.first.isEmpty || ka.first != kb.first) return false;
  final ia = ka.length > 1 ? ka[1] : '';
  final ib = kb.length > 1 ? kb[1] : '';
  if (ia.isEmpty || ib.isEmpty) return true;
  return ia.startsWith(ib) || ib.startsWith(ia);
}

/// Контакты преподаватель обычно пишет в первом (самом старом) задании.
/// Идём от старых к новым: берём первое задание с контактами и ещё два
/// следующих — там порой дописывают то, чего не было в первом.
List<TeacherContact> scanTasksForContacts(
    List<ContactWorkItem> tasks, String lecturer) {
  final own = tasks
      .where((t) => t.teacher.trim().isEmpty || sameTeacher(t.teacher, lecturer))
      .toList()
    ..sort((a, b) {
      final da = a.createdAt;
      final db = b.createdAt;
      if (da != null && db != null) return da.compareTo(db);
      if (da != null) return -1;
      if (db != null) return 1;
      return a.number.compareTo(b.number);
    });

  final found = <TeacherContact>[];
  final seen = <String>{};
  int? firstHit;
  for (var i = 0; i < own.length; i++) {
    if (firstHit != null && i > firstHit + 2) break;
    for (final c in extractContacts(own[i].comment)) {
      if (seen.add(c._dedupKey)) found.add(c);
    }
    if (firstHit == null && found.isNotEmpty) firstHit = i;
  }

  final ordered = found.indexed.toList()
    ..sort((a, b) {
      final byKind = a.$2.kind.index.compareTo(b.$2.kind.index);
      return byKind != 0 ? byKind : a.$1.compareTo(b.$1);
    });
  return [for (final (_, c) in ordered) c];
}

// ───────────────────────── поиск ─────────────────────────

/// Ищет контакты преподавателя из расписания в заданиях контактной работы.
///
/// Результат кэшируется в `SharedPreferences`: найденный — на неделю,
/// «ничего нет» — на сутки. Сетевые ошибки не кэшируются.
class TeacherContactsService {
  TeacherContactsService._();

  static final instance = TeacherContactsService._();

  static const cachePrefix = 'teacher_contacts_v1_';
  static const _ttlFound = Duration(days: 7);
  static const _ttlEmpty = Duration(days: 1);

  final _inFlight = <String, Future<TeacherContacts?>>{};

  Future<TeacherContacts?> find(
    LkController lk, {
    required String lecturer,
    String? discipline,
  }) {
    final key = teacherKey(lecturer);
    if (!lk.isConnected || key.isEmpty) return Future.value(null);
    return _inFlight[key] ??= _find(lk, key, lecturer, discipline)
        .whenComplete(() => _inFlight.remove(key));
  }

  Future<TeacherContacts?> _find(
      LkController lk, String key, String lecturer, String? discipline) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = _readCache(prefs, key);
    if (cached != null) return cached.contacts;

    try {
      final api = lk.contactWorkApi;
      final disciplines =
          await api.readDisciplinesCache() ?? await api.fetchDisciplinesFresh();
      // Если препод ведёт несколько дисциплин — сначала та, что в расписании.
      final candidates = disciplines
          .where((d) =>
              d.id != null && d.teachers.any((t) => sameTeacher(t, lecturer)))
          .toList()
        ..sort((a, b) => _wordOverlap(b.discipline, discipline)
            .compareTo(_wordOverlap(a.discipline, discipline)));

      for (final d in candidates.take(3)) {
        final tasks =
            await api.readTasksCache(d.id!) ?? await api.fetchTasksFresh(d.id!);
        final items = scanTasksForContacts(tasks, lecturer);
        if (items.isEmpty) continue;
        final found = TeacherContacts(items: items, discipline: d.discipline);
        await _writeCache(prefs, key, found);
        return found;
      }
      await _writeCache(prefs, key, null);
      return null;
    } catch (e) {
      // Сеть или сессия — не повод запоминать «контактов нет».
      debugPrint('[Contacts] поиск для «$lecturer» не удался: $e');
      return null;
    }
  }

  static int _wordOverlap(String a, String? b) {
    if (b == null || b.isEmpty) return 0;
    Set<String> words(String s) => s
        .toLowerCase()
        .replaceAll('ё', 'е')
        .split(RegExp(r'[^a-zа-я0-9]+'))
        .where((w) => w.length > 3)
        .toSet();
    return words(a).intersection(words(b)).length;
  }

  ({TeacherContacts? contacts})? _readCache(SharedPreferences prefs, String key) {
    final raw = prefs.getString('$cachePrefix$key');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(map['t'] as int);
      final items = ((map['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => TeacherContact.fromJson(Map<String, dynamic>.from(m)))
          .whereType<TeacherContact>()
          .toList();
      final ttl = items.isEmpty ? _ttlEmpty : _ttlFound;
      if (DateTime.now().difference(savedAt) > ttl) return null;
      return (
        contacts: items.isEmpty
            ? null
            : TeacherContacts(
                items: items,
                discipline: (map['discipline'] ?? '') as String,
              ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
      SharedPreferences prefs, String key, TeacherContacts? contacts) async {
    await prefs.setString(
      '$cachePrefix$key',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'discipline': contacts?.discipline ?? '',
        'items': contacts?.items.map((i) => i.toJson()).toList() ?? const [],
      }),
    );
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(cachePrefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
