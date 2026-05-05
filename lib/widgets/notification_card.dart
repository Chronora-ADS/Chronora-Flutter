class NotificationEntry {
  final int id;
  final String message;
  final DateTime notificationTime;
  final NotificationServiceSummary service;

  NotificationEntry({
    required this.id,
    required this.message,
    required this.notificationTime,
    required this.service,
  });

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    return NotificationEntry(
      id: _readInt(json['id']),
      message: json['message']?.toString() ?? '',
      notificationTime: _readDateTime(json['notificationTime']),
      service: NotificationServiceSummary.fromJson(
        (json['service'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
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

  NotificationServiceSummary({
    required this.id,
    required this.title,
  });

  factory NotificationServiceSummary.fromJson(Map<String, dynamic> json) {
    return NotificationServiceSummary(
      id: NotificationEntry._readInt(json['id']),
      title: json['title']?.toString() ?? '',
    );
  }
}
