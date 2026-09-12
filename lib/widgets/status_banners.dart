import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

/// «Показаны последние сохранённые данные» — единая плашка для всех экранов ЛК
/// и расписания вместо приватных `_cacheBanner`, которые были на каждом.
class CacheBanner extends StatelessWidget {
  final DateTime? updatedAt;
  final EdgeInsetsGeometry padding;

  const CacheBanner({
    super.key,
    this.updatedAt,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;

    final at = updatedAt;
    final text = at == null
        ? l.lkCacheShown
        : '${l.lkCacheShown} · ${l.scheduleCachedAt(DateFormat.Hm().format(at))}';

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(Icons.offline_pin_outlined, size: 15, color: glass.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Плашка ошибки. Без `title` — компактная строка под шапкой экрана;
/// с `title` — развёрнутый блок «сервер недоступен» с кнопкой повтора.
class ErrorBanner extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner(
    this.message, {
    super.key,
    this.title,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: error.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 18, color: error),
              const SizedBox(width: 8),
              Expanded(
                child: title == null
                    ? Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(color: error),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: error),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            message,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: error.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.close, size: 16, color: error),
                  ),
                ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(l.retry),
                style: TextButton.styleFrom(
                  foregroundColor: error,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
