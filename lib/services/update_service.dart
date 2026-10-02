import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_version.dart';
import 'lk/lk_file_downloader.dart';

/// Обновление вне магазина: последний релиз GitHub с APK внутри. Android ставит
/// его поверх текущей версии (тот же applicationId и ключ подписи, выше
/// versionCode), поэтому данные и вход в ЛК сохраняются.
class UpdateService {
  static const repo = '0Eaggle0/OmTech';
  static const _snoozeKey = 'update_snoozed_until';

  /// Новый релиз или null: не Android, нет сети, нет APK, версия не новее
  /// или пользователь недавно нажал «Позже».
  static Future<AppRelease?> checkLatest() async {
    if (!Platform.isAndroid) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final snoozedUntil = prefs.getInt(_snoozeKey) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < snoozedUntil) return null;

      final r = await Dio().get<Map<String, dynamic>>(
        'https://api.github.com/repos/$repo/releases/latest',
      );
      final data = r.data!;
      final version = (data['tag_name'] as String).replaceFirst('v', '');
      if (!isNewer(version, kAppVersion)) return null;

      final apk = (data['assets'] as List).cast<Map<String, dynamic>>().where(
            (a) => (a['name'] as String).endsWith('.apk'),
          );
      if (apk.isEmpty) return null;
      return AppRelease(
        version,
        apk.first['browser_download_url'] as String,
        apk.first['size'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('[Update] check failed: $e');
      return null;
    }
  }

  /// «Позже» — не спрашивать сутки.
  static Future<void> snooze() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(const Duration(days: 1));
    await prefs.setInt(_snoozeKey, until.millisecondsSinceEpoch);
  }

  /// Качает APK в нашу временную папку и отдаёт системному установщику.
  static Future<void> downloadAndInstall(
    AppRelease release, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await lkFilesDir();
    await dir.create(recursive: true);
    final path = '${dir.path}${Platform.pathSeparator}omtech-update.apk';
    await Dio().download(release.apkUrl, path, onReceiveProgress: onProgress);
    final result = await OpenFilex.open(
      path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) throw Exception(result.message);
  }

  /// `1.10.0` > `1.9.3`; суффикс сборки (`+39`) не учитывается.
  static bool isNewer(String a, String b) {
    List<int> parts(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < 3; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d > 0;
    }
    return false;
  }
}

class AppRelease {
  final String version;
  final String apkUrl;

  /// Размер APK в байтах (0 — GitHub не сообщил).
  final int size;

  const AppRelease(this.version, this.apkUrl, this.size);
}
