// core/models/category_entity.dart
class CategoryEntity {
  final String name;
  
  CategoryEntity({required this.name});
  
  factory CategoryEntity.fromJson(dynamic json) { // Mude para dynamic
    // Pode vir como objeto {"name": "valor"} ou como string "valor"
    if (json is String) {
      return CategoryEntity(name: json);
    } else if (json is Map<String, dynamic>) {
      return CategoryEntity(name: json['name'] ?? '');
    } else {
      // Fallback para caso inesperado
      return CategoryEntity(name: '');
    }
  }
  
  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}