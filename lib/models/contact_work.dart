class WorkFile {
  final String name;
  final String url;
  final String type; // pdf, docx, pptx, link

  const WorkFile({required this.name, required this.url, required this.type});
}

class ContactWorkItem {
  final int number;
  final String comment;
  final List<WorkFile> files;
  final DateTime? createdAt;
  final String teacher;

  const ContactWorkItem({
    required this.number,
    required this.comment,
    required this.files,
    this.createdAt,
    required this.teacher,
  });
}

class WorkDiscipline {
  final String discipline;
  final List<String> teachers;
  final List<ContactWorkItem> items;

  const WorkDiscipline({
    required this.discipline,
    required this.teachers,
    required this.items,
  });

  int get taskCount => items.length;
}
