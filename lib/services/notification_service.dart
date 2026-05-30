import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/lk_controller.dart';
import '../models/report_work.dart';
import '../models/student_record.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _chTasks = 'ch_tasks';
  static const _chReports = 'ch_reports';
  static const _chGrades = 'ch_grades';

  static const _keyReportSnapshot = 'notif_report_snapshot';
  static const _keyGradesSnapshot = 'notif_grades_snapshot';
  static const _keyPermAsked = 'notif_perm_asked';

  // Счётчик ID уведомлений (автоинкремент в памяти — достаточно для сессии).
  int _nextId = 100;
  int _id() => _nextId++;

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  Future<void> requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyPermAsked) == true) return;
    await prefs.setBool(_keyPermAsked, true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ─────────────────────── show helpers ───────────────────────

  Future<void> _show(String title, String body, String channelId,
      String channelName) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: channelId == _chGrades
            ? Importance.defaultImportance
            : Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(_id(), title, body, details);
  }

  // ─────────────────────── checks ─────────────────────────────

  Future<void> checkAll(LkController lk) async {
    if (!lk.isConnected) return;
    await Future.wait([
      checkContactWork(lk),
      checkReportWorks(lk),
      checkGrades(lk),
    ]);
  }

  /// Проверяет новые задания в контактной работе.
  /// Использует существующий `calcNewCount`, который сам сравнивает
  /// с сохранённым baseline и обновляет его.
  Future<void> checkContactWork(LkController lk) async {
    try {
      final api = lk.contactWorkApi;
      final disciplines = await api.readDisciplinesCache();
      if (disciplines == null || disciplines.isEmpty) return;

      final updates = <String>[];
      for (final d in disciplines) {
        if (d.id == null) continue;
        final newCount = await api.calcNewCount(d);
        if (newCount > 0) {
          updates.add('${d.discipline}: +$newCount');
        }
      }

      if (updates.isEmpty) return;

      if (updates.length == 1) {
        await _show(
          '📚 Вставай, есть задание!',
          '${updates.first} — само себя не сделает',
          _chTasks,
          'Контактная работа',
        );
      } else {
        await _show(
          '📚 Задания копятся (${updates.length} предм.)',
          updates.join(' • '),
          _chTasks,
          'Контактная работа',
        );
      }
    } catch (_) {
      // Фоновая проверка — игнорируем сетевые ошибки.
    }
  }

  /// Проверяет изменение статуса отчётных работ.
  Future<void> checkReportWorks(LkController lk) async {
    try {
      final api = lk.reportWorkApi;
      final result = await api.readCache();
      if (result == null) return;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyReportSnapshot);

      // Первый запуск — просто фиксируем baseline.
      if (raw == null) {
        await _saveReportSnapshot(prefs, result.otherWorks);
        return;
      }

      final snapshot = Map<String, String>.from(
        jsonDecode(raw) as Map,
      );

      for (final work in result.otherWorks) {
        final prev = snapshot[work.fileId];
        final curr = work.status.name;
        if (prev == ReportWorkStatus.pending.name && curr != prev) {
          if (work.status == ReportWorkStatus.accepted) {
            await _show(
              '🎉 Ура, приняли!',
              '«${work.title}» — зачтено, можно выдохнуть',
              _chReports,
              'Отчётные работы',
            );
          } else if (work.status == ReportWorkStatus.rejected) {
            await _show(
              '😬 Надо доработать',
              '«${work.title}» — вернули на правки',
              _chReports,
              'Отчётные работы',
            );
          }
        }
      }

      await _saveReportSnapshot(prefs, result.otherWorks);
    } catch (_) {}
  }

  Future<void> _saveReportSnapshot(
      SharedPreferences prefs, List<ReportWork> works) async {
    final map = {for (final w in works) w.fileId: w.status.name};
    await prefs.setString(_keyReportSnapshot, jsonEncode(map));
  }

  /// Проверяет появление новых оценок.
  Future<void> checkGrades(LkController lk) async {
    try {
      final api = lk.gradesApi;
      final record = await api.readCache();
      if (record == null) return;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyGradesSnapshot);

      if (raw == null) {
        await _saveGradesSnapshot(prefs, record.panels
            .map((p) => MapEntry(p.number, _gradeCount(p)))
            .toList());
        return;
      }

      final snapshot = Map<String, int>.from(
        (jsonDecode(raw) as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      );

      for (final panel in record.panels) {
        final prev = snapshot[panel.number.toString()];
        final curr = _gradeCount(panel);
        if (prev != null && curr > prev) {
          await _show(
            '👀 Смотри, оценки пришли',
            '${panel.number} семестр — загляни, пока не поздно',
            _chGrades,
            'Оценки',
          );
        }
      }

      await _saveGradesSnapshot(prefs,
          record.panels.map((p) => MapEntry(p.number, _gradeCount(p))).toList());
    } catch (_) {}
  }

  int _gradeCount(SemesterPanel panel) =>
      panel.sections.expand((s) => s.grades).length;

  Future<void> _saveGradesSnapshot(
      SharedPreferences prefs, List<MapEntry<int, int>> entries) async {
    final map = {for (final e in entries) '${e.key}': e.value};
    await prefs.setString(_keyGradesSnapshot, jsonEncode(map));
  }

  // ─────────────────────── test methods ───────────────────────

  Future<void> testTask() => _show(
        '📚 Вставай, есть задание!',
        'Математика: +1 — само себя не сделает',
        _chTasks,
        'Контактная работа',
      );

  Future<void> testReportAccepted() => _show(
        '🎉 Ура, приняли!',
        '«Лабораторная работа №3» — зачтено, можно выдохнуть',
        _chReports,
        'Отчётные работы',
      );

  Future<void> testReportRejected() => _show(
        '😬 Надо доработать',
        '«Курсовая работа» — вернули на правки',
        _chReports,
        'Отчётные работы',
      );

  Future<void> testGrade() => _show(
        '👀 Смотри, оценки пришли',
        '6 семестр — загляни, пока не поздно',
        _chGrades,
        'Оценки',
      );
}
