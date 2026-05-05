enum ModalityOption {
  presencial,
  remoto,
  hibrido,
}

class ModalityOptions {
  static const List<String> labels = [
    'Presencial',
    'Remoto',
    'Híbrido',
  ];

  static String toBackendValue(String label) {
    switch (label) {
      case 'Presencial':
        return 'PRESENCIAL';
      case 'Remoto':
        return 'REMOTO';
      case 'Híbrido':
        return 'HIBRIDO';
      default:
        return 'PRESENCIAL';
    }
  }

  static String fromBackendValue(String value) {
    switch (value.toUpperCase()) {
      case 'PRESENCIAL':
        return 'Presencial';
      case 'REMOTO':
        return 'Remoto';
      case 'HÍBRIDO':
      case 'HIBRIDO':
        return 'Híbrido';
      default:
        return 'Presencial';
    }
  }
}
