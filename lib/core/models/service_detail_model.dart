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
  final String postedAt;

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
    this.postedAt = '',
  });

  String? get serviceImageUrl => serviceImage;

  factory ServiceDetailModel.fromJson(Map<String, dynamic> json) {
    return ServiceDetailModel(
      id: _toNullableInt(json['id']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      timeChronos: _toInt(json['timeChronos']),
      deadline: (json['deadline'] ?? '').toString(),
      categoryEntities: _parseCategories(
        json['categoryEntities'] ?? json['categories'],
      ),
      modality: (json['modality'] ?? '').toString(),
      serviceImage: _parseServiceImage(json),
      userCreator: UserCreator.fromJson(
        (json['userCreator'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      postedAt: (json['postedAt'] ?? '').toString(),
    );
  }

  static List<CategoryEntity> _parseCategories(dynamic categories) {
    if (categories is! List) return [];

    return categories.map(CategoryEntity.fromJson).toList();
  }

  static String? _parseServiceImage(Map<String, dynamic> json) {
    final rawValue = json['serviceImageUrl'] ?? json['serviceImage'];
    if (rawValue == null) {
      return null;
    }

    final value = rawValue.toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }

    return value;
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
      'categories': categoryEntities.map((e) => e.name).toList(),
      'modality': modality,
      if (serviceImage != null) 'serviceImage': serviceImage,
      if (postedAt.isNotEmpty) 'postedAt': postedAt,
    };
  }
}
