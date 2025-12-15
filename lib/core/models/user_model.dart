// models/user_model.dart
class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final int? timeChronos;
  final String? descricao;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.timeChronos,
    this.descricao,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseString(json['id']),
      name: _parseString(json['name']),
      email: _parseString(json['email']),
      phoneNumber: _parseString(json['phoneNumber']),
      timeChronos: _parseInt(json['timeChronos']),
      descricao: _parseString(json['descricao']),
    );
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.tryParse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'timeChronos': timeChronos,
      'descricao': descricao,
    };
  }
}