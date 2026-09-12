import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_nav_controller.dart';
import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/lk_required_state.dart';
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
  int? _contactCount;
  int? _reportCount;

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
        actions: [
          if (lk.isConnected && _section == 1)
            IconButton(
              tooltip: l.reportShareHtml,
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => shareReportDebugDumps(context),
            ),
        ],
      ),
      body: !lk.isConnected
          ? const LkRequiredState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: SegmentedButton<int>(
                    style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    segments: [
                      ButtonSegment(
                        value: 0,
                        icon: const Icon(Icons.groups_2_outlined, size: 16),
                        label: Text(_label(l.workTitle, _contactCount)),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: const Icon(Icons.assignment_turned_in_outlined,
                            size: 16),
                        label: Text(_label(l.reportWorksTitle, _reportCount)),
                      ),
                    ],
                    selected: {_section},
                    onSelectionChanged: (s) => _select(s.first),
                    showSelectedIcon: false,
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _section,
                    children: [
                      if (_visited.contains(0))
                        ContactWorkListView(
                          onCount: (n) => setState(() => _contactCount = n),
                        )
                      else
                        const SizedBox.shrink(),
                      if (_visited.contains(1))
                        ReportWorkListView(
                          onCount: (n) => setState(() => _reportCount = n),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static String _label(String title, int? count) =>
      count == null ? title : '$title  $count';
}
