import 'category_entity.dart';
import 'user_creator.dart';

class ServiceDetailModel {
  final int? id;
  final String title;
  final String description;
  final int timeChronos;
  final String deadline;
  final List<CategoryEntity> categoryEntities;
  final String modality;
  final String? serviceImage;
  final UserCreator userCreator;

  ServiceDetailModel({
    this.id,
    required this.title,
    required this.description,
    required this.timeChronos,
    required this.deadline,
    required this.categoryEntities,
    required this.modality,
    this.serviceImage,
    required this.userCreator,
  });

  factory ServiceDetailModel.fromJson(Map<String, dynamic> json) {
    return ServiceDetailModel(
      id: _toNullableInt(json['id']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timeChronos: _toInt(json['timeChronos']),
      deadline: json['deadline'] ?? '',
      categoryEntities: _parseCategories(
        json['categoryEntities'] ?? json['categories'],
      ),
      modality: json['modality'] ?? '',
      serviceImage:
          (json['serviceImage'] ?? json['serviceImageUrl'])?.toString(),
      userCreator: UserCreator.fromJson(json['userCreator'] ?? {}),
    );
  }

  static List<CategoryEntity> _parseCategories(dynamic categories) {
    if (categories is! List) return [];
    return categories.map((item) => CategoryEntity.fromJson(item)).toList();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'timeChronos': timeChronos,
      'deadline': deadline,
      'categoryEntities': categoryEntities.map((e) => e.toJson()).toList(),
      'modality': modality,
      if (serviceImage != null) 'serviceImage': serviceImage,
    };
  }
}
