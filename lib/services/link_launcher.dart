import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Схемы, которые приложению есть смысл открывать. Ссылки приходят из чужого
/// HTML (новости, задания, файлы ЛК), поэтому запускаем не всё подряд:
/// `intent:`, `javascript:` и прочее сюда не попадают.
const _allowedSchemes = {'https', 'http', 'mailto', 'tel'};

/// Открывает ссылку во внешнем браузере, показывает SnackBar при ошибке.
Future<void> openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !_allowedSchemes.contains(uri.scheme.toLowerCase()) ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Не удалось открыть ссылку')),
    );
  }
}
