import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_version.dart';
import '../controllers/group_controller.dart';
import '../controllers/lk_controller.dart';
import '../controllers/locale_controller.dart';
import '../controllers/theme_controller.dart';
import 'app_log.dart';
import 'background_worker.dart';
import 'lk/lk_report_work_api.dart';

enum BugReportDelivery { direct, email, share, failed }

/// Сборка и отправка отчёта об ошибке разработчику.
///
/// Отчёт — текстовый файл (версия, система, состояние ЛК, журнал [AppLog])
/// и по желанию HTML-дампы страниц ЛК: большинство поломок — сменившаяся
/// вёрстка сайта, и без самой страницы их не воспроизвести.
class BugReportService {
  BugReportService._();

  static const recipient = 'eaggleVlad@outlook.com';

  /// Отправка без почтового клиента: FormSubmit пересылает форму письмом
  /// на [recipient]. Первая отправка приходит не отчётом, а письмом
  /// «Activate Form» — после клика по ссылке форма заработает, а вместо
  /// адреса в URL можно подставить выданный сервисом случайный алиас.
  /// Отчёт и вложения хранятся у FormSubmit до 30 дней.
  static const _directEndpoint = 'https://formsubmit.co/ajax/$recipient';

  /// Дампы, которые [LkReportWorkApi] пишет при каждом обращении к сайту.
  static const _pageDumps = [
    'vkr2_shell',
    'otherlist',
    'upload_form',
    'upload_result',
  ];

  /// Снимок состояния приложения. Синхронно — пока `context` жив.
  static String describeState(BuildContext context) {
    final lk = context.read<LkController>();
    final groups = context.read<GroupController>();
    final theme = context.read<ThemeController>();
    final locale = context.read<LocaleController>();
    final subgroup = groups.subgroup;
    return [
      'Версия: $kAppVersionLabel ($kAppVersion+$kAppBuild)',
      'Платформа: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'Язык: ${locale.locale.languageCode}, тема: ${theme.mode.name}',
      'Группа: ${groups.group?.label ?? '—'}'
          '${subgroup == null ? '' : ', подгруппа $subgroup'}',
      'ЛК: ${lk.status.name}'
          '${lk.errorMessage == null ? '' : ' (${lk.errorMessage})'}',
    ].join('\n');
  }

  /// Отправляет отчёт напрямую (см. [_directEndpoint]). Не вышло —
  /// почтовый клиент с готовым письмом, нет клиента — «Поделиться».
  static Future<BugReportDelivery> send({
    required String state,
    required LkReportWorkApi reportApi,
    required String description,
    required bool attachPages,
    List<String> extraDumps = const [],
    List<String> screenshots = const [],
  }) async {
    final List<String> attachments;
    try {
      attachments = await _buildAttachments(
        state: state,
        reportApi: reportApi,
        description: description,
        attachPages: attachPages,
        extraDumps: extraDumps,
        screenshots: screenshots,
      );
    } catch (e) {
      debugPrint('[BugReport] не удалось собрать отчёт: $e');
      return BugReportDelivery.failed;
    }

    final subject = 'OmTech $kAppVersion: сообщение об ошибке';
    final text = description.trim();
    final body = '${text.isEmpty ? '' : '$text\n\n'}—\n$state\n'
        'Файл диагностики во вложении.';

    if (await _sendDirect(subject, body, attachments)) {
      return BugReportDelivery.direct;
    }

    try {
      await FlutterEmailSender.send(Email(
        subject: subject,
        recipients: const [recipient],
        body: body,
        attachmentPaths: attachments,
      ));
      return BugReportDelivery.email;
    } catch (e) {
      debugPrint('[BugReport] почтовый клиент недоступен: $e');
    }

    try {
      await Share.shareXFiles(
        attachments.map(XFile.new).toList(),
        subject: subject,
        text: 'Отправьте на $recipient\n\n$body',
      );
      return BugReportDelivery.share;
    } catch (e) {
      debugPrint('[BugReport] «Поделиться» недоступно: $e');
      return BugReportDelivery.failed;
    }
  }

  static Future<bool> _sendDirect(
      String subject, String body, List<String> attachments) async {
    try {
      final form = FormData.fromMap({
        '_subject': subject,
        '_captcha': 'false',
        '_template': 'box',
        'message': body,
      });
      for (var i = 0; i < attachments.length; i++) {
        form.files.add(MapEntry(
          'attachment${i + 1}',
          await MultipartFile.fromFile(attachments[i],
              filename: p.basename(attachments[i])),
        ));
      }
      final res = await Dio().post<Map<String, dynamic>>(
        _directEndpoint,
        data: form,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(seconds: 60),
          // Без Origin/Referer сервис отвечает «откройте через веб-сервер».
          headers: {
            'Accept': 'application/json',
            'Origin': 'https://github.com',
            'Referer': 'https://github.com/0Eaggle0/campus2_0',
          },
        ),
      );
      final ok = '${res.data?['success']}' == 'true';
      if (!ok) {
        debugPrint('[BugReport] прямая отправка: ${res.data?['message']}');
      }
      return ok;
    } catch (e) {
      debugPrint('[BugReport] прямая отправка не удалась: $e');
      return false;
    }
  }

  /// Когда и с каким итогом последний раз отработал фоновый воркер —
  /// главный вопрос, если «уведомления не приходят».
  static Future<String> _backgroundState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final ms = prefs.getInt(bgLastRunKey);
      if (ms == null) return 'Фон: ни разу не запускался';
      final at = DateTime.fromMillisecondsSinceEpoch(ms);
      return 'Фон: ${at.toIso8601String()} — '
          '${prefs.getString(bgLastResultKey) ?? '?'}';
    } catch (_) {
      return 'Фон: —';
    }
  }

  static Future<List<String>> _buildAttachments({
    required String state,
    required LkReportWorkApi reportApi,
    required String description,
    required bool attachPages,
    required List<String> extraDumps,
    required List<String> screenshots,
  }) async {
    final now = DateTime.now();
    final dir = await getTemporaryDirectory();
    final report = File(p.join(
      dir.path,
      'omtech_report_${DateFormat('yyyyMMdd_HHmmss').format(now)}.txt',
    ));

    final log = AppLog.lines;
    final text = description.trim();
    final buf = StringBuffer()
      ..writeln('OmTech — отчёт об ошибке')
      ..writeln('Время: ${now.toIso8601String()}')
      ..writeln(state)
      ..writeln(await _backgroundState())
      ..writeln()
      ..writeln('── Описание ──')
      ..writeln(text.isEmpty ? '(не заполнено)' : text)
      ..writeln()
      ..writeln('── Журнал (${log.length} строк) ──');
    log.forEach(buf.writeln);
    await report.writeAsString(buf.toString(), flush: true);

    final paths = [report.path];
    if (attachPages) {
      for (final name in {..._pageDumps, ...extraDumps}) {
        final path = await reportApi.lastDumpPath(name);
        if (path != null) paths.add(path);
      }
    }
    for (final shot in screenshots) {
      if (await File(shot).exists()) paths.add(shot);
    }
    return paths;
  }
}
