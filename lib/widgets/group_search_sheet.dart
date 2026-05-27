import 'dart:async';

import 'package:flutter/material.dart';

import '../models/group.dart';
import '../services/schedule_api.dart';

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
  final _api = ScheduleApi();
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
        _error = 'Не удалось найти группы. Проверьте соединение.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выбор группы',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            decoration: const InputDecoration(
              hintText: 'Например: ИВТ-221',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 320, child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'Введите название группы',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final g = _results[i];
        return ListTile(
          title: Text(g.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: g.description.isEmpty ? null : Text(g.description),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pop(g),
        );
      },
    );
  }
}
