import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/app_nav_controller.dart';
import '../controllers/lk_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/lk/lk_credentials_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/lk_login_sheet.dart';
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

  /// Р’РєР»Р°РґРєРё Р¶РёРІСѓС‚ РІ РґРµСЂРµРІРµ Рё РЅРµ РїРµСЂРµСЃРѕР·РґР°СЋС‚СЃСЏ РїСЂРё РїРµСЂРµРєР»СЋС‡РµРЅРёРё, РёРЅР°С‡Рµ
  /// РєР°Р¶РґС‹Р№ РІРѕР·РІСЂР°С‚ РЅР° В«Р Р°СЃРїРёСЃР°РЅРёРµВ» С‚РµСЂСЏР» СЃРѕСЃС‚РѕСЏРЅРёРµ Рё Р»РµР· РІ СЃРµС‚СЊ Р·Р°РЅРѕРІРѕ.
  /// РЎС‚СЂРѕРёРј РёС… Р»РµРЅРёРІРѕ: РЅРµРїРѕСЃРµС‰С‘РЅРЅР°СЏ РІРєР»Р°РґРєР° РЅРёС‡РµРіРѕ РЅРµ РіСЂСѓР·РёС‚.
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

  /// Р­РєСЂР°РЅС‹, Р·Р°РїСѓС€РµРЅРЅС‹Рµ РїРѕРІРµСЂС… С€РµР»Р»Р° (РЅР°РїСЂРёРјРµСЂ, РїРѕР»РЅРѕСЌРєСЂР°РЅРЅС‹Р№ РїРѕРёСЃРє), РЅРµ
  /// СЏРІР»СЏСЋС‚СЃСЏ РїРѕС‚РѕРјРєР°РјРё `_pages` Рё РЅРµ РјРѕРіСѓС‚ РґС‘СЂРЅСѓС‚СЊ `_open` РЅР°РїСЂСЏРјСѓСЋ вЂ”
  /// РІРјРµСЃС‚Рѕ СЌС‚РѕРіРѕ РѕРЅРё РїСЂРѕСЃСЏС‚ С‡РµСЂРµР· РїСЂРѕРІР°Р№РґРµСЂ, Р° С€РµР»Р» СЃР»СѓС€Р°РµС‚ Рё РїРµСЂРµРєР»СЋС‡Р°РµС‚.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstLaunch());
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
    if (creds != null) return; // РЈР¶Рµ РµСЃС‚СЊ РґР°РЅРЅС‹Рµ

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    // РћРґРЅР° С€С‚РѕСЂРєР° РІРјРµСЃС‚Рѕ РґРІСѓС…: РїСЂРёРІРµС‚СЃС‚РІРёРµ Рё РїРѕР»СЏ РІС…РѕРґР° С‚РµРїРµСЂСЊ РІ РЅРµР№ Р¶Рµ.
    await LkLoginSheet.show(context, allowSkip: true);
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
      // РЎРѕРґРµСЂР¶РёРјРѕРµ РІРєР»Р°РґРєРё СѓС…РѕРґРёС‚ РїРѕРґ РїР»Р°РІР°СЋС‰СѓСЋ РїР°РЅРµР»СЊ, Р° РµС‘ РІС‹СЃРѕС‚Р° РїРѕРїР°РґР°РµС‚
      // РІ `MediaQuery.padding.bottom` С‚РµР»Р° вЂ” РѕС‚С‚СѓРґР° РµС‘ Р±РµСЂС‘С‚ `navBottomPadding`.
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
                      // РЎРєСЂС‹С‚Р°СЏ РІРєР»Р°РґРєР° РЅРµ РґРѕР»Р¶РЅР° РєСЂСѓС‚РёС‚СЊ СЃРІРѕРё Р°РЅРёРјР°С†РёРё.
                      child: TickerMode(
                        enabled: i == _index,
                        // РћР±С‘СЂС‚РєРё РѕРґРёРЅР°РєРѕРІС‹Рµ РґР»СЏ РІСЃРµС… РІРєР»Р°РґРѕРє: РјРµРЅСЏСЋС‚СЃСЏ С‚РѕР»СЊРєРѕ
                        // СЃР°РјРё Р°РЅРёРјР°С†РёРё, РїРѕСЌС‚РѕРјСѓ РїРѕРґРґРµСЂРµРІРѕ РЅРµ РїРµСЂРµСЃРѕР·РґР°С‘С‚СЃСЏ.
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

// в”Ђв”Ђв”Ђ Р‘Р°РЅРЅРµСЂ СЃС‚Р°С‚СѓСЃР° РїРѕРґРєР»СЋС‡РµРЅРёСЏ Р›Рљ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

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

