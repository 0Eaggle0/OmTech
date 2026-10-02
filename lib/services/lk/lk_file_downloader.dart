import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/contact_work.dart';
import '../link_launcher.dart';
import 'lk_session.dart';

/// Скачивает файл через активную сессию ЛК (cookie-jar уже подкинут
/// к запросу) во временную папку и открывает его в системном просмотрщике.
/// Если сессии нет — открывает URL во внешнем браузере.
Future<void> openWorkFile(
  BuildContext context,
  LkSession? session,
  WorkFile file,
) async {
  // Демо-режим — ссылка не авторизованная, открываем в браузере.
  if (session == null) {
    await openExternal(context, file.url);
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DownloadProgressDialog(),
  );

  try {
    final path = await _downloadToTemp(session, file);

    if (navigator.canPop()) navigator.pop();

    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      // Фолбэк: системное меню «Поделиться» — пользователь сможет
      // выбрать любое приложение, способное открыть файл.
      await Share.shareXFiles([XFile(path)]);
    }
  } catch (e) {
    if (navigator.canPop()) navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Не удалось скачать файл: $e')),
    );
  }
}

/// Скачивает файл во временную папку и открывает системный диалог
/// «Save As…», в котором пользователь сам выбирает место (Downloads,
/// SD-карта, iCloud Drive и т.д.). После сохранения файл становится
/// виден в системном файловом менеджере.
Future<void> saveWorkFile(
  BuildContext context,
  LkSession? session,
  WorkFile file,
) async {
  if (session == null) {
    await openExternal(context, file.url);
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DownloadProgressDialog(),
  );

  try {
    final path = await _downloadToTemp(session, file);
    if (navigator.canPop()) navigator.pop();

    final savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: path,
        fileName: _safeFileName(file.name),
      ),
    );

    if (savedPath == null) return; // пользователь отменил
    messenger.showSnackBar(
      SnackBar(content: Text('Сохранено: ${_displayPath(savedPath)}')),
    );
  } catch (e) {
    if (navigator.canPop()) navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Не удалось сохранить файл: $e')),
    );
  }
}

/// Скачанные из ЛК файлы держим в своей подпапке временной папки: так их
/// можно стереть целиком при очистке кэша, не задев чужие файлы (например
/// PDF, скопированный туда системным диалогом выбора файла).
const lkFilesDirName = 'lk_files';

Future<Directory> lkFilesDir() async {
  final dir = await getTemporaryDirectory();
  return Directory('${dir.path}${Platform.pathSeparator}$lkFilesDirName');
}

Future<String> _downloadToTemp(LkSession session, WorkFile file) async {
  // Referer подбираем под хост: для /ecab/-файлов — vkr2.php, иначе
  // — портал зачётки. Если хост не угадан, передаём null — downloadBytes
  // подставит дефолт самостоятельно.
  String? referer;
  if (file.url.contains('omgtu.ru/ecab/')) {
    referer = 'https://omgtu.ru/ecab/vkr2.php';
  } else if (file.url.contains('up.omgtu.ru')) {
    referer = 'https://up.omgtu.ru/index.php?r=remote/read';
  }
  final bytes = await session.downloadBytes(file.url, referer: referer);
  final dir = await lkFilesDir();
  await dir.create(recursive: true);
  final safeName = _safeFileName(file.name);
  final path = '${dir.path}${Platform.pathSeparator}$safeName';
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}

String _safeFileName(String name) {
  return name.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();
}

String _displayPath(String path) {
  // На Android FlutterFileDialog возвращает либо абсолютный путь,
  // либо `content://`-URI. Показываем хвост — для пользователя
  // содержательнее «Download/foo.pdf», чем длинный content-URI.
  final cleaned = path.replaceAll('\\', '/');
  final segs = cleaned.split('/').where((s) => s.isNotEmpty).toList();
  if (segs.length <= 2) return path;
  return segs.sublist(segs.length - 2).join('/');
}

class _DownloadProgressDialog extends StatelessWidget {
  const _DownloadProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 14),
            Text(
              'Скачивание…',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
