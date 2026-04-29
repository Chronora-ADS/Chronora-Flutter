import 'dart:convert';
import 'dart:typed_data';

import 'package:chronora/core/constants/app_config.dart';

class ServiceImageResolver {
  static String? normalize(dynamic rawValue) {
    if (rawValue == null) {
      return null;
    }

    final value = rawValue.toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }

    return value;
  }

  static Uint8List? tryDecodeBytes(String? rawValue) {
    final value = normalize(rawValue);
    if (value == null) {
      return null;
    }

    final base64Value = _extractBase64Value(value);
    if (base64Value == null) {
      return null;
    }

    try {
      return base64Decode(base64.normalize(base64Value));
    } catch (_) {
      return null;
    }
  }

  static String? resolveNetworkUrl(String? rawValue) {
    final value = normalize(rawValue);
    if (value == null) {
      return null;
    }

    if (_extractBase64Value(value) != null) {
      return null;
    }

    if (_isAbsoluteUrl(value) || value.startsWith('blob:')) {
      return value;
    }

    final baseUrl = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final normalizedPath = value.replaceFirst(RegExp(r'^/+'), '');
    return '$baseUrl/$normalizedPath';
  }

  static String? _extractBase64Value(String value) {
    if (_isDataUri(value)) {
      final commaIndex = value.indexOf(',');
      if (commaIndex == -1 || commaIndex == value.length - 1) {
        return null;
      }

      return value.substring(commaIndex + 1);
    }

    final compactValue = value.replaceAll(RegExp(r'\s'), '');
    if (_looksLikeBase64(compactValue)) {
      return compactValue;
    }

    return null;
  }

  static bool _isAbsoluteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool _isDataUri(String value) {
    return value.startsWith('data:image/');
  }

  static bool _looksLikeBase64(String value) {
    if (value.length < 32) {
      return false;
    }

    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value);
  }
}
