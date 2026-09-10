import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/lk_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/lk/lk_credentials_storage.dart';
import '../widgets/lk_login_dialog.dart';
import 'dashboard/dashboard_screen.dart';
import 'news/news_screen.dart';
import 'profile/profile_screen.dart';
import 'schedule/schedule_screen.dart';
import 'work/work_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  static const _tabTransition = Duration(milliseconds: 260);
  static const _staticOpacity = AlwaysStoppedAnimation(1.0);
  static const _staticOffset = AlwaysStoppedAnimation(Offset.zero);

  int _index = 0;

  /// Вкладки живут в дереве и не пересоздаются при переключении, иначе
  /// каждый возврат на «Расписание» терял состояние и лез в сеть заново.
  /// Строим их лениво: непосещённая вкладка ничего не грузит.
  late final List<Widget> _pages;
  final _visited = <int>{0};

  late final AnimationController _tabAnim = AnimationController(
    vsync: this,
    duration: _tabTransition,
    value: 1,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _tabAnim, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.03),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _tabAnim, curve: Curves.easeOut));

  void _open(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
    _tabAnim.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(onOpenTab: _open),
      const ScheduleScreen(),
      const NewsScreen(),
      const WorkListScreen(),
      const ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstLaunch());
  }

  @override
  void dispose() {
    _tabAnim.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('credential_prompt_shown') ?? false;
    if (alreadyShown) return;

    await prefs.setBool('credential_prompt_shown', true);

    final creds = await LkCredentialsStorage().read();
    if (creds != null) return; // Уже есть данные

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _showOnboardingSheet();
  }

  void _showOnboardingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OnboardingSheet(
        onLogin: () async {
          if (!mounted) return;
          await LkLoginDialog.show(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final navItems = [
      (Icons.home_outlined, Icons.home, l.navHome),
      (Icons.calendar_month_outlined, Icons.calendar_month, l.navSchedule),
      (Icons.newspaper_outlined, Icons.newspaper, l.navNews),
      (Icons.assignment_outlined, Icons.assignment, l.navWork),
      (Icons.person_outline, Icons.person, l.navProfile),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  if (_visited.contains(i))
                    Offstage(
                      key: ValueKey<int>(i),
                      offstage: i != _index,
                      // Скрытая вкладка не должна крутить свои анимации.
                      child: TickerMode(
                        enabled: i == _index,
                        // Обёртки одинаковые для всех вкладок: меняются только
                        // сами анимации, поэтому поддерево не пересоздаётся.
                        child: FadeTransition(
                          opacity: i == _index ? _fade : _staticOpacity,
                          child: SlideTransition(
                            position: i == _index ? _slide : _staticOffset,
                            child: _pages[i],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _LkConnectionBanner(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _open,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: List.generate(navItems.length, (i) {
          final (outlinedIcon, filledIcon, label) = navItems[i];
          return NavigationDestination(
            icon: _NavIcon(icon: outlinedIcon, selected: false),
            selectedIcon: _NavIcon(icon: filledIcon, selected: true),
            label: label,
          );
        }),
      ),
    );
  }
}

// ─── Баннер статуса подключения ЛК ───────────────────────────────────────────

class _LkConnectionBanner extends StatefulWidget {
  const _LkConnectionBanner();

  @override
  State<_LkConnectionBanner> createState() => _LkConnectionBannerState();
}

class _LkConnectionBannerState extends State<_LkConnectionBanner> {
  LkStatus? _lastStatus;
  _BannerState _bannerState = _BannerState.hidden;
  Timer? _hideTimer;
  LkController? _lkController;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lk = context.read<LkController>();
    if (_lkController != lk) {
      _lkController?.removeListener(_onLkChanged);
      _lkController = lk;
      _lkController!.addListener(_onLkChanged);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _lkController?.removeListener(_onLkChanged);
    super.dispose();
  }

  void _onLkChanged() {
    final lk = _lkController;
    if (lk == null) return;
    final status = lk.status;
    if (status == _lastStatus) return;
    final prev = _lastStatus;
    _lastStatus = status;
    _hideTimer?.cancel();

    if (status == LkStatus.connecting) {
      setState(() => _bannerState = _BannerState.connecting);
    } else if (prev == LkStatus.connecting && status == LkStatus.connected) {
      setState(() => _bannerState = _BannerState.success);
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _bannerState = _BannerState.hidden);
      });
    } else if (prev == LkStatus.connecting && status == LkStatus.error) {
      setState(() {
        _bannerState = _BannerState.error;
        _errorMessage = lk.errorMessage;
      });
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _bannerState = _BannerState.hidden);
      });
    } else {
      setState(() => _bannerState = _BannerState.hidden);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
          offset: _bannerState == _BannerState.hidden
              ? const Offset(0, -1)
              : Offset.zero,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _bannerState == _BannerState.hidden ? 0 : 1,
            duration: const Duration(milliseconds: 280),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _buildBannerContent(context),
              ),
            ),
          ),
        );
  }

  Widget _buildBannerContent(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon, text) = switch (_bannerState) {
      _BannerState.connecting => (
          theme.colorScheme.primary,
          null,
          'Подключение к сайту…',
        ),
      _BannerState.success => (
          const Color(0xFF49C18B),
          Icons.check_circle_outline,
          'Подключено',
        ),
      _BannerState.error => (
          theme.colorScheme.error,
          Icons.error_outline,
          _errorMessage ?? 'Ошибка подключения',
        ),
      _BannerState.hidden => (theme.colorScheme.primary, null, ''),
    };

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: color.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 18, color: Colors.white)
            else
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BannerState { hidden, connecting, success, error }

