import 'category_entity.dart';
import 'user_creator.dart';

class ServiceDetailModel {
  final int? id;
  final String title;
  final String description;
  final int timeChronos;
  final String deadline;
  final List<CategoryEntity> categoryEntities;
  final String modality;
  final String status;
  final String? serviceImage;
  final UserCreator userCreator;
  final String postedAt;
  final int verificationCodeCallCount;
  final AcceptedRequestInfo? acceptedRequestInfo;

  ServiceDetailModel({
    this.id,
    required this.title,
    required this.description,
    required this.timeChronos,
    required this.deadline,
    required this.categoryEntities,
    required this.modality,
    this.status = 'CRIADO',
    this.serviceImage,
    required this.userCreator,
    this.postedAt = '',
    this.verificationCodeCallCount = 0,
    this.acceptedRequestInfo,
  });

  String? get serviceImageUrl => serviceImage;

  factory ServiceDetailModel.fromJson(Map<String, dynamic> json) {
    return ServiceDetailModel(
      id: _toNullableInt(json['id']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      timeChronos: _toInt(json['timeChronos']),
      deadline: (json['deadline'] ?? '').toString(),
      categoryEntities: _parseCategories(
        json['categoryEntities'] ?? json['categories'],
      ),
      modality: (json['modality'] ?? '').toString(),
      status: (json['status'] ?? 'CRIADO').toString(),
      serviceImage: _parseServiceImage(json),
      userCreator: UserCreator.fromJson(
        _withFallbackRating(
          (json['userCreator'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
          json['rating'] ?? json['userRating'] ?? json['avaliacao'],
        ),
      ),
      postedAt: (json['postedAt'] ?? '').toString(),
      verificationCodeCallCount: _toInt(
        json['verificationCodeCallCount'] ??
            json['verification_code_call_count'] ??
            json['startCallCount'],
      ),
      acceptedRequestInfo: AcceptedRequestInfo.fromJson(json),
    );
  }

  static List<CategoryEntity> _parseCategories(dynamic categories) {
    if (categories is! List) return [];

    return categories.map(CategoryEntity.fromJson).toList();
  }

  static Map<String, dynamic> _withFallbackRating(
    Map<String, dynamic> data,
    dynamic fallbackRating,
  ) {
    final nextData = Map<String, dynamic>.from(data);
    nextData.putIfAbsent('rating', () => fallbackRating);
    return nextData;
  }

  static String? _parseServiceImage(Map<String, dynamic> json) {
    final rawValue = json['serviceImageUrl'] ?? json['serviceImage'];
    if (rawValue == null) {
      return null;
    }

    final value = rawValue.toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }

    return value;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'timeChronos': timeChronos,
      'deadline': deadline,
      'categoryEntities': categoryEntities.map((e) => e.toJson()).toList(),
      'categories': categoryEntities.map((e) => e.name).toList(),
      'modality': modality,
      'status': status,
      if (serviceImage != null) 'serviceImage': serviceImage,
      if (postedAt.isNotEmpty) 'postedAt': postedAt,
      'verificationCodeCallCount': verificationCodeCallCount,
      if (acceptedRequestInfo != null) ...acceptedRequestInfo!.toJson(),
    };
  }
}

class AcceptedRequestInfo {
  final UserCreator? acceptedUser;
  final String? acceptedAt;
  final String? authenticationCode;
  final String? expiresAt;

  const AcceptedRequestInfo({
    this.acceptedUser,
    this.acceptedAt,
    this.authenticationCode,
    this.expiresAt,
  });

  bool get hasAcceptedUser =>
      acceptedUser != null &&
      (acceptedUser!.id != null ||
          acceptedUser!.name.trim().isNotEmpty ||
          acceptedUser!.phoneNumber != null);

  factory AcceptedRequestInfo.fromJson(Map<String, dynamic> json) {
    final nestedInfo = json['acceptedRequestInfo'];
    final source = nestedInfo is Map
        ? <String, dynamic>{...nestedInfo.cast<String, dynamic>(), ...json}
        : json;
    final acceptedUserJson = _extractAcceptedUserJson(source);
    final acceptedAt = _readFirstString(
      source,
      const [
        'acceptedAt',
        'accepted_at',
        'aceitoEm',
        'acceptedDate',
      ],
    );
    final authenticationCode = _readFirstString(
      source,
      const [
        'authenticationCode',
        'verificationCode',
        'startAuthenticationCode',
        'codigoAutenticacao',
      ],
    );
    final expiresAt = _readFirstString(
      source,
      const [
        'expiresAt',
        'verificationCodeExpiresAt',
        'authenticationCodeExpiresAt',
      ],
    );

    if (acceptedUserJson == null &&
        (acceptedAt == null || acceptedAt.isEmpty) &&
        (authenticationCode == null || authenticationCode.isEmpty) &&
        (expiresAt == null || expiresAt.isEmpty)) {
      return const AcceptedRequestInfo();
    }

    return AcceptedRequestInfo(
      acceptedUser: acceptedUserJson != null
          ? UserCreator.fromJson(acceptedUserJson)
          : null,
      acceptedAt: acceptedAt,
      authenticationCode: authenticationCode,
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (acceptedUser != null) 'acceptedUser': acceptedUser!.toJson(),
      if (acceptedAt != null) 'acceptedAt': acceptedAt,
      if (authenticationCode != null) 'authenticationCode': authenticationCode,
      if (expiresAt != null) 'verificationCodeExpiresAt': expiresAt,
    };
  }

  static Map<String, dynamic>? _extractAcceptedUserJson(
    Map<String, dynamic> json,
  ) {
    const candidateKeys = [
      'acceptedUser',
      'userAccepted',
      'acceptedBy',
      'acceptedProvider',
      'providerAccepted',
      'prestadorAceito',
    ];

    for (final key in candidateKeys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, dynamic>();
      }
    }

    final acceptedUserId = _readFirstInt(
      json,
      const ['acceptedUserId', 'acceptedById', 'providerAcceptedId'],
    );
    final acceptedUserName = _readFirstString(
      json,
      const ['acceptedUserName', 'acceptedByName', 'providerAcceptedName'],
    );
    final acceptedUserPhone = _readFirstInt(
      json,
      const ['acceptedUserPhone', 'acceptedByPhone', 'providerAcceptedPhone'],
    );
    final acceptedUserRating = _readFirstDouble(
      json,
      const [
        'acceptedUserRating',
        'acceptedByRating',
        'providerAcceptedRating',
        'acceptedRating',
      ],
    );

    if (acceptedUserId == null &&
        (acceptedUserName == null || acceptedUserName.isEmpty) &&
        acceptedUserPhone == null &&
        acceptedUserRating == null) {
      return null;
    }

    return {
      if (acceptedUserId != null) 'id': acceptedUserId,
      if (acceptedUserName != null) 'name': acceptedUserName,
      if (acceptedUserPhone != null) 'phoneNumber': acceptedUserPhone,
      if (acceptedUserRating != null) 'rating': acceptedUserRating,
    };
  }

  static String? _readFirstString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static int? _readFirstInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static double? _readFirstDouble(
      Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
