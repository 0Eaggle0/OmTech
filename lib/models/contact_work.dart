class WorkFile {
  final String name;
  final String url;
  final String type; // pdf, docx, pptx, link

  const WorkFile({required this.name, required this.url, required this.type});

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'type': type,
      };

  factory WorkFile.fromJson(Map<String, dynamic> json) => WorkFile(
        name: (json['name'] ?? '') as String,
        url: (json['url'] ?? '') as String,
        type: (json['type'] ?? 'link') as String,
      );
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

  Map<String, dynamic> toJson() => {
        'number': number,
        'comment': comment,
        'files': files.map((f) => f.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'teacher': teacher,
      };

  factory ContactWorkItem.fromJson(Map<String, dynamic> json) =>
      ContactWorkItem(
        number: (json['number'] ?? 0) as int,
        comment: (json['comment'] ?? '') as String,
        files: ((json['files'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => WorkFile.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        teacher: (json['teacher'] ?? '') as String,
      );
}

class WorkDiscipline {
  /// Идентификатор дисциплины из querystring `discipline=...` ссылки на детали.
  /// `null` означает демо-дисциплину (нет реального источника).
  final String? id;
  final String discipline;
  final List<String> teachers;
  final List<ContactWorkItem> items;
  final int? taskCountHint;

  const WorkDiscipline({
    this.id,
    required this.discipline,
    required this.teachers,
    required this.items,
    this.taskCountHint,
  });

  int get taskCount => taskCountHint ?? items.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'discipline': discipline,
        'teachers': teachers,
        'items': items.map((i) => i.toJson()).toList(),
        'taskCountHint': taskCountHint,
      };

  factory WorkDiscipline.fromJson(Map<String, dynamic> json) => WorkDiscipline(
        id: json['id'] as String?,
        discipline: (json['discipline'] ?? '') as String,
        teachers: ((json['teachers'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        items: ((json['items'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => ContactWorkItem.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        taskCountHint: json['taskCountHint'] as int?,
      );
}
