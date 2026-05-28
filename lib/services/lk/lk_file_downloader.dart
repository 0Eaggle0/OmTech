import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/contact_work.dart';
import '../link_launcher.dart';
import 'lk_session.dart';

/// Скачивает файл с up.omgtu.ru через активную сессию ЛК (cookie-jar
/// уже подкинут к запросу) во временную папку и открывает его в системном
/// просмотрщике. Если сессии нет — открывает URL во внешнем браузере.
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

  // Неблокирующий диалог с прогрессом.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DownloadProgressDialog(),
  );

  try {
    final bytes = await session.downloadBytes(
      file.url,
      referer: 'https://up.omgtu.ru/index.php?r=remote/read',
    );

    final dir = await getTemporaryDirectory();
    final safeName = _safeFileName(file.name);
    final path = '${dir.path}${Platform.pathSeparator}$safeName';
    await File(path).writeAsBytes(bytes, flush: true);

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

String _safeFileName(String name) {
  return name.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();
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
