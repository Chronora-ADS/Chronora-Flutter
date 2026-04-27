export 'category_entity.dart';
export 'user_creator.dart';

import 'category_entity.dart';
import 'user_creator.dart';

class Service {
  final int id;
  final String title;
  final String description;
  final String serviceImageUrl;
  final int timeChronos;
  final UserCreator userCreator;
  final UserCreator? userAccepted;
  final List<CategoryEntity> categoryEntities;
  final DateTime deadline;
  final String modality;
  final String status;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.serviceImageUrl,
    required this.timeChronos,
    required this.userCreator,
    required this.userAccepted,
    required this.categoryEntities,
    required this.deadline,
    required this.modality,
    required this.status,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: _toInt(json['id']) ?? 0,
      title: (json['title'] ?? 'Titulo nao disponivel').toString(),
      description: (json['description'] ?? 'Descricao nao disponivel').toString(),
      serviceImageUrl: _parseServiceImage(json),
      timeChronos: _toInt(json['timeChronos']) ?? 0,
      userCreator:
          _parseUser(json['userCreator']) ??
          UserCreator(name: 'Usuario desconhecido'),
      userAccepted:
          _parseUser(json['userAccepted']) ??
          _parseUser(json['acceptedBy']) ??
          _parseUser(json['userExecutor']),
      categoryEntities: _parseCategories(
        json['categoryEntities'] ?? json['categories'],
      ),
      deadline: _parseDeadline(json['deadline']),
      modality: (json['modality'] ?? '').toString(),
      status: (json['status'] ?? 'CRIADO').toString(),
    );
  }

  static UserCreator? _parseUser(dynamic value) {
    if (value is Map<String, dynamic>) {
      return UserCreator.fromJson(value);
    }

    if (value is List) {
      for (final item in value) {
        final parsed = _parseUser(item);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static List<CategoryEntity> _parseCategories(dynamic value) {
    if (value is List) {
      return value.map((item) => CategoryEntity.fromJson(item)).toList();
    }

    return [];
  }

  static DateTime _parseDeadline(dynamic value) {
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.now().add(const Duration(days: 30));
  }

  static String _parseServiceImage(Map<String, dynamic> json) {
    final rawValue = json['serviceImageUrl'] ?? json['serviceImage'];
    if (rawValue == null) {
      return '';
    }

    return rawValue.toString();
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
