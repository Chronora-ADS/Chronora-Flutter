class CreateRequestModel {
  final String title;
  final String description;
  final int timeChronos;
  final String deadline;
  final List<String> categories;
  final String modality;
  final String serviceImage;

  CreateRequestModel({
    required this.title,
    required this.description,
    required this.timeChronos,
    required this.deadline,
    required this.categories,
    required this.modality,
    required this.serviceImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timeChronos': timeChronos,
      'deadline': deadline,
      'categories': categories
          .map((category) => category.trim())
          .where((category) => category.isNotEmpty)
          .toList(),
      'modality': modalityToApi(modality),
      if (serviceImage != null) 'serviceImage': serviceImage,
    };
  }

  static String modalityToApi(String modality) {
    final normalized = _normalizeForApi(modality);

    if (normalized.startsWith('PRESENC')) {
      return 'PRESENCIAL';
    }

    if (normalized.startsWith('REMOT')) {
      return 'REMOTO';
    }

    if (normalized.contains('HIBRID')) {
      return 'HIBRIDO';
    }

    return normalized;
  }

  static String _normalizeForApi(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('\u00C1', 'A')
        .replaceAll('\u00C0', 'A')
        .replaceAll('\u00C2', 'A')
        .replaceAll('\u00C3', 'A')
        .replaceAll('\u00C9', 'E')
        .replaceAll('\u00CA', 'E')
        .replaceAll('\u00CD', 'I')
        .replaceAll('\u00D3', 'O')
        .replaceAll('\u00D4', 'O')
        .replaceAll('\u00D5', 'O')
        .replaceAll('\u00DA', 'U')
        .replaceAll('\u00C7', 'C');
  }

  factory CreateRequestModel.fromJson(Map<String, dynamic> json) {
    return CreateRequestModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timeChronos: json['timeChronos'] ?? 0,
      deadline: json['deadline'] ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      modality: json['modality'] ?? '',
      serviceImage: json['serviceImage'] ?? '',
    );
  }
}
