class Validators {
  static final RegExp _emailRegex = RegExp(r'^[\w.-]+@[\w-]+\.[a-zA-Z]{2,}$');
  static final RegExp _randomPixKeyRegex = RegExp(r'^[a-zA-Z0-9_-]{8,64}$');

  static bool isEmail(String value) => _emailRegex.hasMatch(value.trim());

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-mail é obrigatório';
    if (!isEmail(value)) return 'E-mail inválido';
    return null;
  }

  static bool isPixKey(String value) {
    if (value.isEmpty) return false;
    if (isEmail(value)) return true;

    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 10 && digitsOnly.length <= 13) return true;

    return _randomPixKeyRegex.hasMatch(value);
  }
}
