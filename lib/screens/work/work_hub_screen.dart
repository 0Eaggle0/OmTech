import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_nav_controller.dart';
import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/lk_required_state.dart';
import '../../widgets/sliding_toggle.dart';
import '../reports/report_work_list_view.dart';
import 'contact_work_list_view.dart';

/// Вкладка «Задания»: контактная работа и отчётные работы под одним
/// переключателем. Оба списка живут в `IndexedStack`, поэтому переключение
/// разделов не пересоздаёт их состояние и не тянет данные заново.
class WorkHubScreen extends StatefulWidget {
  const WorkHubScreen({super.key});

  @override
  State<WorkHubScreen> createState() => _WorkHubScreenState();
}

class _WorkHubScreenState extends State<WorkHubScreen> {
  int _section = 0;

  /// Непосещённый раздел не строим: иначе открытие вкладки тянуло бы из сети
  /// сразу оба списка. Посещённый остаётся в дереве и не грузится повторно.
  final _visited = <int>{0};

  AppNavController? _appNav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<AppNavController>();
    if (_appNav != nav) {
      _appNav?.removeListener(_onNavChanged);
      _appNav = nav;
      _appNav!.addListener(_onNavChanged);
    }
  }

  @override
  void dispose() {
    _appNav?.removeListener(_onNavChanged);
    super.dispose();
  }

  /// Плитки на главной открывают вкладку сразу на нужном разделе.
  void _onNavChanged() {
    final section = _appNav?.consumeWorkSection();
    if (section != null && section != _section) _select(section);
  }

  void _select(int section) {
    setState(() {
      _section = section;
      _visited.add(section);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lk = context.watch<LkController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.workHubTitle),
      ),
      body: !lk.isConnected
          ? const LkRequiredState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: SlidingToggle(
                    items: [
                      SlidingToggleItem(
                        icon: Icons.groups_2_outlined,
                        label: l.workTitle,
                      ),
                      SlidingToggleItem(
                        icon: Icons.assignment_turned_in_outlined,
                        label: l.reportWorksTitle,
                      ),
                    ],
                    selected: _section,
                    onSelected: _select,
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _section,
                    children: [
                      if (_visited.contains(0))
                        const ContactWorkListView()
                      else
                        const SizedBox.shrink(),
                      if (_visited.contains(1))
                        const ReportWorkListView()
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
