import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingServiceCancellationJustification {
  final int serviceId;
  final String serviceTitle;
  final String requesterName;
  final DateTime createdAt;

  const PendingServiceCancellationJustification({
    required this.serviceId,
    required this.serviceTitle,
    required this.requesterName,
    required this.createdAt,
  });

  String get displayTitle {
    final title = serviceTitle.trim();
    return title.isEmpty ? 'Pedido #$serviceId' : title;
  }

  String get displayRequesterName {
    final name = requesterName.trim();
    return name.isEmpty ? 'Cliente nao informado' : name;
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'requesterName': requesterName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PendingServiceCancellationJustification.fromJson(
    Map<String, dynamic> json,
  ) {
    final serviceId = _toInt(json['serviceId'] ?? json['service_id']);
    if (serviceId == null) {
      throw const FormatException('serviceId obrigatorio');
    }

    return PendingServiceCancellationJustification(
      serviceId: serviceId,
      serviceTitle: (json['serviceTitle'] ?? json['service_title'] ?? '')
          .toString()
          .trim(),
      requesterName: (json['requesterName'] ?? json['requester_name'] ?? '')
          .toString()
          .trim(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class PendingServiceCancellationStore {
  static const String _storageKey =
      'pending_service_cancellation_justifications';

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<List<PendingServiceCancellationJustification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      final pending = decoded
          .whereType<Map>()
          .map((item) => PendingServiceCancellationJustification.fromJson(
                item.cast<String, dynamic>(),
              ))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return pending;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> hasPending() async {
    final pending = await getAll();
    return pending.isNotEmpty;
  }

  static Future<void> upsert(
    PendingServiceCancellationJustification pending,
  ) async {
    final all = await getAll();
    final next = [
      for (final item in all)
        if (item.serviceId != pending.serviceId) item,
      pending,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    await _save(next);
  }

  static Future<void> remove(int serviceId) async {
    final all = await getAll();
    final next = [
      for (final item in all)
        if (item.serviceId != serviceId) item,
    ];

    await _save(next);
  }

  static Future<void> _save(
    List<PendingServiceCancellationJustification> pending,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (pending.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(
        _storageKey,
        jsonEncode(pending.map((item) => item.toJson()).toList()),
      );
    }

    changes.value++;
  }
}
