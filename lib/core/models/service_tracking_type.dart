enum ServiceTrackingType {
  time,
  completion,
  custom;

  String get apiValue {
    switch (this) {
      case ServiceTrackingType.time:
        return 'TIME';
      case ServiceTrackingType.completion:
        return 'COMPLETION';
      case ServiceTrackingType.custom:
        return 'CUSTOM';
    }
  }

  String get label {
    switch (this) {
      case ServiceTrackingType.time:
        return 'Por tempo';
      case ServiceTrackingType.completion:
        return 'Apenas ao finalizar';
      case ServiceTrackingType.custom:
        return 'Campos customizados';
    }
  }

  String get explanation {
    switch (this) {
      case ServiceTrackingType.time:
        return 'O progresso será acompanhado pelo tempo dedicado ao serviço.';
      case ServiceTrackingType.completion:
        return 'O progresso será considerado somente na conclusão do serviço.';
      case ServiceTrackingType.custom:
        return 'O progresso seguirá os critérios definidos pelo solicitante.';
    }
  }

  static ServiceTrackingType fromApi(dynamic value) {
    switch (value?.toString().trim().toUpperCase()) {
      case 'COMPLETION':
        return ServiceTrackingType.completion;
      case 'CUSTOM':
        return ServiceTrackingType.custom;
      case 'TIME':
      default:
        return ServiceTrackingType.time;
    }
  }
}
