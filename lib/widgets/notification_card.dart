class NotificationEntry {
  final int id;
  final String message;
  final String notificationType;
  final String detail;
  final String actorName;
  final String actorRole;
  final DateTime notificationTime;
  final NotificationServiceSummary service;

  NotificationEntry({
    required this.id,
    required this.message,
    this.notificationType = '',
    this.detail = '',
    this.actorName = '',
    this.actorRole = '',
    required this.notificationTime,
    required this.service,
  });

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    final serviceJson = _readMap(
      json['service'] ??
          json['serviceEntity'] ??
          json['servicePost'] ??
          json['request'] ??
          json['pedido'],
    );

    return NotificationEntry(
      id: _readInt(
        json['id'] ?? json['notificationId'] ?? json['notification_id'],
      ),
      message: _readString(json, const [
        'message',
        'notificationMessage',
        'notification_message',
        'content',
        'text',
        'body',
        'description',
      ]),
      notificationType: _readString(json, const [
        'notificationType',
        'notification_type',
        'type',
      ]),
      detail: _readString(json, const [
        'detail',
        'details',
        'notificationDetail',
        'notification_detail',
        'justification',
        'serviceCancellationJustification',
        'service_cancellation_justification',
      ]),
      actorName: _readString(json, const [
        'actorName',
        'actor_name',
        'cancelledBy',
        'cancelled_by',
        'requestedByName',
        'requested_by_name',
      ]),
      actorRole: _readString(json, const [
        'actorRole',
        'actor_role',
        'cancelledByRole',
        'cancelled_by_role',
        'requestedByRole',
        'requested_by_role',
      ]),
      notificationTime: _readDateTime(
        json['notificationTime'] ??
            json['notification_time'] ??
            json['createdAt'] ??
            json['created_at'] ??
            json['date'] ??
            json['timestamp'] ??
            json['time'],
      ),
      service: NotificationServiceSummary.fromJson(
        serviceJson.isEmpty ? json : serviceJson,
      ),
    );
  }

  bool get hasDetail => detail.trim().isNotEmpty;

  bool get isServiceCancellationJustification {
    final normalizedType = notificationType.trim().toUpperCase();
    if (normalizedType == 'SERVICE_CANCELLATION_JUSTIFICATION') {
      return true;
    }
    return message.toLowerCase().contains('justificativa de cancelamento');
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class NotificationServiceSummary {
  final int id;
  final String title;
  final String status;
  final DateTime? deadline;

  NotificationServiceSummary({
    required this.id,
    required this.title,
    this.status = '',
    this.deadline,
  });

  factory NotificationServiceSummary.fromJson(Map<String, dynamic> json) {
    return NotificationServiceSummary(
      id: NotificationEntry._readInt(
        json['id'] ??
            json['serviceId'] ??
            json['service_id'] ??
            json['requestId'] ??
            json['request_id'],
      ),
      title: NotificationEntry._readString(json, const [
        'title',
        'serviceTitle',
        'service_title',
        'name',
        'requestTitle',
        'request_title',
      ]),
      status: NotificationEntry._readString(json, const [
        'status',
        'serviceStatus',
        'service_status',
        'requestStatus',
        'request_status',
      ]),
      deadline: _readOptionalDate(
        json['deadline'] ??
            json['serviceDeadline'] ??
            json['service_deadline'] ??
            json['requestDeadline'] ??
            json['request_deadline'],
      ),
    );
  }

  static DateTime? _readOptionalDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
