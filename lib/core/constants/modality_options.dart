enum ModalityOption {
  presencial,
  remoto,
}

class ModalityOptions {
  static const List<String> labels = [
    'Presencial',
    'Remoto',
  ];

  static String toBackendValue(String label) {
    switch (label) {
      case 'Presencial':
        return 'PRESENCIAL';
      case 'Remoto':
        return 'REMOTO';
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
      default:
        return 'Presencial';
    }
  }
}
