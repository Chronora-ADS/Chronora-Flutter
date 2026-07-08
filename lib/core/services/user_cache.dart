import 'dart:convert';

import '../api/api_service.dart';

class CachedUserData {
  final int? id;
  final String name;
  final double? rating;
  final String? photoUrl;
  final bool isModerator;
  final int timeChronos;
  final String? email;
  final int? phoneNumber;
  final DateTime fetchedAt;

  const CachedUserData({
    this.id,
    required this.name,
    this.rating,
    this.photoUrl,
    required this.isModerator,
    required this.timeChronos,
    this.email,
    this.phoneNumber,
    required this.fetchedAt,
  });

  factory CachedUserData.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];
    final isModerator = roles is List && roles.contains('ROLE_MODERATOR');

    final ratingRaw = json['rating'] ?? json['userRating'] ?? json['avaliacao'];
    double? rating;
    if (ratingRaw is num) {
      rating = ratingRaw.toDouble();
    } else if (ratingRaw is String) {
      rating = double.tryParse(ratingRaw);
    }

    final photo =
        json['profileImageUrl'] ?? json['profileImage'] ?? json['photoUrl'];
    final rawName = (json['name'] as String?)?.trim();

    return CachedUserData(
      id: _toInt(json['id']),
      name: (rawName != null && rawName.isNotEmpty) ? rawName : 'Usuário',
      rating: rating,
      photoUrl: photo?.toString(),
      isModerator: isModerator,
      timeChronos: _toInt(json['timeChronos']) ?? 0,
      email: json['email']?.toString(),
      phoneNumber: _toInt(json['phoneNumber']),
      fetchedAt: DateTime.now(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class UserCache {
  static final UserCache instance = UserCache._();
  UserCache._();

  static const _ttl = Duration(seconds: 60);

  CachedUserData? _cached;
  Future<CachedUserData?>? _pendingFetch;

  Future<CachedUserData?> get(String token) async {
    final cached = _cached;
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) <= _ttl) {
      return cached;
    }
    _pendingFetch ??=
        _refresh(token).whenComplete(() => _pendingFetch = null);
    return _pendingFetch;
  }

  Future<CachedUserData?> _refresh(String token) async {
    try {
      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) return _cached;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return _cached;
      final data = decoded['user'] is Map<String, dynamic>
          ? decoded['user'] as Map<String, dynamic>
          : decoded;
      _cached = CachedUserData.fromJson(data);
      return _cached;
    } catch (_) {
      return _cached;
    }
  }

  void invalidate() {
    _cached = null;
    _pendingFetch = null;
  }
}
