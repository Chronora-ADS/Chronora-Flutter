// core/models/service_detail_model.dart
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
  final String? serviceImageUrl;
  final UserCreator userCreator;
  final String postedAt;
  final AcceptedRequestInfo? acceptedRequestInfo;

  ServiceDetailModel({
    this.id,
    required this.title,
    required this.description,
    required this.timeChronos,
    required this.deadline,
    required this.categoryEntities,
    required this.modality,
    this.serviceImageUrl,
    required this.userCreator,
    required this.postedAt,
    this.acceptedRequestInfo,
  });

  factory ServiceDetailModel.fromJson(Map<String, dynamic> json) {
    return ServiceDetailModel(
      id: json['id'] as int?,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timeChronos: json['timeChronos'] ?? 0,
      deadline: json['deadline'] ?? '',
      categoryEntities: _parseCategories(json['categoryEntities']),
      modality: json['modality'] ?? '',
      serviceImageUrl: json['serviceImageUrl'],
      userCreator: UserCreator.fromJson(json['userCreator'] ?? {}),
      postedAt: json['postedAt'] ?? '',
      acceptedRequestInfo: AcceptedRequestInfo.fromJson(json),
    );
  }

  static List<CategoryEntity> _parseCategories(dynamic categories) {
    if (categories == null) return [];
    
    if (categories is List) {
      return categories.map((item) => CategoryEntity.fromJson(item)).toList();
    }
  
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'timeChronos': timeChronos,
      'deadline': deadline,
      'categories': categoryEntities.map((e) => e.name).toList(),
      'modality': modality,
      if (serviceImageUrl != null) 'serviceImage': serviceImageUrl,
      'postedAt': postedAt,
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
      ((acceptedUser!.name).trim().isNotEmpty || acceptedUser!.phoneNumber != null);

  factory AcceptedRequestInfo.fromJson(Map<String, dynamic> json) {
    final acceptedUserJson = _extractAcceptedUserJson(json);
    final acceptedAt = _readFirstString(
      json,
      const [
        'acceptedAt',
        'accepted_at',
        'aceitoEm',
        'acceptedDate',
      ],
    );
    final authenticationCode = _readFirstString(
      json,
      const [
        'authenticationCode',
        'verificationCode',
        'startAuthenticationCode',
        'codigoAutenticacao',
      ],
    );
    final expiresAt = _readFirstString(
      json,
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
      if (authenticationCode != null)
        'authenticationCode': authenticationCode,
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

    if (acceptedUserId == null &&
        (acceptedUserName == null || acceptedUserName.isEmpty) &&
        acceptedUserPhone == null) {
      return null;
    }

    return {
      if (acceptedUserId != null) 'id': acceptedUserId,
      if (acceptedUserName != null) 'name': acceptedUserName,
      if (acceptedUserPhone != null) 'phoneNumber': acceptedUserPhone,
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
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
