// core/models/user_creator.dart
class UserCreator {
  final int? id;
  final String name;
  final String? email;
  final int? phoneNumber;
  final int? timeChronos;
  final double? rating;

  UserCreator({
    this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.timeChronos,
    this.rating,
  });

  factory UserCreator.fromJson(Map<String, dynamic> json) {
    return UserCreator(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phoneNumber: _toInt(json['phoneNumber']),
      timeChronos: _toInt(json['timeChronos']),
      rating: _toDouble(
        json['rating'] ?? json['userRating'] ?? json['avaliacao'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (timeChronos != null) 'timeChronos': timeChronos,
      if (rating != null) 'rating': rating,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }
}
