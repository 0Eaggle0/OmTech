/// Учебная группа из API поиска ОМГТУ.
class Group {
  final int id;
  final String label;
  final String description;

  const Group({required this.id, required this.label, required this.description});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      label: (json['label'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}
