class Request {
  final String title;
  final String description;
  final int timeChronos;
  final String deadline;
  final List<String> categories;
  final String modality;
  final String? requestImage;

  Request({
    required this.title,
    required this.description,
    required this.timeChronos,
    required this.deadline,
    required this.categories,
    required this.modality,
    this.requestImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timeChronos': timeChronos,
      'deadline': deadline,
      'categories': categories,
      'modality': modality,
      if (requestImage != null) 'requestImage': requestImage,
    };
  }

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timeChronos: json['timeChronos'] ?? 0,
      deadline: json['deadline'] ?? '',
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      modality: json['modality'] ?? '',
      requestImage: json['requestImage'],
    );
  }
}