import 'dart:async';

import 'package:flutter/material.dart';

import '../models/schedule_entity.dart';
import '../services/schedule_api.dart';

class EntitySearchSheet extends StatefulWidget {
  final String title;
  final String hint;
  final Future<List<ScheduleEntity>> Function(String term) search;

  const EntitySearchSheet({
    super.key,
    required this.title,
    required this.hint,
    required this.search,
  });

  static Future<ScheduleEntity?> showForTeacher(BuildContext context) => _show(
        context,
        title: 'Поиск преподавателя',
        hint: 'Фамилия, например: Иванов',
        search: ScheduleApi().searchTeachers,
      );

  static Future<ScheduleEntity?> showForAuditorium(BuildContext context) => _show(
        context,
        title: 'Поиск аудитории',
        hint: 'Номер, например: 8-418',
        search: ScheduleApi().searchAuditoriums,
      );

  static Future<ScheduleEntity?> _show(
    BuildContext context, {
    required String title,
    required String hint,
    required Future<List<ScheduleEntity>> Function(String) search,
  }) {
    return showModalBottomSheet<ScheduleEntity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EntitySearchSheet(title: title, hint: hint, search: search),
    );
  }

  @override
  State<EntitySearchSheet> createState() => _EntitySearchSheetState();
}

class _EntitySearchSheetState extends State<EntitySearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<ScheduleEntity> _results = [];
  bool _loading = false;
  bool _searched = false;
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
        _searched = false;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(term));
  }

  Future<void> _search(String term) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.search(term);
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
        _error = 'Не удалось выполнить поиск. Проверьте соединение.';
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
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
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
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    }
    if (!_searched) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Введите не менее 2 символов',
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
          title: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: e.description.isNotEmpty ? Text(e.description) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pop(e),
        );
      },
    );
  }
}
