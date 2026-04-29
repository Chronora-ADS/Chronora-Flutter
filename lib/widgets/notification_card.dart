class NotificationCard {
  final int id;
  final String message;
  final DateTime notificationTime;
  final ServiceData service;

  NotificationCard({
    required this.id,
    required this.message,
    required this.notificationTime,
    required this.service,
  });

  factory NotificationCard.fromJson(Map<String, dynamic> json) {
    return NotificationCard(
      id: json['id'],
      message: json['message'],
      notificationTime: DateTime.parse(json['notificationTime']),
      service: ServiceData.fromJson(json['service']),
    );
  }
}

class ServiceData {
  final int id;
  final String title;

  ServiceData({required this.id, required this.title});

  factory ServiceData.fromJson(Map<String, dynamic> json) {
    return ServiceData(
      id: json['id'],
      title: json['title'],
    );
  }
}