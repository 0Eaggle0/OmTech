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
import '../../models/group.dart';
import '../../models/schedule_entity.dart';
import '../../models/student_record.dart';
import '../../services/avatar_store.dart';
import '../../services/link_launcher.dart';
import '../../theme/app_glass.dart';
import '../../theme/app_metrics.dart';
import '../../widgets/accent_bar.dart';
import '../../widgets/lk_login_sheet.dart';
import '../../widgets/sliding_toggle.dart';
import '../../widgets/status_pill.dart';
import '../search/search_screen.dart';
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
  static const _avatarKey = AvatarStore.key;

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

  Future<String?> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return _avatarPath;
    final dir = await getApplicationDocumentsDirectory();
    // Новое имя на каждый выбор: по старому пути `FileImage` отдал бы
    // закэшированную картинку прежнего фото.
    final dest = File(p.join(dir.path,
        'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}'));
    await File(picked.path).copy(dest.path);
    await _deleteAvatarFile(_avatarPath);
    await AvatarStore.set(dest.path);
    if (mounted) setState(() => _avatarPath = dest.path);
    return dest.path;
  }

  Future<void> _removeAvatar() async {
    final path = _avatarPath;
    await AvatarStore.set(null);
    await _deleteAvatarFile(path);
    if (mounted) setState(() => _avatarPath = null);
  }

  Future<void> _deleteAvatarFile(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  void _showEditProfileSheet(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(
        lastName: _lastName,
        firstName: _firstName,
        patronymic: _patronymic,
        avatarPath: _avatarPath,
        onSave: _saveName,
        onPickAvatar: _pickAvatar,
        onRemoveAvatar: _removeAvatar,
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
    final glass = context.glass;
    final inner = (file != null && file.existsSync())
        ? CircleAvatar(radius: radius, backgroundImage: FileImage(file))
        : CircleAvatar(
            radius: radius,
            backgroundColor: glass.tint(theme.colorScheme.primary),
            child: Text(
              _firstName.isNotEmpty
                  ? _firstName[0].toUpperCase()
                  : _lastName.isNotEmpty
                      ? _lastName[0].toUpperCase()
                      : '?',
              style: TextStyle(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          );
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.55)),
      ),
      child: inner,
    );
  }

  Future<void> _changeGroup() async {
    final entity = await SearchScreen.pick(context, EntityType.group);
    if (entity != null && mounted) {
      await context.read<GroupController>().select(Group(
            id: entity.id,
            label: entity.label,
            description: entity.description,
          ));
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
        padding: EdgeInsets.fromLTRB(16, 8, 16, navBottomPadding(context)),
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
                        color: context.glass.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.profileSubgroupHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.glass.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SlidingToggle(
                      items: [
                        SlidingToggleItem(label: l.profileSubgroupAll),
                        const SlidingToggleItem(label: '1'),
                        const SlidingToggleItem(label: '2'),
                      ],
                      selected: switch (groupCtrl.subgroup) { 1 => 1, 2 => 2, _ => 0 },
                      onSelected: (i) => groupCtrl.setSubgroup(i == 0 ? null : i),
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
          _servicesGrid(context, l),
          const SizedBox(height: 20),
          _footer(context, l),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l, String? groupLabel) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final avatarFile = _avatarPath != null ? File(_avatarPath!) : null;
    final displayName = _displayName.isNotEmpty ? _displayName : l.profileNameHint;
    final specialty = context.watch<LkController>().profile?.specialty ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showAvatarPickerMenu(context, l,
              onPick: (s) async { await _pickAvatar(s); },
              onRemove: _removeAvatar),
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
              Text(displayName, style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              if (groupLabel != null || specialty.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (groupLabel != null)
                      StatusPill(groupLabel, status: AppStatus.accent, dense: true),
                    if (specialty.isNotEmpty)
                      StatusPill(specialty, color: glass.textMuted, filled: false, dense: true),
                  ],
                ),
              const SizedBox(height: 6),
              Text(
                l.profileUniversity,
                style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
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
    final glass = context.glass;

    if (lk.isConnected) {
      final profile = lk.profile;
      final accent = glass.statusColor(AppStatus.success);
      final shape = BorderRadius.circular(AppRadius.card);
      return Material(
        color: glass.cardFill,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0, child: AccentBar(accent)),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: glass.tint(accent),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(Icons.verified_user_outlined, color: accent),
                    ),
                    title: Text(profile?.fullName.isNotEmpty == true
                        ? profile!.fullName
                        : l.lkConnected),
                    subtitle: profile == null ? null : Text(_lkSubtitle(l, profile)),
                    isThreeLine: profile != null,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout_outlined, color: theme.colorScheme.error),
                    title: Text(
                      l.lkDisconnect,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () => _confirmDisconnect(l, lk),
                  ),
                ],
              ),
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
                  final ok = await LkLoginSheet.show(context);
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
          color: context.glass.textMuted,
        ),
      ),
    );
  }

  Widget _servicesGrid(BuildContext context, AppLocalizations l) {
    final glass = context.glass;
    final items = [
      (Icons.public, l.profileSiteOmgtu, 'https://www.omgtu.ru/', glass.accent),
      (Icons.calendar_month_outlined, l.profileSiteSchedule,
          'https://rasp.omgtu.ru/ruz/main', glass.statusColor(AppStatus.info)),
      (Icons.newspaper_outlined, l.profileSiteNews, 'https://www.omgtu.ru/news/',
          glass.statusColor(AppStatus.warning)),
      (Icons.dashboard_outlined, l.profileSitePortal, 'https://up.omgtu.ru/',
          glass.statusColor(AppStatus.success)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        for (final (icon, label, url, color) in items)
          _serviceTile(context, icon, label, url, color),
      ],
    );
  }

  Widget _serviceTile(
      BuildContext context, IconData icon, String label, String url, Color color) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final shape = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: shape, boxShadow: glass.glow(color)),
      child: Material(
        color: glass.cardFill,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openExternal(context, url),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: glass.tint(color),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l) {
    final glass = context.glass;
    return Center(
      child: Text(
        '${l.appTitle} · ${l.profileBuildBy}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: glass.textFaint),
      ),
    );
  }
}

