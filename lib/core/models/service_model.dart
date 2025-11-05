class Service {
  final String title;
  final String serviceImage;
  final int timeChronos;
  final UserEntity userEntity;
  final List<CategoryEntity> categoryEntities;

  Service({
    required this.title,
    required this.serviceImage,
    required this.timeChronos,
    required this.userEntity,
    required this.categoryEntities,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      title: json['title'] ?? '',
      serviceImage: json['serviceImage'] ?? '',
      timeChronos: json['timeChronos'] ?? 0,
      userEntity: UserEntity.fromJson(json['userEntity'] ?? {}),
      categoryEntities: (json['categoryEntities'] as List? ?? [])
          .map((e) => CategoryEntity.fromJson(e))
          .toList(),
    );
  }
}

class UserEntity {
  final String name;

  UserEntity({required this.name});

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
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