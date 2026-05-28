enum EntityType { group, teacher, auditorium }

class ScheduleEntity {
  final int id;
  final String label;
  final String description;
  final EntityType type;

  const ScheduleEntity({
    required this.id,
    required this.label,
    this.description = '',
    required this.type,
  });

  factory ScheduleEntity.fromJson(Map<String, dynamic> json, EntityType type) {
    return ScheduleEntity(
      id: json['id'] as int,
      label: (json['label'] ?? json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? json['shortName'] ?? '').toString(),
      type: type,
    );
  }
}
