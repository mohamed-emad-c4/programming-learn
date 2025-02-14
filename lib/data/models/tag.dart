class Tag {
  final int id;
  final String name;
  final String description;

  Tag({required this.id, required this.name, required this.description});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}