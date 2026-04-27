// core/models/user_creator.dart
class UserCreator {
  final int? id;
  final String name;
  final String? email;
  final int? phoneNumber;
  final int? timeChronos;
  
  UserCreator({
    this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.timeChronos,
  });
  
  factory UserCreator.fromJson(Map<String, dynamic> json) {
    return UserCreator(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phoneNumber: _toInt(json['phoneNumber']),
      timeChronos: _toInt(json['timeChronos']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (timeChronos != null) 'timeChronos': timeChronos,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
