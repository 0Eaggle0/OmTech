/// Файл материала курса.
class MaterialFile {
  final String name;
  final String type; // pdf / docx / pptx / link
  final String url;

  const MaterialFile({required this.name, required this.type, required this.url});
}

/// Дисциплина с материалами (заглушка — данные требуют авторизации в ЛК).
class CourseMaterial {
  final String discipline;
  final String teacher;
  final List<MaterialFile> files;

  const CourseMaterial({
    required this.discipline,
    required this.teacher,
    required this.files,
  });
}
