import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../controllers/lk_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/link_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';
import 'status_banners.dart';

/// Шторка входа в ЛК. Возвращает `true` при успешном логине, иначе
/// `false`/`null` — пользователь отменил или пропустил.
///
/// При `allowSkip` (первый запуск) это ещё и онбординг: градиентная шапка
/// с объяснением, зачем нужен вход, и конфетти при успехе — отдельного
/// приветственного экрана перед формой больше нет.
class LkLoginSheet extends StatefulWidget {
  /// Показывать ли «Пропустить» — только в сценарии первого запуска,
  /// где обойтись без ЛК — осознанный выбор, а не исключение.
  final bool allowSkip;

  const LkLoginSheet({super.key, this.allowSkip = false});

  static Future<bool?> show(BuildContext context, {bool allowSkip = false}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // В онбординге шапка градиентная и должна доходить до края шторки —
      // отсюда прозрачный фон и своя обрезка вместо ручки перетаскивания.
      showDragHandle: !allowSkip,
      backgroundColor: allowSkip ? Colors.transparent : null,
      builder: (_) => LkLoginSheet(allowSkip: allowSkip),
    );
  }

  @override
  State<LkLoginSheet> createState() => _LkLoginSheetState();
}

class _LkLoginSheetState extends State<LkLoginSheet> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  late final ConfettiController _confetti;
  bool _busy = false;
  bool _obscure = true;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confetti.dispose();
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
      // Первый запуск — празднуем: конфетти и только потом закрываем.
      if (widget.allowSkip) {
        setState(() {
          _busy = false;
          _success = true;
        });
        _confetti.play();
        await Future.delayed(const Duration(milliseconds: 1600));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _busy = false;
        _error = lk.errorMessage ?? AppLocalizations.of(context)!.lkNetworkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          child: ColoredBox(
            color: theme.colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.allowSkip) _gradientHeader(context),
                Flexible(child: _form(context)),
              ],
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          gravity: 0.12,
          emissionFrequency: 0.05,
          colors: const [
            AppColors.violet,
            AppColors.indigo,
            Color(0xFFFFD700),
            Color(0xFFEC4899),
            AppColors.statusInfo,
          ],
        ),
      ],
    );
  }

  /// Шапка первого запуска — объясняет, зачем вообще этот вход.
  Widget _gradientHeader(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: const BoxDecoration(gradient: AppColors.accentGradient),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            l.lkOnboardingTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.lkOnboardingMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final compact = !widget.allowSkip;

    // Скролл обязателен: при isScrollControlled шторка получает жёсткую
    // максимальную высоту, а клавиатура съедает ещё часть — без него
    // содержимое не помещается и вылезает полосатым overflow.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        compact ? 8 : 22,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
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
          ],
          Text(
            l.lkLoginHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: glass.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _fieldLabel(l.lkUsername),
          const SizedBox(height: 6),
          TextField(
            controller: _username,
            enabled: !_busy && !_success,
            decoration: InputDecoration(
              hintText: l.lkUsername,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _fieldLabel(l.lkPassword)),
              TextButton(
                onPressed: () => openExternal(context, 'https://up.omgtu.ru/'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l.lkForgotPassword),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _password,
            enabled: !_busy && !_success,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: l.lkPassword,
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
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(_error!),
          ],
          const SizedBox(height: 18),
          if (_success)
            Center(
              child: const Icon(Icons.check_circle,
                      color: AppColors.statusSuccess, size: 48)
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
            )
          else
            _submitButton(l),
          if (widget.allowSkip && !_success) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                child: Text(l.lkSkipGuest),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _privacyFooter(l, theme, glass),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    final glass = context.glass;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: glass.textMuted,
      ),
    );
  }

  /// Градиентная кнопка — тот же акцент, что у бегущей плашки переключателей.
  Widget _submitButton(AppLocalizations l) {
    final enabled = !_busy;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: context.glass.glow(AppColors.violet),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? _submit : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Center(
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.login, color: Colors.white, size: 19),
                          const SizedBox(width: 8),
                          Text(
                            l.lkLoginButton,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Куда уходят данные и почему приложению можно доверить пароль.
  Widget _privacyFooter(AppLocalizations l, ThemeData theme, AppGlass glass) {
    final style = theme.textTheme.bodySmall?.copyWith(
      color: glass.textFaint,
      height: 1.4,
    );

    Widget line(IconData icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: glass.textFaint),
            const SizedBox(width: 7),
            Expanded(child: Text(text, style: style)),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: glass.elevatedFill,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: glass.hairline),
      ),
      child: Column(
        children: [
          line(Icons.shield_outlined, l.lkSslNote),
          const SizedBox(height: 8),
          line(Icons.phonelink_lock_outlined, l.lkPrivacyNote),
        ],
      ),
    );
  }
}
