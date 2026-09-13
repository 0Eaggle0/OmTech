import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../controllers/lk_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/link_launcher.dart';
import '../services/teacher_contacts_service.dart';
import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

/// Ищет контакты преподавателя в контактной работе и показывает карточку.
/// Пока идёт поиск и когда ничего не нашлось — места не занимает вовсе.
class TeacherContactsLookup extends StatefulWidget {
  final String lecturer;
  final String? discipline;

  /// Подписать карточку ФИО — когда у пары несколько преподавателей.
  final bool showName;
  final EdgeInsetsGeometry padding;

  const TeacherContactsLookup({
    super.key,
    required this.lecturer,
    this.discipline,
    this.showName = false,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  @override
  State<TeacherContactsLookup> createState() => _TeacherContactsLookupState();
}

class _TeacherContactsLookupState extends State<TeacherContactsLookup> {
  late final Future<TeacherContacts?> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherContactsService.instance.find(
      context.read<LkController>(),
      lecturer: widget.lecturer,
      discipline: widget.discipline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeacherContacts?>(
      future: _future,
      builder: (context, snapshot) {
        final contacts = snapshot.data;
        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: contacts == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: widget.padding,
                  child: TeacherContactsCard(
                    contacts: contacts,
                    name: widget.showName ? widget.lecturer : null,
                  ),
                )
                  .animate()
                  .fadeIn(duration: 220.ms)
                  .slideY(begin: 0.08, curve: Curves.easeOutCubic),
        );
      },
    );
  }
}

/// Карточка с уже найденными контактами: тап — открыть, копирование —
/// кнопкой или долгим нажатием.
class TeacherContactsCard extends StatelessWidget {
  final TeacherContacts contacts;
  final String? name;

  /// Подпись «Из контактной работы · дисциплина». На экране самой
  /// дисциплины она лишняя.
  final bool showSource;

  const TeacherContactsCard({
    super.key,
    required this.contacts,
    this.name,
    this.showSource = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
      decoration: BoxDecoration(
        color: glass.elevatedFill,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: glass.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_page_outlined, size: 16, color: glass.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name == null
                      ? l.teacherContactsTitle
                      : l.teacherContactsFor(name!),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final c in contacts.items) _ContactTile(contact: c),
          if (showSource && contacts.discipline.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                l.teacherContactsSource(contacts.discipline),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: glass.textFaint),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final TeacherContact contact;

  const _ContactTile({required this.contact});

  void _copy(BuildContext context, AppLocalizations l) {
    Clipboard.setData(ClipboardData(text: contact.value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.reportCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final (icon, label, tone) = switch (contact.kind) {
      TeacherContactKind.email =>
        (Icons.alternate_email_rounded, l.contactKindEmail, glass.accent),
      TeacherContactKind.telegram =>
        (Icons.send_rounded, 'Telegram', glass.statusColor(AppStatus.info)),
      TeacherContactKind.phone => (
          Icons.phone_rounded,
          l.contactKindPhone,
          glass.statusColor(AppStatus.success)
        ),
      TeacherContactKind.vk => (
          Icons.people_alt_outlined,
          l.contactKindVk,
          glass.statusColor(AppStatus.info)
        ),
      TeacherContactKind.max =>
        (Icons.chat_bubble_outline_rounded, 'MAX', glass.accent),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => openExternal(context, contact.uri),
      onLongPress: () => _copy(context, l),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: glass.tint(tone),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: tone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: glass.textMuted),
                  ),
                  Text(
                    contact.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.contactCopy,
              icon: Icon(Icons.copy_rounded, size: 18, color: glass.textFaint),
              onPressed: () => _copy(context, l),
            ),
          ],
        ),
      ),
    );
  }
}
