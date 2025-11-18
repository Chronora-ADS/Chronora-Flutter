class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String? chronora;
  final String? descricao;
  final String? currentPassword;
  final String? newPassword;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.chronora,
    this.descricao,
    this.currentPassword,
    this.newPassword,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      chronora: json['chronora']?.toString(),
      descricao: json['descricao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'chronora': chronora,
      'descricao': descricao,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? chronora,
    String? descricao,
    String? currentPassword,
    String? newPassword,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      chronora: chronora ?? this.chronora,
      descricao: descricao ?? this.descricao,
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
    );
  }
}
