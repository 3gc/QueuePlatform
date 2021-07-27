class QueueEntity {
  final String id;
  final int tier;
  final String value;

  QueueEntity({required this.id, required this.tier, required this.value});

  factory QueueEntity.fromJson(Map<String, dynamic> json) {
    return QueueEntity(
        id: json['id'], value: json['value'], tier: json['tier'] ?? 1);
  }
}

class EntityInfo {
  List<QueueEntity> entities;
  int total;

  EntityInfo(this.entities, this.total);
}
