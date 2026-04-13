class Service {
  final int id;
  final String title;
  final String description;
  final String serviceImage;
  final int timeChronos;
  final UserCreator userCreator;
  final List<CategoryEntity> categoryEntities;
  final DateTime deadline;
  final String modality;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.serviceImage,
    required this.timeChronos,
    required this.userCreator,
    required this.categoryEntities,
    required this.deadline,
    required this.modality,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    // Verifica se userCreator existe e é um Map
    final userCreatorJson = json['userCreator'];
    UserCreator userCreator;

    if (userCreatorJson != null && userCreatorJson is Map<String, dynamic>) {
      userCreator = UserCreator.fromJson(userCreatorJson);
    } else {
      // Cria um UserCreator padrão se estiver nulo ou inválido
      userCreator = UserCreator(name: 'Usuário Desconhecido');
    }

    DateTime deadline;
    try {
      if (json['deadline'] != null) {
        deadline = DateTime.parse(json['deadline']);
      } else {
        deadline = DateTime.now().add(const Duration(days: 30)); // Fallback
      }
    } catch (e) {
      deadline = DateTime.now().add(const Duration(days: 30)); // Fallback
    }

    return Service(
      id: _toInt(json['id']),
      title: json['title'] ?? 'Título não disponível',
      description: json['description'] ?? 'Descrição não disponível',
<<<<<<< ours
<<<<<<< ours
      serviceImage:
          (json['serviceImageUrl'] ?? json['serviceImage'] ?? '').toString(),
      timeChronos: json['timeChronos'] ?? 0,
=======
      serviceImage: (json['serviceImage'] ?? json['serviceImageUrl'] ?? '').toString(),
      timeChronos: _toInt(json['timeChronos']),
>>>>>>> theirs
=======
      serviceImage: (json['serviceImage'] ?? json['serviceImageUrl'] ?? '').toString(),
      timeChronos: _toInt(json['timeChronos']),
>>>>>>> theirs
      userCreator: userCreator,
      categoryEntities: _parseCategories(json['categoryEntities'] ?? json['categories']),
      deadline: deadline,
      modality: json['modality'] ?? '',
    );
  }

  static List<CategoryEntity> _parseCategories(dynamic categories) {
    if (categories is! List) return [];

    return categories.map((item) {
      if (item is Map<String, dynamic>) {
        return CategoryEntity.fromJson(item);
      }
      if (item is String) {
        return CategoryEntity(name: item);
      }
      return CategoryEntity(name: '');
    }).toList();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class UserCreator {
  final String name;

  UserCreator({required this.name});

  factory UserCreator.fromJson(Map<String, dynamic> json) {
    return UserCreator(
      name: json['name'] ?? '',
    );
  }
}

class CategoryEntity {
  final String name;

  CategoryEntity({required this.name});

  factory CategoryEntity.fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      name: json['name'] ?? '',
    );
  }
}
