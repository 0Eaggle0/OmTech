import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../controllers/lk_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/course_material.dart';
import '../../services/link_launcher.dart';
import '../../services/materials_service.dart';
import '../../widgets/demo_banner.dart';
import '../../widgets/lk_required_state.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _service = MaterialsService();
  late final Future<List<CourseMaterial>> _future = _service.fetchMaterials();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lk = context.watch<LkController>();

    return Scaffold(
      appBar: AppBar(title: Text(l.materialsTitle)),
      body: !lk.isConnected
          ? const LkRequiredState()
          : FutureBuilder<List<CourseMaterial>>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final courses = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    DemoBanner(text: l.materialsDemoNote),
                    const SizedBox(height: 12),
                    for (var i = 0; i < courses.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _courseCard(context, courses[i])
                            .animate(key: ValueKey(courses[i].discipline))
                            .fadeIn(duration: 180.ms)
                            .slideY(begin: 0.05, curve: Curves.easeOut),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _courseCard(BuildContext context, CourseMaterial c) {
    final theme = Theme.of(context);
    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          title: Text(c.discipline, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(c.teacher),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [
            for (final f in c.files)
              ListTile(
                leading: Icon(_iconFor(f.type), color: theme.colorScheme.primary),
                title: Text(f.name),
                trailing: const Icon(Icons.download_outlined, size: 20),
                onTap: () => openExternal(context, f.url),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'pdf':  return Icons.picture_as_pdf_outlined;
      case 'docx': return Icons.description_outlined;
      case 'pptx': return Icons.slideshow_outlined;
      case 'link': return Icons.link_outlined;
      default:     return Icons.insert_drive_file_outlined;
    }
  }
}
