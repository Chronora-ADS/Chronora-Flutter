class Service {
  final int id;
  final String title;
  final String description;
  final String serviceImage;
  final int timeChronos;
  final UserCreator userCreator;
  final List<CategoryEntity> categoryEntities;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.serviceImage,
    required this.timeChronos,
    required this.userCreator,
    required this.categoryEntities,
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

    return Service(
      id: json['id'],
      title: json['title'] ?? 'Título não disponível',
      description: json['description'] ?? 'Descrição não disponível',
      serviceImage: json['serviceImage'] ?? '',
      timeChronos: json['timeChronos'] ?? 0,
      userCreator: userCreator,
      categoryEntities: (json['categoryEntities'] as List? ?? [])
          .map((e) => CategoryEntity.fromJson(e ?? {}))
          .toList(),
    );
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
