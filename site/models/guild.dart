class Guild {
  int entities;
  String id;
  String name;
  String? key;

  Guild(this.id, this.name, this.entities, {this.key});

  factory Guild.fromJson(Map<String, dynamic> json) {
    return Guild(json['id'], json['name'], json['entities']);
  }
}
