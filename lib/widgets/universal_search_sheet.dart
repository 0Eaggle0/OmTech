import 'dart:async';

import 'package:flutter/material.dart';

import '../models/schedule_entity.dart';
import '../services/schedule_api.dart';

class UniversalSearchSheet extends StatefulWidget {
  const UniversalSearchSheet({super.key});

  static Future<ScheduleEntity?> show(BuildContext context) {
    return showModalBottomSheet<ScheduleEntity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const UniversalSearchSheet(),
    );
  }

  @override
  State<UniversalSearchSheet> createState() => _UniversalSearchSheetState();
}

class _UniversalSearchSheetState extends State<UniversalSearchSheet> {
  final _api = ScheduleApi.instance;
  final _controller = TextEditingController();
  Timer? _debounce;
  List<ScheduleEntity> _results = [];
  bool _loading = false;
  bool _searched = false;

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
        _searched = false;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(term));
  }

  Future<void> _search(String term) async {
    setState(() => _loading = true);
    try {
      final results = await _api.universalSearch(term);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searched = true;
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
            'Общий поиск',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Группы, преподаватели и аудитории',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            decoration: const InputDecoration(
              hintText: 'Например: ИВТ, Иванов, 8-418...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_searched) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Начните вводить запрос',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Ничего не найдено',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = _results[i];
        return ListTile(
          leading: _typeIcon(e.type),
          title: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: e.description.isNotEmpty ? Text(e.description) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pop(e),
        );
      },
    );
  }

  Widget _typeIcon(EntityType type) {
    final (icon, label, color) = switch (type) {
      EntityType.group => (Icons.groups_outlined, 'Группа', Colors.blue),
      EntityType.teacher => (Icons.person_outline, 'Препод.', Colors.purple),
      EntityType.auditorium => (Icons.place_outlined, 'Аудит.', Colors.teal),
    };
    return Tooltip(
      message: label,
      child: Icon(icon, color: color),
    );
  }
}
