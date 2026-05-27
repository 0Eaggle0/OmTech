import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/group_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../services/link_launcher.dart';
import '../../widgets/group_search_sheet.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _nameKey = 'user_name';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString(_nameKey) ?? '');
  }

  Future<void> _editName() async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.profileNameEdit),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.profileNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _userName = result);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, result);
    }
  }

  Future<void> _changeGroup() async {
    final group = await GroupSearchSheet.show(context);
    if (group != null && mounted) {
      await context.read<GroupController>().select(group);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final group = context.watch<GroupController>().group;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.profileSettings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _header(context, l, group?.label),
          const SizedBox(height: 20),
          _sectionTitle(context, l.profileGroup),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(group?.label ?? l.profileGroupNotSelected),
              subtitle: group != null && group.description.isNotEmpty
                  ? Text(group.description)
                  : Text(l.profileGroupTap),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changeGroup,
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, l.profileServices),
          Card(
            child: Column(
              children: [
                _link(context, Icons.public, l.profileSiteOmgtu, 'https://www.omgtu.ru/'),
                const Divider(height: 1),
                _link(context, Icons.calendar_month_outlined, l.profileSiteSchedule, 'https://rasp.omgtu.ru/ruz/main'),
                const Divider(height: 1),
                _link(context, Icons.newspaper_outlined, l.profileSiteNews, 'https://www.omgtu.ru/news/'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l, String? groupLabel) {
    final theme = Theme.of(context);
    final displayName = _userName.isNotEmpty ? _userName : l.profileNameHint;
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _editName,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 13, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (groupLabel != null)
                Text(
                  groupLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                l.profileUniversity,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _link(BuildContext context, IconData icon, String label, String url) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => openExternal(context, url),
    );
  }
}
