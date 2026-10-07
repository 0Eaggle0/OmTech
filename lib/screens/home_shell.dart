import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../controllers/app_nav_controller.dart';
import '../controllers/lk_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/lk/lk_credentials_storage.dart';
import '../services/update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../widgets/background_work_tile.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/lk_login_sheet.dart';
import '../widgets/update_sheet.dart';
import 'dashboard/dashboard_screen.dart';
import 'news/news_screen.dart';
import 'profile/profile_screen.dart';
import 'schedule/schedule_screen.dart';
import 'work/work_hub_screen.dart';
import '../services/app_prefs.dart';

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
    final prefs = appPrefs;
    final alreadyShown = await prefs.getBool('credential_prompt_shown') ?? false;
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
          // Над навбаром и сквозной для тапов: сверху плашка закрывала
          // кнопки шапок (в том числе настройки в профиле).
          const Positioned.fill(
            child: IgnorePointer(child: _LkConnectionBanner()),
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

    // Тихое восстановление сессии плашку не трогает — только вход из формы
    // и отвергнутый пароль (он приходит и без «подключения»).
    if (status == LkStatus.connecting) {
      if (!lk.interactiveLogin) return;
      setState(() => _bannerState = _BannerState.connecting);
    } else if (prev == LkStatus.connecting &&
        status == LkStatus.connected &&
        lk.interactiveLogin) {
      setState(() => _bannerState = _BannerState.success);
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _bannerState = _BannerState.hidden);
      });
      // Пользователь только что вошёл — самое время один раз попросить
      // разрешение на фон, ради которого вход и нужен уведомлениям.
      unawaited(showBatteryHintIfNeeded(context));
    } else if (status == LkStatus.error) {
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
    final hidden = _bannerState == _BannerState.hidden;
    // `MediaQuery.padding.bottom` тела уже включает высоту навбара
    // (extendBody), так что пилюля садится ровно над ним.
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            24, 0, 24, MediaQuery.paddingOf(context).bottom + 10),
        child: AnimatedSlide(
          offset: hidden ? const Offset(0, 0.8) : Offset.zero,
          duration: const Duration(milliseconds: 380),
          curve: hidden ? Curves.easeInCubic : Curves.easeOutBack,
          child: AnimatedScale(
            scale: hidden ? 0.85 : 1,
            duration: const Duration(milliseconds: 380),
            curve: hidden ? Curves.easeInCubic : Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: hidden ? 0 : 1,
              duration: const Duration(milliseconds: 240),
              child: _buildPill(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final l = AppLocalizations.of(context)!;
    final (color, text) = switch (_bannerState) {
      _BannerState.connecting => (theme.colorScheme.primary, l.lkConnecting),
      _BannerState.success => (AppColors.statusSuccess, l.lkConnected),
      _BannerState.error => (
          theme.colorScheme.error,
          _errorMessage ?? l.lkConnectError,
        ),
      _BannerState.hidden => (theme.colorScheme.primary, ''),
    };

    Widget pill = DecoratedBox(
      decoration: BoxDecoration(
        color: glass.navFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: glass.floatShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26,
                height: 18,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(
                        parent: anim, curve: Curves.easeOutBack),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: switch (_bannerState) {
                    _BannerState.success => Icon(Icons.check_rounded,
                        key: const ValueKey('ok'), size: 18, color: color),
                    _BannerState.error => Icon(Icons.close_rounded,
                        key: const ValueKey('err'), size: 18, color: color),
                    _ => _LinkingDots(key: const ValueKey('link'), color: color),
                  },
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    text,
                    key: ValueKey(text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (_bannerState == _BannerState.error) {
      // Короткое «нет» головой — понятнее красного цвета в одиночку.
      pill = pill
          .animate(key: const ValueKey('shake'))
          .shakeX(hz: 5, amount: 4, duration: 420.ms);
    }
    return pill;
  }
}

enum _BannerState { hidden, connecting, success, error }

/// Две точки тянутся друг к другу и сцепляются перемычкой — «подключаемся».
class _LinkingDots extends StatefulWidget {
  final Color color;

  const _LinkingDots({super.key, required this.color});

  @override
  State<_LinkingDots> createState() => _LinkingDotsState();
}

class _LinkingDotsState extends State<_LinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _LinkingDotsPainter(
          CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic),
          widget.color,
        ),
      );
}

class _LinkingDotsPainter extends CustomPainter {
  final Animation<double> t;
  final Color color;

  _LinkingDotsPainter(this.t, this.color) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final cy = size.height / 2;
    final gap = lerpDouble(size.width / 2 - 4, 4, v)!;
    final left = Offset(size.width / 2 - gap, cy);
    final right = Offset(size.width / 2 + gap, cy);
    final paint = Paint()..color = color;

    canvas.drawLine(
      left,
      right,
      Paint()
        ..color = color.withValues(alpha: 0.5 * v)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(left, 3.5, paint);
    canvas.drawCircle(right, 3.5, paint);
  }

  @override
  bool shouldRepaint(_LinkingDotsPainter old) => old.color != color;
}
