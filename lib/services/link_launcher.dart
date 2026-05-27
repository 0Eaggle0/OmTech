import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Открывает ссылку во внешнем браузере, показывает SnackBar при ошибке.
Future<void> openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.tryParse(url);
  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Не удалось открыть ссылку')),
    );
  }
}
