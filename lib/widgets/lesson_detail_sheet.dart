import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/schedule_event.dart';
import '../services/link_launcher.dart';
import '../theme/app_colors.dart';

/// Карта здания ОМГТУ → адрес
const _buildingAddresses = {
  'УЛК-1': 'пр. Мира, 11',
  'УЛК-2': 'пр. Мира, 11к2',
  'УЛК-3': 'пр. Мира, 11к3',
  'УЛК-4': 'пр. Мира, 11к4',
  'УЛК-5': 'пр. Мира, 11к5',
  'УЛК-6': 'пр. Мира, 11к6',
  'УЛК-7': 'пр. Мира, 11к7',
  'УЛК-8': 'пр. Мира, 11к8',
  'ГУК': 'пр. Мира, 11',
  'СК': 'пр. Мира, 11',
};

class LessonDetailSheet extends StatefulWidget {
  final ScheduleEvent event;

  const LessonDetailSheet({super.key, required this.event});

  static Future<void> show(BuildContext context, ScheduleEvent event) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => LessonDetailSheet(event: event),
    );
  }

  @override
  State<LessonDetailSheet> createState() => _LessonDetailSheetState();
}

class _LessonDetailSheetState extends State<LessonDetailSheet> {
  final _noteController = TextEditingController();
  String _noteKey = '';

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _noteKey = 'note_${e.date.toIso8601String().substring(0, 10)}_${e.beginLesson}_${e.discipline.hashCode}';
    _loadNote();
  }

  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_noteKey) ?? '';
    _noteController.text = saved;
  }

  Future<void> _saveNote(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_noteKey, value);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = AppColors.forKindOfWork(widget.event.kindOfWork);
    final e = widget.event;
    final address = _buildingAddresses[e.building];

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          // Drag handle (от темы)
          const SizedBox(height: 4),

          // Шапка: время + тип
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${e.beginLesson} – ${e.endLesson}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (e.kindOfWork.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    e.kindOfWork,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Дисциплина
          Text(
            e.discipline,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),

          // Инфо-строки
          if (e.stream.isNotEmpty)
            _infoRow(context, Icons.groups_2_outlined, '${l.lessonDetailStream}: ${e.stream}', accent),
          if (e.subgroupLabel.isNotEmpty)
            _infoRow(context, Icons.people_outline, '${l.lessonDetailSubgroup}: ${e.subgroupLabel}', accent),

          if (e.auditorium.isNotEmpty)
            _infoRow(context, Icons.door_front_door_outlined, e.auditorium, accent),

          if (e.building.isNotEmpty)
            _buildingRow(context, l, e.building, address, accent),

          if (e.lecturer.isNotEmpty)
            _teacherRow(context, l, e.lecturer, accent),

          const SizedBox(height: 20),
          Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          const SizedBox(height: 16),

          // Поле заметки
          TextField(
            controller: _noteController,
            maxLines: 4,
            onChanged: _saveNote,
            decoration: InputDecoration(
              hintText: l.lessonDetailNote,
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              prefixIcon: const Icon(Icons.edit_outlined),
              filled: true,
              fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Кнопка поделиться
          FilledButton.icon(
            onPressed: () {
              final note = _noteController.text.trim();
              if (note.isEmpty) return;
              Share.share('${e.discipline} (${e.beginLesson}–${e.endLesson})\n\n$note');
            },
            icon: const Icon(Icons.share_outlined),
            label: Text(l.lessonDetailShare),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text, Color accent) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildingRow(BuildContext context, AppLocalizations l, String building, String? address, Color accent) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.apartment_outlined, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(building, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (address != null)
                  Text(address, style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  )),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              final query = Uri.encodeComponent(address != null ? '$building $address Омск' : '$building Омск ОМГТУ');
              openExternal(context, 'https://maps.yandex.ru/?text=$query');
            },
            icon: Icon(Icons.map_outlined, color: accent),
            tooltip: l.lessonDetailOpenMaps,
          ),
        ],
      ),
    );
  }

  Widget _teacherRow(BuildContext context, AppLocalizations l, String lecturer, Color accent) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_outline, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lecturer,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: () => _showTeacherOptions(context, l, lecturer),
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  void _showTeacherOptions(BuildContext context, AppLocalizations l, String lecturer) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                lecturer,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.contacts_outlined),
              title: Text(l.lessonDetailContacts),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text(l.lessonDetailReviews),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

}
