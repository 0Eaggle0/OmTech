import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/background_worker.dart';
import '../services/battery_optimization.dart';
import '../theme/app_glass.dart';

/// Пункт настроек «Фоновая работа»: разрешена ли она системой и когда
/// фоновая проверка ЛК последний раз отработала.
class BackgroundWorkTile extends StatefulWidget {
  const BackgroundWorkTile({super.key});

  @override
  State<BackgroundWorkTile> createState() => _BackgroundWorkTileState();
}

class _BackgroundWorkTileState extends State<BackgroundWorkTile> {
  late final AppLifecycleListener _lifecycle;
  bool? _allowed;
  DateTime? _lastRun;
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Системный диалог уводит приложение в фон — итог видно по возврату.
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final allowed = await BatteryOptimization.isIgnoring();
    final prefs = await SharedPreferences.getInstance();
    // Время прогона пишет фоновый изолят — кэш prefs UI о нём не знает.
    await prefs.reload();
    final ms = prefs.getInt(bgLastRunKey);
    if (!mounted) return;
    setState(() {
      _allowed = allowed;
      _lastRun = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      _lastResult = prefs.getString(bgLastResultKey);
    });
  }

  static String _resultLabel(AppLocalizations l, String? result) =>
      switch (result) {
        'ok' => l.bgResultOk,
        'ui_active' => l.bgResultUiActive,
        'no_creds' => l.bgResultNoCreds,
        'auth_failed' => l.bgResultAuthFailed,
        'network' => l.bgResultNetwork,
        _ => l.bgResultError,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final allowed = _allowed;
    final lastRun = _lastRun;
    final runLine = lastRun == null
        ? l.settingsBackgroundNever
        : l.settingsBackgroundLastRun(
            DateFormat('d MMM, HH:mm', Localizations.localeOf(context).languageCode)
                .format(lastRun),
            _resultLabel(l, _lastResult),
          );

    return ListTile(
      leading: Icon(
        allowed == false ? Icons.battery_alert_outlined : Icons.sync_outlined,
        color: allowed == false ? theme.colorScheme.error : null,
      ),
      title: Text(l.settingsBackground),
      subtitle: Text(
        [
          if (allowed != null)
            allowed ? l.settingsBackgroundAllowed : l.settingsBackgroundRestricted,
          runLine,
        ].join('\n'),
        style: theme.textTheme.bodySmall?.copyWith(color: context.glass.textMuted),
      ),
      isThreeLine: allowed != null,
      trailing: allowed == false
          ? TextButton(
              onPressed: BatteryOptimization.request,
              child: Text(l.settingsBackgroundAllow),
            )
          : null,
    );
  }
}

/// Одноразовая подсказка после ручного входа в ЛК: без исключения из
/// оптимизации батареи фоновые уведомления на многих прошивках не работают.
Future<void> showBatteryHintIfNeeded(BuildContext context) async {
  if (!await BatteryOptimization.shouldShowHint()) return;
  await BatteryOptimization.markHintShown();
  if (!context.mounted) return;
  final l = AppLocalizations.of(context)!;
  final allow = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.batteryHintTitle,
                      style: Theme.of(ctx).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.batteryHintBody),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l.batteryHintLater),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l.settingsBackgroundAllow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (allow == true) unawaited(BatteryOptimization.request());
}
