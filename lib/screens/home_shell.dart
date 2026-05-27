import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
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

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _open(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final pages = [
      DashboardScreen(onOpenTab: _open),
      const ScheduleScreen(),
      const NewsScreen(),
      const WorkListScreen(),
      const ProfileScreen(),
    ];

    final navItems = [
      (Icons.home_outlined, Icons.home, l.navHome),
      (Icons.calendar_month_outlined, Icons.calendar_month, l.navSchedule),
      (Icons.newspaper_outlined, Icons.newspaper, l.navNews),
      (Icons.assignment_outlined, Icons.assignment, l.navWork),
      (Icons.person_outline, Icons.person, l.navProfile),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _open,
        // Показываем подпись только у выбранного — нет переносов длинных слов
        labelBehavior:
            NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: List.generate(navItems.length, (i) {
          final (outlinedIcon, filledIcon, label) = navItems[i];
          return NavigationDestination(
            icon: _NavIcon(
              icon: outlinedIcon,
              selected: false,
            ),
            selectedIcon: _NavIcon(
              icon: filledIcon,
              selected: true,
            ),
            label: label,
          );
        }),
      ),
    );
  }
}

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
