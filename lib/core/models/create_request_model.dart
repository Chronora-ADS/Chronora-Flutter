// core/models/create_request_model.dart
class CreateRequestModel {
  final String title;
  final String description;
  final int timeChronos;
  final String deadline;
  final List<String> categories;
  final String modality;
  final String? serviceImage;

  CreateRequestModel({
    required this.title,
    required this.description,
    required this.timeChronos,
    required this.deadline,
    required this.categories,
    required this.modality,
    this.serviceImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timeChronos': timeChronos,
      'deadline': deadline,
      'categories': categories,
      'modality': modality,
      if (serviceImage != null) 'serviceImage': serviceImage,
    };
  }

  factory CreateRequestModel.fromJson(Map<String, dynamic> json) {
    return CreateRequestModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timeChronos: json['timeChronos'] ?? 0,
      deadline: json['deadline'] ?? '',
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      modality: json['modality'] ?? '',
      serviceImage: json['serviceImage'],
    );
  }
}