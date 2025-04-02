class Tag {
  final int id;
  final String name;
  final String description;
  final String imageUrl;

  Tag({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['url_image'] ?? 'assets/images/fallback.jpg',
    );
  }
}
