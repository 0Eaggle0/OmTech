import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/locale_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();

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
          _sectionTitle(context, l.settingsAbout),
          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 22),
              ),
              title: Text(l.settingsAboutApp, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${l.settingsVersion} 1.0.0'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
