import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group.dart';
import '../services/schedule_api.dart';
import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

/// Bottom sheet поиска группы через реальный API.
/// Возвращает выбранную [Group] через Navigator.pop.
class GroupSearchSheet extends StatefulWidget {
  const GroupSearchSheet({super.key});

  static Future<Group?> show(BuildContext context) {
    return showModalBottomSheet<Group>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const GroupSearchSheet(),
    );
  }

  @override
  State<GroupSearchSheet> createState() => _GroupSearchSheetState();
}

class _GroupSearchSheetState extends State<GroupSearchSheet> {
  final _api = ScheduleApi.instance;
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Group> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final term = value.trim();
    if (term.length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(term));
  }

  Future<void> _search(String term) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await _api.searchGroups(term);
      if (!mounted) return;
      setState(() {
        _results = groups;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.groupSearchError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.groupSearchTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: l.groupSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(child: _buildResults(l)),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations l) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final glass = context.glass;
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    }
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            l.groupSearchHint,
            style: TextStyle(color: glass.textMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final g = _results[i];
        return Material(
          color: glass.elevatedFill,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            onTap: () => Navigator.of(context).pop(g),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.label, style: Theme.of(context).textTheme.titleSmall),
                        if (g.description.isNotEmpty)
                          Text(
                            g.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: glass.textMuted),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: glass.textFaint),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
