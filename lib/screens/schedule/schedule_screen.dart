import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/group_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/schedule_event.dart';
import '../../services/schedule_api.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/group_search_sheet.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/lesson_detail_sheet.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _api = ScheduleApi();

  late DateTime _weekStart;
  Future<List<ScheduleEvent>>? _future;
  int? _loadedGroupId;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = context.watch<GroupController>().group;
    if (group != null && group.id != _loadedGroupId) {
      _loadedGroupId = group.id;
      _reload();
    }
  }

  void _reload() {
    final group = context.read<GroupController>().group;
    if (group == null) return;
    setState(() {
      _future = _api.getSchedule(
        group.id,
        start: _weekStart,
        finish: _weekStart.add(const Duration(days: 6)),
      );
    });
  }

  void _shiftWeek(int weeks) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));
    _reload();
  }

  Future<void> _pickGroup() async {
    final group = await GroupSearchSheet.show(context);
    if (group != null && mounted) {
      await context.read<GroupController>().select(group);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final group = context.watch<GroupController>().group;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.scheduleTitle),
        actions: [
          if (group != null)
            TextButton.icon(
              onPressed: _pickGroup,
              icon: const Icon(Icons.groups_outlined, size: 18),
              label: Text(group.label),
            ),
        ],
      ),
      body: group == null ? _noGroup(l) : _scheduleBody(l),
    );
  }

  Widget _noGroup(AppLocalizations l) {
    return EmptyState(
      icon: Icons.groups_outlined,
      title: l.scheduleNoGroup,
      message: l.scheduleNoGroupMsg,
      actionLabel: l.schedulePickGroup,
      onAction: _pickGroup,
    );
  }

  Widget _scheduleBody(AppLocalizations l) {
    return Column(
      children: [
        _weekSwitcher(l),
        Expanded(
          child: FutureBuilder<List<ScheduleEvent>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.wifi_off_outlined,
                  title: l.scheduleLoadError,
                  message: l.scheduleLoadErrorMsg,
                  actionLabel: l.scheduleRetry,
                  onAction: _reload,
                );
              }
              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return EmptyState(
                  icon: Icons.event_available_outlined,
                  title: l.scheduleNoLessons,
                  message: l.scheduleNoLessonsMsg,
                );
              }
              return _eventsList(events);
            },
          ),
        ),
      ],
    );
  }

  Widget _weekSwitcher(AppLocalizations l) {
    final end = _weekStart.add(const Duration(days: 6));
    final locale = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('d MMM', locale);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _shiftWeek(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '${fmt.format(_weekStart)} – ${fmt.format(end)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () => _shiftWeek(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _eventsList(List<ScheduleEvent> events) {
    final byDay = <DateTime, List<ScheduleEvent>>{};
    for (final e in events) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      byDay.putIfAbsent(day, () => []).add(e);
    }
    final days = byDay.keys.toList()..sort();
    final locale = Localizations.localeOf(context).languageCode;
    final dayFmt = DateFormat('EEEE, d MMMM', locale);

    int cardIndex = 0;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final lessons = byDay[day]!;
        final headerDelay = (i * 40).ms;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                _capitalize(dayFmt.format(day)),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ).animate(delay: headerDelay).fadeIn(duration: 250.ms),
            ),
            for (final e in lessons) ...[
              () {
                final delay = (cardIndex++ * 55).ms;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LessonCard(
                    event: e,
                    onTap: () => LessonDetailSheet.show(context, e),
                  ).animate(delay: delay).fadeIn(duration: 280.ms).slideY(begin: 0.05, curve: Curves.easeOut),
                );
              }(),
            ],
          ],
        );
      },
    );
  }

  static DateTime _mondayOf(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
