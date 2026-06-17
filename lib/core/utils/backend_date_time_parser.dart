class BackendDateTimeParser {
  static final RegExp _explicitOffsetPattern = RegExp(
    r'(?:[zZ]|[+-]\d{2}:?\d{2})$',
  );
  static const Duration _timezoneSkewThreshold = Duration(minutes: 15);

  const BackendDateTimeParser._();

  static DateTime? parse(dynamic value, {DateTime? now}) {
    if (value is DateTime) {
      return value.isUtc ? value.toLocal() : value;
    }
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    final raw = value.trim();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return null;
    }
    if (parsed.isUtc || _hasExplicitOffset(raw)) {
      return parsed.toLocal();
    }

    final utcAssumed = DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();

    final reference = now ?? DateTime.now();
    final localDistance = _absoluteDuration(parsed.difference(reference));
    final utcDistance = _absoluteDuration(utcAssumed.difference(reference));

    if (localDistance >= _timezoneSkewThreshold &&
        utcDistance < localDistance) {
      return utcAssumed;
    }

    return parsed;
  }

  static bool _hasExplicitOffset(String raw) {
    return _explicitOffsetPattern.hasMatch(raw);
  }

  static Duration _absoluteDuration(Duration duration) {
    return duration.isNegative ? -duration : duration;
  }
}
