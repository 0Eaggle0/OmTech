import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';
import '../../models/grade.dart';
import '../../services/grades_service.dart';
import '../../widgets/demo_banner.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> with SingleTickerProviderStateMixin {
  final _service = GradesService();
  late final Future<List<Semester>> _future = _service.fetchSemesters();
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.gradesTitle)),
      body: FutureBuilder<List<Semester>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final semesters = snapshot.data!;

          _tabController ??= TabController(length: semesters.length, vsync: this);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DemoBanner(text: l.gradesDemoNote),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: List.generate(
                  semesters.length,
                  (i) => Tab(text: '${i + 1} ${l.gradesSemester}'),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController!,
                  children: semesters.asMap().entries.map((entry) {
                    return _semesterTab(context, entry.value, entry.key);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _semesterTab(BuildContext context, Semester semester, int semIndex) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          semester.title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...semester.grades.asMap().entries.map((entry) {
          return _gradeTile(context, entry.value, entry.key).animate(
            delay: (entry.key * 60).ms,
          ).fadeIn(duration: 280.ms).slideY(begin: 0.05, curve: Curves.easeOut);
        }),
      ],
    );
  }

  Widget _gradeTile(BuildContext context, Grade g, int index) {
    final theme = Theme.of(context);
    final markColor = _markColor(g.mark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.discipline,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          _controlIcon(g.controlType),
                          size: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          g.controlType,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: markColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      g.mark,
                      style: TextStyle(
                        color: markColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (g.score != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${g.score} б.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _markColor(String mark) {
    final m = mark.toLowerCase();
    if (m.contains('отл')) return const Color(0xFF49C18B);
    if (m.contains('хор')) return const Color(0xFF4F9DDE);
    if (m.contains('удовл')) return const Color(0xFFE0A03A);
    if (m.contains('зачт')) return const Color(0xFF8B5CF6);
    if (m.contains('незачт') || m.contains('неуд')) return const Color(0xFFE05A6B);
    return const Color(0xFF9A97A8);
  }

  IconData _controlIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('экзам')) return Icons.fact_check_outlined;
    if (t.contains('зачёт') || t.contains('зачет')) return Icons.check_circle_outline;
    if (t.contains('курс')) return Icons.menu_book_outlined;
    if (t.contains('вкр')) return Icons.school_outlined;
    return Icons.grade_outlined;
  }
}
