import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_version.dart';
import '../../controllers/lk_controller.dart';
import '../../controllers/locale_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../services/cache_manager.dart';
import '../../services/news_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_glass.dart';
import '../../widgets/background_work_tile.dart';
import 'bug_report_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _cacheSize;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _measureCache();
  }

  CacheManager get _cacheManager =>
      CacheManager(newsDb: context.read<NewsService>().db);

  Future<void> _measureCache() async {
    final size = await _cacheManager.totalSize();
    if (!mounted) return;
    setState(() => _cacheSize = size);
  }

  Future<void> _confirmClearCache(AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsClearCacheTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.settingsClearCacheBody),
            const SizedBox(height: 12),
            Text(
              l.settingsClearCacheKept,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: ctx.glass.textMuted,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.settingsClearCache),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _clearing = true);
    final messenger = ScaffoldMessenger.of(context);
    await _cacheManager.clearAll(context.read<LkController>());
    if (!mounted) return;
    setState(() {
      _clearing = false;
      _cacheSize = null;
    });
    messenger.showSnackBar(SnackBar(content: Text(l.settingsCacheCleared)));
    unawaited(_measureCache());
  }

  void _showTestMenu(AppLocalizations l) {
    final service = NotificationService.instance;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (label, action) in <(String, Future<void> Function())>[
              (l.settingsNotifTestTask, service.testTask),
              (l.settingsNotifTestAccepted, service.testReportAccepted),
              (l.settingsNotifTestRejected, service.testReportRejected),
              (l.settingsNotifTestGrade, service.testGrade),
              (l.settingsNotifTestSchedule, service.testSchedule),
            ])
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(label),
                onTap: () {
                  Navigator.pop(ctx);
                  action();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final settings = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _sectionTitle(context, l.settingsLanguage),
          Card(
            child: Column(
              children: [
                _localeOption(context, localeController, const Locale('ru'), l.settingsLangRu, '🇷🇺'),
                const Divider(height: 1),
                _localeOption(context, localeController, const Locale('en'), l.settingsLangEn, '🇬🇧'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, l.settingsTheme),
          Card(
            child: Column(
              children: [
                _themeOption(context, themeController, ThemeMode.dark, l.settingsThemeDark, Icons.dark_mode_outlined),
                const Divider(height: 1),
                _themeOption(context, themeController, ThemeMode.light, l.settingsThemeLight, Icons.light_mode_outlined),
                const Divider(height: 1),
                _themeOption(context, themeController, ThemeMode.system, l.settingsThemeSystem, Icons.brightness_auto_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, l.settingsNotifications),
          Card(
            child: Column(
              children: [
                _notifSwitch(settings, NotifCategory.tasks,
                    l.settingsNotifTasks, l.settingsNotifTasksHint),
                const Divider(height: 1),
                _notifSwitch(settings, NotifCategory.reports,
                    l.settingsNotifReports, l.settingsNotifReportsHint),
                const Divider(height: 1),
                _notifSwitch(settings, NotifCategory.grades,
                    l.settingsNotifGrades, l.settingsNotifGradesHint),
                const Divider(height: 1),
                _notifSwitch(settings, NotifCategory.schedule,
                    l.settingsNotifSchedule, l.settingsNotifScheduleHint),
                const Divider(height: 1),
                const BackgroundWorkTile(),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_none_outlined),
                  title: Text(l.settingsNotifTest),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showTestMenu(l),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, l.settingsData),
          Card(
            child: ListTile(
              leading: _clearing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cleaning_services_outlined),
              title: Text(l.settingsClearCache),
              subtitle: Text(_cacheSize == null
                  ? l.settingsCacheCounting
                  : l.settingsCacheSize(CacheManager.formatBytes(_cacheSize!))),
              trailing: const Icon(Icons.chevron_right),
              onTap: _clearing ? null : () => _confirmClearCache(l),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, l.settingsAbout),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: context.glass.accentGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 22),
                  ),
                  title: Text(l.settingsAboutApp),
                  subtitle: Text('${l.settingsVersion} $kAppVersionLabel · ${l.profileBuildBy}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(l.bugReportAction),
                  subtitle: Text(l.bugReportSettingsHint),
                  trailing: const Icon(Icons.chevron_right),
                  // Снимок самих настроек разработчику ничего не скажет.
                  onTap: () => BugReportSheet.show(context, captureScreen: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifSwitch(
      SettingsController settings, NotifCategory category, String label, String hint) {
    return SwitchListTile(
      value: settings.isEnabled(category),
      onChanged: (v) => settings.setEnabled(category, v),
      title: Text(label),
      subtitle: Text(hint),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.glass.textMuted,
            ),
      ),
    );
  }

  Widget _localeOption(BuildContext context, LocaleController controller, Locale locale, String label, String flag) {
    final selected = controller.locale.languageCode == locale.languageCode;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: () => controller.setLocale(locale),
    );
  }

  Widget _themeOption(BuildContext context, ThemeController controller, ThemeMode mode, String label, IconData icon) {
    final selected = controller.mode == mode;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: () => controller.setMode(mode),
    );
  }
}
