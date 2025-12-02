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
      id: json['id'] as int?,
      name: json['name'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'] as int?,
      timeChronos: json['timeChronos'] as int?,
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
}