/// Шторка редактирования ФИО и аватара — отдельный виджет со своим `State`,
/// чтобы контроллеры полей корректно диспозились (раньше их создавал builder
/// без владельца, и они утекали при каждом открытии шторки).
class _EditProfileSheet extends StatefulWidget {
  final String lastName;
  final String firstName;
  final String patronymic;
  final String? avatarPath;
  final void Function(String lastName, String firstName, String patronymic) onSave;
  final Future<String?> Function(ImageSource) onPickAvatar;
  final Future<void> Function() onRemoveAvatar;

  const _EditProfileSheet({
    required this.lastName,
    required this.firstName,
    required this.patronymic,
    required this.avatarPath,
    required this.onSave,
    required this.onPickAvatar,
    required this.onRemoveAvatar,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _lastCtrl = TextEditingController(text: widget.lastName);
  late final _firstCtrl = TextEditingController(text: widget.firstName);
  late final _patronymicCtrl = TextEditingController(text: widget.patronymic);
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _avatarPath = widget.avatarPath;
  }

  @override
  void dispose() {
    _lastCtrl.dispose();
    _firstCtrl.dispose();
    _patronymicCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final path = await widget.onPickAvatar(source);
    if (mounted) setState(() => _avatarPath = path);
  }

  Future<void> _remove() async {
    await widget.onRemoveAvatar();
    if (mounted) setState(() => _avatarPath = null);
  }

  void _showAvatarMenu(AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.profilePhotoGallery),
              onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.profilePhotoCamera),
              onTap: () { Navigator.pop(context); _pick(ImageSource.camera); },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text(l.profilePhotoRemove,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () { Navigator.pop(context); _remove(); },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final file = _avatarPath != null ? File(_avatarPath!) : null;
    final inner = (file != null && file.existsSync())
        ? CircleAvatar(radius: 52, backgroundImage: FileImage(file))
        : CircleAvatar(
            radius: 52,
            backgroundColor: glass.tint(theme.colorScheme.primary),
            child: Text(
              _firstCtrl.text.isNotEmpty
                  ? _firstCtrl.text[0].toUpperCase()
                  : _lastCtrl.text.isNotEmpty
                      ? _lastCtrl.text[0].toUpperCase()
                      : '?',
              style: TextStyle(
                  fontSize: 39, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
            ),
          );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.55)),
      ),
      child: inner,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.profileEditTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => _showAvatarMenu(l),
                child: Stack(
                  children: [
                    _avatar(context),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
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
              controller: _lastCtrl,
              decoration: InputDecoration(labelText: l.profileLastName),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firstCtrl,
              decoration: InputDecoration(labelText: l.profileFirstName),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _patronymicCtrl,
              decoration: InputDecoration(labelText: l.profilePatronymic),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                widget.onSave(
                  _lastCtrl.text.trim(),
                  _firstCtrl.text.trim(),
                  _patronymicCtrl.text.trim(),
                );
                Navigator.pop(context);
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
