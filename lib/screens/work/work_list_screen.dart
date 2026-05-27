import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact_work.dart';
import '../../services/contact_work_service.dart';
import '../../widgets/demo_banner.dart';
import 'work_detail_screen.dart';

class WorkListScreen extends StatefulWidget {
  const WorkListScreen({super.key});

  @override
  State<WorkListScreen> createState() => _WorkListScreenState();
}

class _WorkListScreenState extends State<WorkListScreen> {
  final _service = ContactWorkService();
  late final Future<List<WorkDiscipline>> _future = _service.fetchDisciplines();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.workTitle)),
      body: FutureBuilder<List<WorkDiscipline>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final filtered = _query.isEmpty
              ? all
              : all.where((d) => d.discipline.toLowerCase().contains(_query.toLowerCase())).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l.workSearch,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DemoBanner(text: l.workDemoNote),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _disciplineCard(context, l, filtered[i], i),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _disciplineCard(BuildContext context, AppLocalizations l, WorkDiscipline d, int index) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkDetailScreen(discipline: d)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.discipline,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l.workTeachers}: ${d.teachers.join(', ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${d.taskCount}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l.workTaskCount,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.search, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ).animate(delay: (index * 60).ms).fadeIn(duration: 280.ms).slideY(begin: 0.05, curve: Curves.easeOut),
    );
  }
}
