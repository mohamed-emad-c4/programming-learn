class ProblemModel {
  final int id;
  final String title;
  final String description;
  final int level;

  ProblemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    return ProblemModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      level: json['level'],
    );
  }
}
