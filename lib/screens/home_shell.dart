import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/app_nav_controller.dart';
import '../controllers/lk_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/lk/lk_credentials_storage.dart';
import '../services/update_service.dart';
import '../theme/app_colors.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/lk_login_sheet.dart';
import '../widgets/update_sheet.dart';
import 'dashboard/dashboard_screen.dart';
import 'news/news_screen.dart';
import 'profile/profile_screen.dart';
import 'schedule/schedule_screen.dart';
import 'work/work_hub_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with TickerProviderStateMixin {
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

  AppNavController? _appNav;

  void _open(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
    _tabAnim.forward(from: 0);
  }

  /// Экраны, запушенные поверх шелла (например, полноэкранный поиск), не
  /// являются потомками `_pages` и не могут дёрнуть `_open` напрямую —
  /// вместо этого они просят через провайдер, а шелл слушает и переключает.
  void _onAppNavChanged() {
    final tab = _appNav?.consumeTab();
    if (tab != null) _open(tab);
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(onOpenTab: _open),
      const ScheduleScreen(),
      const NewsScreen(),
      const WorkHubScreen(),
      const ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkFirstLaunch().then((_) => _checkUpdate()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<AppNavController>();
    if (_appNav != nav) {
      _appNav?.removeListener(_onAppNavChanged);
      _appNav = nav;
      _appNav!.addListener(_onAppNavChanged);
    }
  }

  @override
  void dispose() {
    _appNav?.removeListener(_onAppNavChanged);
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
    // Одна шторка вместо двух: приветствие и поля входа теперь в ней же.
    await LkLoginSheet.show(context, allowSkip: true);
  }

  Future<void> _checkUpdate() async {
    final release = await UpdateService.checkLatest();
    if (release == null || !mounted) return;
    await UpdateSheet.show(context, release);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final navItems = [
      NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home, label: l.navHome),
      NavItemData(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
        label: l.navSchedule,
      ),
      NavItemData(
        icon: Icons.newspaper_outlined,
        activeIcon: Icons.newspaper,
        label: l.navNews,
      ),
      NavItemData(
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment,
        label: l.navWork,
      ),
      NavItemData(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: l.navProfile,
      ),
    ];

    return Scaffold(
      // Содержимое вкладки уходит под плавающую панель, а её высота попадает
      // в `MediaQuery.padding.bottom` тела — оттуда её берёт `navBottomPadding`.
      extendBody: true,
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
      bottomNavigationBar: FloatingNavBar(
        items: navItems,
        index: _index,
        onSelected: _open,
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
    final l = AppLocalizations.of(context)!;
    final (color, icon, text) = switch (_bannerState) {
      _BannerState.connecting => (
          theme.colorScheme.primary,
          null,
          l.lkConnecting,
        ),
      _BannerState.success => (
          AppColors.statusSuccess,
          Icons.check_circle_outline,
          l.lkConnected,
        ),
      _BannerState.error => (
          theme.colorScheme.error,
          Icons.error_outline,
          _errorMessage ?? l.lkConnectError,
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

