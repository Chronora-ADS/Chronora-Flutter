class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final int? timeChronos;
  final String? description;
  final double? rating;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.timeChronos,
    this.description,
    this.rating,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _readString(json['id']),
      name: _readString(json['name']),
      email: _readString(json['email']),
      phoneNumber: _readString(json['phoneNumber']),
      timeChronos: _readInt(json['timeChronos']),
      description:
          _readNullableString(json['description'] ?? json['descricao']),
      rating: _readDouble(
          json['rating'] ?? json['userRating'] ?? json['avaliacao']),
      profileImage: _readNullableString(
        json['profileImage'] ?? json['profileImageUrl'] ?? json['photoUrl'],
      ),
    );
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String? _readNullableString(dynamic value) {
    final text = _readString(value);
    return text.isEmpty ? null : text;
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}
