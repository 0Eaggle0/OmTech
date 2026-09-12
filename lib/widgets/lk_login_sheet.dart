import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/lk_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/link_launcher.dart';
import '../theme/app_glass.dart';

/// Шторка входа в ЛК. Возвращает `true` при успешном логине, иначе
/// `false`/`null` — пользователь отменил или пропустил.
class LkLoginSheet extends StatefulWidget {
  /// Показывать ли «Пропустить» — только в сценарии первого запуска,
  /// где обойтись без ЛК — осознанный выбор, а не исключение.
  final bool allowSkip;

  const LkLoginSheet({super.key, this.allowSkip = false});

  static Future<bool?> show(BuildContext context, {bool allowSkip = false}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => LkLoginSheet(allowSkip: allowSkip),
    );
  }

  @override
  State<LkLoginSheet> createState() => _LkLoginSheetState();
}

class _LkLoginSheetState extends State<LkLoginSheet> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final lk = context.read<LkController>();
    final ok = await lk.login(username, password);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = lk.errorMessage ?? AppLocalizations.of(context)!.lkNetworkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: glass.tint(theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 14),
          Text(l.lkLoginTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            l.lkLoginSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
          ),
          const SizedBox(height: 14),
          Text(
            l.lkLoginHint,
            style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _username,
            autofocus: true,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: l.lkUsername,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l.lkPassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => openExternal(context, 'https://up.omgtu.ru/'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l.lkForgotPassword),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.lkLoginButton),
            ),
          ),
          if (widget.allowSkip) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                child: Text(l.lkSkipGuest),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 13, color: glass.textFaint),
                const SizedBox(width: 5),
                Text(
                  l.lkSslNote,
                  style: theme.textTheme.bodySmall?.copyWith(color: glass.textFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
