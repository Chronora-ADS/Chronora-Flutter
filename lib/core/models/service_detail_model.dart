// core/models/service_detail_model.dart
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
  final String? serviceImageUrl;
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
    this.serviceImageUrl,
    required this.userCreator,
    required this.postedAt
  });

  factory ServiceDetailModel.fromJson(Map<String, dynamic> json) {
    return ServiceDetailModel(
      id: json['id'] as int?,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timeChronos: json['timeChronos'] ?? 0,
      deadline: json['deadline'] ?? '',
      categoryEntities: _parseCategories(json['categoryEntities']),
      modality: json['modality'] ?? '',
      serviceImageUrl: _parseServiceImage(json),
      userCreator: UserCreator.fromJson(json['userCreator'] ?? {}),
      postedAt: json['postedAt'] ?? '',
    );
  }

  static List<CategoryEntity> _parseCategories(dynamic categories) {
    if (categories == null) return [];
    
    if (categories is List) {
      return categories.map((item) => CategoryEntity.fromJson(item)).toList();
    }
  
    return [];
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

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'timeChronos': timeChronos,
      'deadline': deadline,
      'categories': categoryEntities.map((e) => e.name).toList(),
      'modality': modality,
      if (serviceImageUrl != null) 'serviceImage': serviceImageUrl,
      'postedAt': postedAt
    };
  }
}
