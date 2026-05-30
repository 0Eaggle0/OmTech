import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/group_controller.dart';
import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/student_record.dart';
import '../../services/link_launcher.dart';
import '../../widgets/group_search_sheet.dart';
import '../../widgets/lk_login_dialog.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _firstNameKey = 'user_first_name';
  static const _lastNameKey = 'user_last_name';
  static const _patronymicKey = 'user_patronymic';
  static const _legacyNameKey = 'user_name';
  static const _avatarKey = 'user_avatar_path';

  String _firstName = '';
  String _lastName = '';
  String _patronymic = '';
  String? _avatarPath;
  LkStatus? _lastLkStatus;

  String get _displayName {
    final parts = [_lastName, _firstName, _patronymic]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : '';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lk = context.watch<LkController>();
    if (_lastLkStatus != lk.status) {
      _lastLkStatus = lk.status;
      if (lk.isConnected && _firstName.isEmpty && _lastName.isEmpty) {
        _loadProfile();
      }
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarPath = prefs.getString(_avatarKey);

    // Новый формат: три отдельных поля.
    final fn = prefs.getString(_firstNameKey) ?? '';
    final ln = prefs.getString(_lastNameKey) ?? '';
    final pt = prefs.getString(_patronymicKey) ?? '';

    if (fn.isNotEmpty || ln.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _firstName = fn;
        _lastName = ln;
        _patronymic = pt;
        _avatarPath = avatarPath;
      });
      return;
    }

    // Легаси: user_name — попробуем разбить и авто-мигрировать в новые ключи.
    final legacy = prefs.getString(_legacyNameKey) ?? '';
    if (legacy.isNotEmpty) {
      final parts = legacy.trim().split(' ');
      final ln = parts.isNotEmpty ? parts[0] : '';
      final fn = parts.length >= 2 ? parts[1] : '';
      final pt = parts.length >= 3 ? parts.sublist(2).join(' ') : '';
      // Сохраняем в новые ключи сразу, не ждём нажатия «Сохранить».
      await prefs.setString(_lastNameKey, ln);
      await prefs.setString(_firstNameKey, fn);
      await prefs.setString(_patronymicKey, pt);
      if (!mounted) return;
      setState(() {
        _lastName = ln;
        _firstName = fn;
        _patronymic = pt;
        _avatarPath = avatarPath;
      });
      return;
    }

    // Нет сохранённого — пробуем из ЛК.
    if (!mounted) return;
    final lk = context.read<LkController>();
    final lkName = lk.profile?.fullName ?? '';
    if (lkName.isNotEmpty) {
      final parts = lkName.trim().split(' ');
      if (!mounted) return;
      setState(() {
        _lastName = parts.isNotEmpty ? parts[0] : '';
        _firstName = parts.length >= 2 ? parts[1] : '';
        _patronymic = parts.length >= 3 ? parts.sublist(2).join(' ') : '';
        _avatarPath = avatarPath;
      });
    } else if (!mounted) {
      return;
    } else {
      setState(() { _avatarPath = avatarPath; });
    }
  }

  Future<void> _saveName(String lastName, String firstName, String patronymic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNameKey, lastName);
    await prefs.setString(_firstNameKey, firstName);
    await prefs.setString(_patronymicKey, patronymic);
    // Обновляем legacy-ключ для совместимости с дашбордом.
    final full = [lastName, firstName, patronymic]
        .where((s) => s.isNotEmpty)
        .join(' ');
    await prefs.setString(_legacyNameKey, full);
    if (mounted) {
      setState(() {
        _lastName = lastName;
        _firstName = firstName;
        _patronymic = patronymic;
      });
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = File(p.join(dir.path, 'avatar${p.extension(picked.path)}'));
    await File(picked.path).copy(dest.path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, dest.path);
    if (mounted) setState(() => _avatarPath = dest.path);
  }

  Future<void> _removeAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarKey);
    if (mounted) setState(() => _avatarPath = null);
  }

  void _showEditProfileSheet(BuildContext context, AppLocalizations l) {
    final lastCtrl = TextEditingController(text: _lastName);
    final firstCtrl = TextEditingController(text: _firstName);
    final patronymicCtrl = TextEditingController(text: _patronymic);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final avatarFile = _avatarPath != null ? File(_avatarPath!) : null;
          return SingleChildScrollView(
            child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.profileEditTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => _showAvatarPickerMenu(ctx, l,
                        onPick: (source) async {
                      await _pickAvatar(source);
                      setSheetState(() {});
                    }, onRemove: () async {
                      await _removeAvatar();
                      setSheetState(() {});
                    }),
                    child: Stack(
                      children: [
                        _buildAvatar(avatarFile, 52),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(ctx).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: lastCtrl,
                  decoration: InputDecoration(
                    labelText: l.profileLastName,
                    hintText: 'Иванов',
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: firstCtrl,
                  decoration: InputDecoration(
                    labelText: l.profileFirstName,
                    hintText: 'Иван',
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: patronymicCtrl,
                  decoration: InputDecoration(
                    labelText: l.profilePatronymic,
                    hintText: 'Иванович',
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    _saveName(
                      lastCtrl.text.trim(),
                      firstCtrl.text.trim(),
                      patronymicCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(l.save),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  void _showAvatarPickerMenu(
    BuildContext ctx,
    AppLocalizations l, {
    required Future<void> Function(ImageSource) onPick,
    required Future<void> Function() onRemove,
  }) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.profilePhotoGallery),
              onTap: () { Navigator.pop(ctx); onPick(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.profilePhotoCamera),
              onTap: () { Navigator.pop(ctx); onPick(ImageSource.camera); },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text(l.profilePhotoRemove,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () { Navigator.pop(ctx); onRemove(); },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(File? file, double radius) {
    final theme = Theme.of(context);
    if (file != null && file.existsSync()) {
      return CircleAvatar(radius: radius, backgroundImage: FileImage(file));
    }
    final initials = _firstName.isNotEmpty
        ? _firstName[0].toUpperCase()
        : _lastName.isNotEmpty
            ? _lastName[0].toUpperCase()
            : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
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
    final groupCtrl = context.watch<GroupController>();

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
          const SizedBox(height: 8),
          // Подгруппа — показывается только если группа выбрана.
          if (group != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.profileSubgroup,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.profileSubgroupHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<int?>(
                      style: SegmentedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      segments: [
                        ButtonSegment<int?>(value: null, label: Text(l.profileSubgroupAll)),
                        const ButtonSegment<int?>(value: 1, label: Text('1')),
                        const ButtonSegment<int?>(value: 2, label: Text('2')),
                      ],
                      selected: {groupCtrl.subgroup},
                      onSelectionChanged: (s) => groupCtrl.setSubgroup(s.first),
                      showSelectedIcon: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          _sectionTitle(context, l.lkSection),
          _lkCard(context, l),
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
    final avatarFile = _avatarPath != null ? File(_avatarPath!) : null;
    final displayName = _displayName.isNotEmpty ? _displayName : l.profileNameHint;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showAvatarPickerMenu(context, l,
              onPick: _pickAvatar, onRemove: _removeAvatar),
          child: Stack(
            children: [
              _buildAvatar(avatarFile, 36),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                  ),
                  child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                ),
              ),
            ],
          ),
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showEditProfileSheet(context, l),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l.profileEditTitle),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lkCard(BuildContext context, AppLocalizations l) {
    final lk = context.watch<LkController>();
    final theme = Theme.of(context);

    if (lk.isConnected) {
      final profile = lk.profile;
      return Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary),
              title: Text(profile?.fullName.isNotEmpty == true
                  ? profile!.fullName
                  : l.lkConnected),
              subtitle: profile == null ? null : Text(_lkSubtitle(l, profile)),
              isThreeLine: profile != null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: Text(l.lkDisconnect),
              onTap: () => _confirmDisconnect(l, lk),
            ),
          ],
        ),
      );
    }

    final connecting = lk.status == LkStatus.connecting;
    return Card(
      child: ListTile(
        leading: connecting
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.login_outlined),
        title: Text(l.lkNotConnected),
        subtitle: Text(lk.errorMessage ?? l.lkLoginHint),
        trailing: TextButton(
          onPressed: connecting
              ? null
              : () async {
                  final ok = await LkLoginDialog.show(context);
                  if (ok == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.lkConnected)),
                    );
                    _loadProfile();
                    // Автозаполнение группы после логина.
                    if (context.mounted) {
                      context.read<LkController>().autoFillGroupIfNeeded(
                        context.read<GroupController>(),
                      );
                    }
                  }
                },
          child: Text(l.lkConnect),
        ),
      ),
    );
  }

  String _lkSubtitle(AppLocalizations l, StudentProfile profile) {
    final parts = <String>[];
    if (profile.groupLabel.isNotEmpty) parts.add(profile.groupLabel);
    if (profile.bookNumber.isNotEmpty) {
      parts.add('${l.lkBookNumber} ${profile.bookNumber}');
    }
    return parts.join(' · ');
  }

  Future<void> _confirmDisconnect(AppLocalizations l, LkController lk) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.lkDisconnectConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.lkDisconnect),
          ),
        ],
      ),
    );
    if (ok == true) {
      await lk.logout();
      if (mounted) _loadProfile();
    }
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