// ─── Онбординг-шит (первый запуск) ───────────────────────────────────────────

class _OnboardingSheet extends StatefulWidget {
  final Future<void> Function() onLogin;

  const _OnboardingSheet({required this.onLogin});

  @override
  State<_OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<_OnboardingSheet> {
  late final ConfettiController _confetti;
  bool _logging = false;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() { _logging = true; _error = null; });
    await widget.onLogin();
    if (!mounted) return;
    final lk = context.read<LkController>();
    if (lk.isConnected) {
      setState(() { _logging = false; _success = true; });
      _confetti.play();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        _logging = false;
        _error = lk.errorMessage ?? 'Ошибка подключения';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            color: Colors.transparent,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              color: theme.colorScheme.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Градиентная шапка
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
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
                        const Text(
                          'Войдите в Личный кабинет',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Тело
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24, 20, 24,
                      MediaQuery.viewInsetsOf(context).bottom + 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Для доступа к контактным работам, отчётам и оценкам нужен аккаунт up.omgtu.ru — те же логин и пароль, что на сайте.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .shake(hz: 4, offset: const Offset(6, 0)),
                        ],
                        const SizedBox(height: 20),
                        if (_success)
                          const Icon(Icons.check_circle, color: Color(0xFF49C18B), size: 48)
                              .animate()
                              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut)
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _logging ? null : _doLogin,
                              child: _logging
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Войти'),
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Пропустить'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            Color(0xFF8B5CF6),
            Color(0xFF6C5CE7),
            Color(0xFFFFD700),
            Color(0xFFEC4899),
            Color(0xFF3B82F6),
          ],
        ),
      ],
    );
  }
}

// ─── NavIcon ──────────────────────────────────────────────────────────────────

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _NavIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    if (!selected) return Icon(icon, color: color);

    return Icon(icon, color: color)
        .animate(key: ValueKey(icon))
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
          duration: 320.ms,
          curve: Curves.elasticOut,
        )
        .shimmer(
          duration: 600.ms,
          color: color.withValues(alpha: 0.4),
          delay: 100.ms,
        );
  }
}
