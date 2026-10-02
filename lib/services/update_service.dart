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
  static const repo = '0Eaggle0/campus2_0';
  static const _skippedKey = 'update_skipped_version';

  /// Новый релиз или null: не Android, нет сети, нет APK, версия не новее
  /// или пользователь уже отказался от именно этой версии.
  static Future<AppRelease?> checkLatest() async {
    if (!Platform.isAndroid) return null;
    try {
      final r = await Dio().get<Map<String, dynamic>>(
        'https://api.github.com/repos/$repo/releases/latest',
      );
      final data = r.data!;
      final version = (data['tag_name'] as String).replaceFirst('v', '');
      if (!isNewer(version, kAppVersion)) return null;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_skippedKey) == version) return null;

      final apk = (data['assets'] as List).cast<Map<String, dynamic>>().where(
            (a) => (a['name'] as String).endsWith('.apk'),
          );
      if (apk.isEmpty) return null;
      return AppRelease(version, apk.first['browser_download_url'] as String);
    } catch (e) {
      debugPrint('[Update] check failed: $e');
      return null;
    }
  }

  static Future<void> skip(AppRelease release) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedKey, release.version);
  }

  /// Качает APK в нашу временную папку и отдаёт системному установщику.
  static Future<void> downloadAndInstall(AppRelease release) async {
    final dir = await lkFilesDir();
    await dir.create(recursive: true);
    final path = '${dir.path}${Platform.pathSeparator}omtech-update.apk';
    await Dio().download(release.apkUrl, path);
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
  const AppRelease(this.version, this.apkUrl);
}
